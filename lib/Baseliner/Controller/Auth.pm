package Baseliner::Controller::Auth;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller'; }
use Try::Tiny;
use YAML;
use MIME::Base64;
use Baseliner::Core::User;

register 'action.surrogate' => {
    name => 'Become a different user',
};

sub login_from_url : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $username = $c->stash->{username};
    if( $username ) {  
        try {
            die if $c->config->{ldap} eq 'no';
            $c->authenticate({ id=>$username }, 'ldap_no_pw');
            $c->session->{user} = new Baseliner::Core::User( user=>$c->user, username=>$username );
            $c->session->{username} = $username;
        } catch {
            # failed to find ldap, just let him in ??? TODO
            my $err = shift;
            _log $err;
            $c->authenticate({ id=>$username }, 'none');
            $c->session->{user} = new Baseliner::Core::User( user=>$c->user, username=>$username );
            $c->session->{username} = $username;
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
        return 1; # don't stop chain on auto, let the caller decide based on $c->username
    } else {
        _debug 'Notifying WWW-Authenticate = Basic';
        $c->response->headers->push_header( 'WWW-Authenticate' => 'Basic realm="clarive"' );
        $c->response->body( _loc('Authentication required') );
        $c->response->status( 401 );
        return 0;  # stops chain, sends auth required
    }
}

sub surrogate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $case = $c->config->{user_case};
    my $username= $case eq 'uc' ? uc($p->{login}) 
     : ( $case eq 'lc' ) ? lc($p->{login}) : $p->{login};
    
    try {
        $c->authenticate({ id=>$username }, 'none');
        $c->session->{user} = new Baseliner::Core::User( user=>$c->user );
        $c->session->{username} = $username;
        $c->stash->{json} = { success => \1, msg => _loc("Login Ok") };
    } catch {
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
                $c->authenticate({ id=>$login, password=> Digest::MD5::md5_hex( $password ) }, 'local');
            } catch {
                $c->log->error( "**** LOGIN ERROR: " . shift() );
            }; # realm may not exist
        }
    } else {
        # default realm authentication:
        $auth = $c->authenticate({ id=>$login, password=> $password });
        
        if ( lc( $c->config->{authentication}->{default_realm} ) eq 'none' ) {
            my $user_key;    # (Public key + Username al revés)
            $user_key = $c->config->{decrypt_key} . reverse($login);

            # BaliUser (internal) auth when realm is 'none'
            my $row = $c->model('Baseliner::BaliUser')->search( { username => $login } )->first;
            if ($row) {
                if ( ! $row->active ) {
                    $c->stash->{auth_message} = _loc( 'User is not active');
                    $auth = undef;
                }
                if ( $c->model('Users')->encriptar_password( $password, $user_key ) ne $row->password 
                    && $row->auth_key ne $password )
                {
                    $auth = undef;
                }
            } else {
                $auth = undef;
            }
        }
    }
    # Create the authenticated user session
    if( ref $auth ) {
        _debug "AUTH OK: $login";
        $c->session->{username} = $login;
        $c->session->{user} = new Baseliner::Core::User( user=>$c->user );
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
    $login= $case eq 'uc' ? uc($login)
     : ( $case eq 'lc' ) ? lc($login) : $login;
     
    $c->log->info( "LOGIN: " . $login );
    #_log "PW   : " . $password; #XXX only for testing!
    my $msg;

    if( $login ) {
        # go to the main authentication worker
        $c->stash->{login} = $login; 
        $c->stash->{password} = $password; 
        $c->forward('authenticate');
        $msg = $c->stash->{auth_message};
        if( length $c->username ) {
            $c->stash->{json} = { success => \1, msg => $msg // _loc("OK") };
        } else {
            $c->stash->{json} = { success => \0, msg => $msg // _loc("Invalid User or Password") };
        }
    } else {
        # invalid form input
        # $c->stash->{json} = { success => \0, msg => _loc("Missing User or Password") };
        $c->stash->{json} = { success => \0, msg => _loc("Missing User") };
    }
    _log '------Login in: '  . $c->username ;
    $c->forward('View::JSON');	
    #$c->res->body("Welcome " . $c->user->username || $c->user->id . "!");
}

sub error : Private {
    my ( $self, $c, $username ) = @_;
    $c->stash->{error_msg} = _loc( 'Invalid User.' );
    $c->stash->{error_msg} .= ' '._loc( "User '%1' not found", $username ) if( $username );
    $c->stash->{template} = $c->config->{error_page} || '/site/error.html';
}

sub logout : Global {
    my ( $self, $c ) = @_;

    $c->delete_session;
    $c->logout;
}

sub logoff : Global {
    my ( $self, $c ) = @_;
    $c->delete_session;
}

sub logon : Global {
    my ( $self, $c ) = @_;
    $c->stash->{template} = $c->config->{login_page} || '/site/login.html';
}

sub saml_check : Private {
    my ( $self, $c ) = @_;
    my $header = $c->config->{saml_header} || 'samlv20';
    _debug _loc('SAML header: %1', $header );
    _log _loc('Current user: %1', $c->username );
    use XML::Simple;
    return try {
        my $saml = $c->req->headers->{$header};
        _debug "H=$saml";
        defined $saml or _fail "SAML: no header '$header' found in request. Rejected.";
        my $xml = XMLin( $saml );
        my $username = $xml->{'saml:Subject'}->{'saml:NameID'};
        $username or die 'SAML username not found';
        $username = $username->{content} if ref $username eq 'HASH';
        _log _loc('SAML starting session for username: %1', $username);
        $c->session->{user} = new Baseliner::Core::User( user=>$c->user, username=>$username );
        $c->session->{username} = $username;
        return $username;
    } catch {
        _error _loc('SAML Failed auth: %1', shift);
        return 0;
    };
}

1;
