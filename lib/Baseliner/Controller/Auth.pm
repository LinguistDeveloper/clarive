package Baseliner::Controller::Auth;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::Auth;
BEGIN { extends 'Catalyst::Controller'; }
use Try::Tiny;
use MIME::Base64;

register 'action.surrogate' => {
    name => 'Become a different user',
};

register 'action.change_password' => {
    name => 'User can change his password',
};

register 'config.login' => {
    metadata => [
        { id => 'delay_attempts', default => 5, name=> 'Number of attempts the user ' },
        { id => 'delay_duration', default => 5, name=> 'Number of seconds the sleep loggin user' },
        ]
    };

register 'config.maintenance' => {
    name => 'Maintenance mode',
    metadata => [
        { id => 'enabled', name => 'Enabled', default => 0 },
        { id => 'message', name => 'Message', default => 'Maintenance mode. Please try again later' },
    ]
};


=head2 logout 

Hardcore, url based logout. Always redirects otherwise 
we get into a /logout loop

=cut

sub logout : Global {
    my ( $self, $c ) = @_;
    event_new 'event.auth.logout'=>{ username=>$c->username, mode=>'url' };
    $c->full_logout;
    $c->res->redirect( $c->req->params->{redirect} || $c->uri_for('/') );
}

=head2 logoff 

JSON based logoff, used by the logout menu option 

=cut
sub logoff : Global {
    my ( $self, $c ) = @_;
    event_new 'event.auth.logout'=>{ username=>$c->username, mode=>'logoff' };
    $c->full_logout;
    $c->stash->{json} = { success=>\1 };
    $c->forward('View::JSON');
}

sub logon : Global{
    my ( $self, $c ) = @_;
    if( my $redirect = $c->req->params->{redirect} ) {
        $c->res->redirect( $redirect );
    } else {
        $c->stash->{template} = $c->config->{login_page} || '/site/login.html';
    }
}

sub login_from_url : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $username = $c->stash->{username};
    if( $username ) {  
        try {
            die if $c->config->{ldap} eq 'no';
            $c->authenticate({ id=>$username }, 'ldap_no_pw');
            $c->session->{user} = $c->user_ci;
            $c->session->{username} = $username;
            event_new 'event.auth.ok'=>{ username=>$username, mode=>'from_url', realm=>'ldap_no_pw' };
        } catch {
            # failed to find ldap, just let him in ??? TODO
            my $err = shift;
            _log $err;
            $c->authenticate({ id=>$username }, 'none');
            $c->session->{user} = $c->user_ci;
            $c->session->{username} = $username;
            event_new 'event.auth.ok'=>{ username=>$username, mode=>'from_url', realm=>'none' };
        };
    }
    if( ref $c->user ) {
        $c->forward('/index');
    }
}

sub login_basic : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my ($login,$password) =  $c->req->headers->authorization_basic;
    if( length $login ) {
        _debug "LOGIN BASIC=$login";
        $c->stash->{login} = $login; 
        $c->stash->{password} = $password; 
        $self->authenticate($c);
        _debug "LOGIN USER=" . $c->user;
        event_new 'event.auth.ok'=>{ username=>$c->username, mode=>'basic' };
        return 1; # don't stop chain on auto, let the caller decide based on $c->username
    } else {
        _debug 'Notifying WWW-Authenticate = Basic';
        $c->response->headers->push_header( 'WWW-Authenticate' => 'Basic realm="clarive"' );
        $c->response->body( _loc('Authentication required') );
        event_new 'event.auth.failed'=>{ username=>$login, mode=>'basic' };
        $c->response->status( 401 );
        return 0;  # stops chain, sends auth required
    }
}
 
sub surrogate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $case = $c->config->{user_case};
    my $curr_user = $c->username;
    my $username= $case eq 'uc' ? uc($p->{login}) 
     : ( $case eq 'lc' ) ? lc($p->{login}) : $p->{login};
    try {
        _fail('User cannot surrogate') unless $c->has_action('action.surrogate');
        my $doc = ci->user->find_one({ name=>$username, active => mdb->true }); 
        if ($doc){
            $c->authenticate({ id=>$username }, 'none');
            $c->session->{user} = $c->user_ci;
            $c->session->{username} = $username;
            event_new 'event.auth.surrogate_ok'=>{ username=>$curr_user, to_user=>$username };
            $c->stash->{json} = { success => \1, msg => _loc("Login Ok") };
        } else {
            event_new 'event.auth.surrogate_failed'=>{ username=>$curr_user, to_user=>$username };
            $c->stash->{json} = { success => \0, msg => _loc("Invalid User") };
        }
    } catch {
        my $msg = shift;
        event_new 'event.auth.surrogate_failed'=>{ username=>$curr_user, to_user=>$username };
        $c->stash->{json} = { success => \0, msg => _loc('Surrogate error: %1', $msg || _loc("Invalid User") ) };
    };
    $c->forward('View::JSON');  
}

