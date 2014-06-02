package Baseliner::Controller::Auth;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Baseliner::Sugar;
BEGIN { extends 'Catalyst::Controller'; }
use Try::Tiny;
use MIME::Base64;

register 'action.surrogate' => {
    name => 'Become a different user',
};

register 'action.change_password' => {
    name => 'User can change his password',
};

register 'event.auth.logout' => { name => 'User Logout' } ;
register 'event.auth.ok' => { name => 'Login Ok' } ;
register 'event.auth.failed' => { name => 'Login Failed' } ;
register 'event.auth.saml_ok' => { name => 'Login by SAML Ok' } ;
register 'event.auth.saml_failed' => { name => 'Login by SAML Failed' } ;
register 'event.auth.surrogate_ok' => { name => 'Surrogate Ok' } ;
register 'event.auth.surrogate_failed' => { name => 'Surrogate Failed' } ;

register 'config.login' => {
    metadata => [
        { id => 'delay_attempts', default => 5, name=> 'Number of attempts the user ' },
        { id => 'delay_duration', default => 5, name=> 'Number of seconds the sleep loggin user' },
        ]
    };

=head2 logout 

Hardcore, url based logout. Always redirects otherwise 
we get into a /logout loop

=cut
sub logout : Global {
    my ( $self, $c ) = @_;
    $c->full_logout;
    event_new 'event.auth.logout'=>{ username=>$c->username, mode=>'url' };
    $c->res->redirect( $c->req->params->{redirect} || $c->uri_for('/') );
}

=head2 logoff 

JSON based logoff, used by the logout menu option 

=cut
sub logoff : Global {
    my ( $self, $c ) = @_;
    $c->full_logout;
    event_new 'event.auth.logout'=>{ username=>$c->username, mode=>'logoff' };
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
        $c->forward('authenticate');
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
        my $doc = ci->user->find_one({ name=>$username, active=>'1' }); 
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
        event_new 'event.auth.surrogate_failed'=>{ username=>$curr_user, to_user=>$username };
        $c->stash->{json} = { success => \0, msg => _loc("Invalid User") };
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
    my $login    = $c->stash->{login} // _throw _loc('Missing login');
    my $password = $c->stash->{password};
    
    my $auth; 
    _debug "AUTH START=$login";

    if( $login =~ /^local\/(.*)$/i ) {
        $login = $1;
        my $local_store = try { $c->config->{authentication}{realms}{local}{store}{users}{ $login } } catch { +{} };
        _debug $c->config->{authentication}{realms}{local};
        _debug $local_store; 
        if( exists $local_store->{api_key} && $password eq $local_store->{ api_key } ) {
            _debug "Login with API_KEY";
            $auth = $c->authenticate({ id=>$login }, 'none');
        } else {
            $auth = try {
                # see the password: _debug BaselinerX::CI::user->encrypt_password( $login, $password ) ;
                $c->authenticate({ id=>$login, password=>BaselinerX::CI::user->encrypt_password( $login, $password ) }, 'local');
            } catch {
                $c->log->error( "**** LOGIN ERROR: " . shift() );
            }; # realm may not exist
        }
    } else {
        # default realm authentication:
        $auth = $c->authenticate({ id=>$login, password=> $password });
        
        if ( lc( $c->config->{authentication}->{default_realm} ) eq 'none' ) {
            # User (internal) auth when realm is 'none'
            if ( !$password ) {
                    $auth = undef;                
            } else {                
                my $row = ci->user->find({ username => $login })->next;
                if ($row) {
                    if ( ! $row->{active} ) {
                        $c->stash->{auth_message} = _loc( 'User is not active');
                        $auth = undef;
                    }
                    if ( BaselinerX::CI::user->encrypt_password( $login, $password ) ne $row->{password} 
                        && $row->{api_key} ne $password )
                    {
                        $auth = undef;
                    }
                } else {
                    $auth = undef;
                }
            }
        }
    }
    # Create the authenticated user session
    if( ref $auth ) {
        _debug "AUTH OK: $login";
        $c->session->{username} = $login;
        $c->session->{user} = $c->user_ci;
        return 1;
    } else {
        _error "AUTH KO: $login";
        $c->logout;  # destroy $c->user
        $c->stash->{auth_message} = _loc("Invalid User or Password");
        return 0;
    }
}