=head2 authenticate

Private action to authenticate a user. 

Returns:

    $c->stash->{auth_message} - with the last error message

=cut
sub authenticate : Private {
    my ( $self, $c ) = @_;
    my $login = $c->stash->{login} // _throw _loc('Missing login');
    my $password = $c->stash->{password};
    my ( $realm, $username ) = $login =~ m{^(\w+)/(.+)$};
    $username //= $login;
    $realm //= '';
    my $auth;
    _debug "AUTH START login=$login, username=$username, realm=$realm";

    my $maintenance = $c->model('ConfigStore')->get('config.maintenance');
    if ( $maintenance->{enabled} && $realm ne 'local' ) {
        $c->logout;
        $c->stash->{auth_message} = $maintenance->{message};
        return 0;
    }

    # auth by rule?
    my $auth_stash = {
        login      => $login,
        realm      => $realm,
        username   => $username,
        login_data => { login_ok => undef }
    };
    if ( !ci->user->find_one( { name => "$username" } ) && $username ne 'local/root' ) {
        $auth_stash->{login} = $login . " (user not exists)";
    }
    event_new 'event.auth.attempt' => $auth_stash;

    if ( $$auth_stash{login_data}{login_ok} ) {

        # rule says it's ok
        _debug "AUTH RULE OK=$login";
        $auth = $c->authenticate( { id => $login }, 'none' );
    }
    elsif ( defined $$auth_stash{login_data}{login_ok} ) {

        # rule says it's not ok
        _debug "AUTH RULE KO=$login";
        $c->stash->{auth_message}
            = _loc( $$auth_stash{login_data}{login_msg}, _array( $$auth_stash{login_data}{login_msg_params} ) )
            if $$auth_stash{login_data}{login_msg};
        $auth = undef;
    }
    elsif ( lc($realm) eq 'local' ) {
        $login = $username;
        my $local_store = try { $c->config->{authentication}{realms}{local}{store}{users}{$username} } catch { +{} };
        _debug $c->config->{authentication}{realms}{local};
        _debug $local_store;
        if ( exists $local_store->{api_key} && $password eq $local_store->{api_key} ) {
            if ( $c->stash->{api_key_authentication} ) {
                _debug "Login with API_KEY";
                $auth = $c->authenticate( { id => $username }, 'none' );
            }
            else {
                $c->log->error("**** LOGIN ERROR: api_key authentication not enabled for this url");
            }
        }
        else {
            $auth = try {

                # see the password: _debug BaselinerX::CI::user->encrypt_password( $login, $password ) ;
                $c->authenticate(
                    { id => $username, password => BaselinerX::CI::user->encrypt_password( $username, $password ) },
                    'local' );
            }
            catch {
                $c->log->error( "**** LOGIN ERROR: " . shift() );
            };    # realm may not exist
        }
    }
    else {
        # default realm authentication:
        $auth = $c->authenticate( { id => $login, password => $password } );

        if ( lc( $c->config->{authentication}->{default_realm} ) eq 'none' ) {

            # User (internal) auth when realm is 'none'
            if ( !$password ) {
                $auth = undef;
            }
            else {
                my $row = ci->user->find( { username => $login } )->next;
                if ($row) {
                    if ( !$row->{active} ) {
                        $c->stash->{auth_message} = _loc('User is not active');
                        $auth = undef;
                    }
                    my $api_key_ok = $row->{api_key} eq $password;
                    if ( BaselinerX::CI::user->encrypt_password( $login, $password ) ne $row->{password}
                        && ( !$c->stash->{api_key_authentication} || !$api_key_ok ) )
                    {
                        $auth = undef;
                        $c->stash->{auth_message} = _loc('api-key authentication is not enabled for this url')
                            if $api_key_ok && !$c->stash->{api_key_authentication};
                    }
                }
                else {
                    $auth = undef;
                }
            }
        }
    }

    # Create the authenticated user session
    if ( ref $auth ) {
        _debug "AUTH OK: $login";
        $c->session->{username} = $login;
        $c->session->{user}     = $c->user_ci;
        return 1;
    }
    else {
        _error "AUTH KO: $login";
        $c->logout;    # destroy $c->user
        $c->stash->{auth_message} ||= _loc("Invalid User or Password");
        return 0;
    }
}


sub login : Global {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $login= $c->stash->{login} // $p->{login};
    my $password = $c->stash->{password} // $p->{password};

    if ( !$login ) {
        my $msg = _loc("Missing User");
        event_new 'event.auth.failed' => { username => '', login => $login, mode => 'login', msg => $msg };
        $c->stash->{json} = { success => \0, msg => $msg, errors => { login => $msg } };
        $c->forward('View::JSON');
        return;
    }

    # configure user login case
    my $case = $c->config->{user_case} // '';
    my $config_login = $c->model('ConfigStore')->get('config.login');
    $login= $case eq 'uc' ? uc($login)
     : ( $case eq 'lc' ) ? lc($login) : $login;
    $c->log->info( "LOGIN: " . $login );
    #_log "PW   : " . $password; #XXX only for testing!
    my $msg;
    my $attempts_login = $config_login->{delay_attempts} // 0;
    my $attempts_duration = $config_login->{delay_duration} // 5;
    my $id_login = $c->req->address;
    my $id_browser = $c->req->user_agent;
    my $block_datetime = mdb->ts;
    try {
        # check if exists before insert in db attempts
        my $attempts_query = mdb->user_login_attempts->find_one({ id_login => $id_login, id_browser => $id_browser });
        my $num_attempts = $attempts_query->{num_attempts}; $num_attempts = 0 if !$num_attempts;
        # check the user hasn't been blocked.
        ########################################################
        my $time_user_block = Class::Date->new($attempts_query->{block_datetime});
        $time_user_block = $time_user_block + "$attempts_duration s";
        my $block_expired = $time_user_block lt mdb->ts ? 1 : 0;
        ########################################################
        if (!$attempts_query->{block_datetime} || ( $block_expired && $block_expired == 1)){
            # go to the main authentication worker
            $c->stash->{login} = $login; 
            $c->stash->{password} = $password;
            my $auth_ok = $self->authenticate($c);
            $msg = $c->stash->{auth_message};
            # check if user logins correctly into corresponding realm
            if( $auth_ok ) {
                # authentication ok, but user ci exists in db?
                if( model->Users->user_exists( $c->username ) ) {
                    $msg //= _loc("OK");
                    event_new 'event.auth.ok'=>{ username=>$c->username, login=>$login, mode=>'login', msg=>$msg };
                    $c->stash->{json} = { success => \1, msg => $msg };
                    #remove from user login attempts if loggin has ok
                    mdb->user_login_attempts->remove({ id_login => $id_login, id_browser => $id_browser });
                } else {
                    my $usr = $c->username;
                    $c->full_logout;  # destroy $c->username, session, etc.
                    _fail _loc('User not found: %1', $usr );
                }
            } else {
                # insert in db;
                if ($num_attempts >= $attempts_login) {
                    mdb->user_login_attempts->update(
                        { id_login => $id_login, id_browser => $id_browser },
                        { id_login => $id_login, id_browser => $id_browser, num_attempts => $num_attempts, block_datetime => $block_datetime },
                        { upsert => 1 }
                    );
                    if($attempts_query->{block_datetime} && $attempts_query->{block_datetime} != 0) { 
                            my $time_user_block = Class::Date->new($attempts_query->{block_datetime});
                            $time_user_block = $time_user_block + "$attempts_duration s";
                            if($time_user_block < mdb->ts) {
                                #remove from db if time has expired
                                $block_datetime = 0;
                                mdb->user_login_attempts->update(
                                    { id_login => $id_login, id_browser => $id_browser },
                                    { id_login => $id_login, id_browser => $id_browser, num_attempts => 1, block_datetime => $block_datetime },
                                    { upsert => 1 }); 
                            } #end if $time_user_block < mdb->ts
                        } #end else $attempts_query->{block_datetime} == 0
                    $msg //= _loc("Too many attempts");
                    event_new 'event.auth.failed'=>{ username=>'', login=>$login, mode=>'login', msg=>$msg };
                    $c->stash->{json} = { 
                        success => \0, 
                        msg => $msg,
                        attempts_login => $attempts_login-$num_attempts, 
                        block_datetime => $block_datetime, 
                        attempts_duration => $attempts_duration };
                } else {
                    $block_datetime = 0;
                    mdb->user_login_attempts->update(
                        { id_login => $id_login, id_browser => $id_browser },
                        { id_login => $id_login, id_browser => $id_browser ,num_attempts => $num_attempts+1, block_datetime => $block_datetime },
                        { 'upsert' => 1 }
                    );
                    $msg //= _loc("Invalid User or Password");
                    event_new 'event.auth.failed'=>{ username=>'', login=>$login, mode=>'login', msg=>$msg };
                    $c->stash->{json} = { 
                        success => \0, 
                        msg => $msg,
                        errors => {login => $msg},
                        attempts_login => $attempts_login-$num_attempts, 
                        block_datetime => $block_datetime };
                } 
            } 
        } else { 
            $block_datetime = 0 if $block_expired == 1;
            $num_attempts = 0 if $block_expired == 1;
            mdb->user_login_attempts->update(
            { id_login => $id_login, id_browser => $id_browser },
            { id_login => $id_login, id_browser => $id_browser, num_attempts => $num_attempts, block_datetime => $block_datetime },
            { upsert => 1 }); 
            $msg //= _loc("Attempts exhausted, please wait");
            event_new 'event.auth.failed'=>{ username=>'', login=>$login, mode=>'login', msg=>$msg };
            $c->stash->{json} = { 
                    success => \0, 
                    msg => $msg,
                    errors => {login => $msg},
                    attempts_login => $attempts_login-$num_attempts, 
                    block_datetime => $block_datetime, 
                    attempts_duration => $attempts_duration
            }; 
        } 
    } catch {
        my $err = shift;
        my $msg_err = _loc('Login error: %1', $err);
        event_new 'event.auth.failed'=>{ username=>'', login=>$login, mode=>'login', msg=>$msg_err };
        $c->stash->{json} = { success=>\0, msg=>$msg_err, errors => {login => $msg_err} };
    };
    
    _log _loc('------| Login in attempt: `%1`. Result=',$c->username, 0+${ $c->stash->{json}{success} || \-1 } );
    $c->forward('View::JSON');
}