sub login : Global {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $login= $c->stash->{login} // $p->{login};
    my $password = $c->stash->{password} // $p->{password};
    # configure user login case
    my $case = $c->config->{user_case} // '';
    my $config_login = Baseliner->model('ConfigStore')->get('config.login');
    $login= $case eq 'uc' ? uc($login)
     : ( $case eq 'lc' ) ? lc($login) : $login;
    $c->log->info( "LOGIN: " . $login );
    #_log "PW   : " . $password; #XXX only for testing!
    my $msg;
    my $attempts_login = $config_login->{delay_attempts};
    my $attempts_duration = $config_login->{delay_duration};
    my $id_login = $c->req->address;
    my $id_browser = $c->req->user_agent;
    my $block_datetime = mdb->ts;
    if( $login ) {
        # check if exists before insert in db attempts
        my $attempts_query = mdb->user_login_attempts->find_one({ id_login => $id_login, id_browser => $id_browser });
        my $num_attempts = $attempts_query->{num_attempts}; $num_attempts = 0 if !$num_attempts;
        # check the user hasn't been blocked.
        ########################################################
        my $time_user_block = Class::Date->new($attempts_query->{block_datetime});
        $time_user_block = $time_user_block + "$attempts_duration s";
        my $block_expired = 1 if $time_user_block < mdb->ts;
        ########################################################
        if (($attempts_query->{block_datetime} == 0) || ($block_expired == 1)){
            # go to the main authentication worker
            $c->stash->{login} = $login; 
            $c->stash->{password} = $password;
            $c->forward('authenticate');
            $msg = $c->stash->{auth_message};
            # comprueba el logueo correcto del usuario
            if( $c->forward('authenticate') ) {
                $msg //= _loc("OK");
                event_new 'event.auth.ok'=>{ username=>$c->username, login=>$login, mode=>'login', msg=>$msg };
                $c->stash->{json} = { success => \1, msg => $msg };
                #remove from user login attempts if loggin has ok
                mdb->user_login_attempts->remove({ id_login => $id_login, id_browser => $id_browser });
            } #end if $c->forward('authenticate')
            else {
                # insert in db;
                if ($num_attempts >= $attempts_login) {
                    mdb->user_login_attempts->update(
                    { id_login => $id_login, id_browser => $id_browser },
                    { id_login => $id_login, id_browser => $id_browser, num_attempts => $num_attempts, block_datetime => $block_datetime },
                    { upsert => 1 });
                    if($attempts_query->{block_datetime} != 0) { 
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
                } #end else $c->forward('authenticate')
                else {
                    $block_datetime = 0;
                    mdb->user_login_attempts->update(
                    { id_login => $id_login, id_browser => $id_browser },
                    { id_login => $id_login, id_browser => $id_browser ,num_attempts => $num_attempts+1, block_datetime => $block_datetime },
                    { 'upsert' => 1 });
                    $msg //= _loc("Invalid User or Password");
                    event_new 'event.auth.failed'=>{ username=>'', login=>$login, mode=>'login', msg=>$msg };
                    $c->stash->{json} = { 
                        success => \0, 
                        msg => $msg,
                        attempts_login => $attempts_login-$num_attempts, 
                        block_datetime => $block_datetime };
                } #end else ($num_attempts >= $attempts_login)
            } #end else $attempts_query->{block_datetime}
        } #end if $attempts_query->{block_datetime}
        else { 
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
                        attempts_login => $attempts_login-$num_attempts, 
                        block_datetime => $block_datetime, 
                        attempts_duration => $attempts_duration
                         }; 
        } #end else $LOGIN 
    } #END IF $LOGIN
    else { 
        # invalid form input
        # $c->stash->{json} = { success => \0, msg => _loc("Missing User or Password") };
        $msg //= _loc("Missing User");
        event_new 'event.auth.failed'=>{ username=>'', login=>$login, mode=>'login', msg=>$msg };
        $c->stash->{json} = { success => \0, msg => $msg };
    } #end else $LOGIN 
    
    _log '------Login in: '  . $c->username ;
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
        $c->session->{user} = $c->user_ci;
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

1;