sub error : Private {
    my ( $self, $c, $username ) = @_;
    $c->stash->{error_msg} = _loc( 'Invalid User.' );
    $c->stash->{error_msg} .= ' '._loc( "User '%1' not found", $username ) if( $username );
    $c->stash->{template} = $c->config->{error_page} || '/site/error.html';
}

sub saml_check : Private {
    my ( $self, $c ) = @_;
    my $header = $c->config->{saml_header} || 'samlv20';
    _debug _loc('SAML header: %1', $header );
    _log _loc('Current user: %1', $c->username );
    my $username = '';
    require XML::Simple;
    return try {
        my $saml = $c->req->headers->{$header};
        _debug "H=$saml";
        defined $saml or _fail "SAML: no header '$header' found in request. Rejected.";
        my $xml = XML::Simple::XMLin( $saml );
        $username = $xml->{'saml:Subject'}->{'saml:NameID'};
        $username or die 'SAML username not found';
        $username = $username->{content} if ref $username eq 'HASH';
        _log _loc('SAML starting session for username: %1', $username);
        $c->session->{user} = ci->user->search_ci( name => $username );
        $c->session->{username} = $username;
        event_new 'event.auth.saml_ok'=>{ username=>$username };
        return $username;
    } catch {
        _error _loc('SAML Failed auth: %1', shift);
        event_new 'event.auth.saml_failed'=>{ username=>$username };
        return 0;
    };
}

sub login_from_session : Local {
    my ( $self, $c ) = @_;
    # the Root controller creates the session for this
    _throw _loc 'Invalid session' unless $c->session_is_valid;    
    $c->res->redirect( $c->config->{web_url} );
}

sub create_user_session : Local {
    my ( $self, $c ) = @_;
    try {
        _fail _loc('S0003: create_user_session not enabled') unless $c->config->{create_user_session};
        _fail _loc('S0001: User %1 not authorized: action.create_user_session', $c->username)
            if $c->username && !$c->has_action('action.create_user_session');
        my $username = $c->req->params->{userid} // $c->req->headers->{userid} // _throw _loc 'Missing userid';
        # check that username is in the database
        my $uid = ci->user->find({ username=>$username })->next;
        _fail _loc( 'S0002: User not found: %1', $username ) unless ref $uid;
        my $sid = $c->create_session_id;
        $c->_sessionid($sid);
        $c->reset_session_expires;
        $c->set_session_id($sid);
        _throw _loc 'Invalid session' unless $c->session_is_valid;    
        $c->session->{username} = $username;
        $c->session->{user} = $c->user_ci;
        $c->_save_session();
        _error $c->session;
        $c->res->body( sprintf '%s/auth/login_from_session?sessionid=%s', $c->config->{web_url}, $c->sessionid );
    } catch {
        my $err = shift;
        $c->res->body( _loc('Auth error: %1', $err ) );
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
