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

sub login_local : Local {
    my ( $self, $c, $login, $password ) = @_;
    my $p = $c->req->params;
	my $auth = $c->authenticate({ id=>$c->stash->{login}, password=>$c->stash->{password} }, 'local');
	if( ref $auth ) {
		$c->session->{user} = new Baseliner::Core::User( user=>$c->user );
		$c->session->{username} = $c->stash->{login};
		$c->stash->{json} = { success => \1, msg => _loc("OK") };
	} else {
		$c->stash->{json} = { success => \0, msg => _loc("Invalid User or Password") };
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

sub login : Global {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $login= $p->{login};
    my $password = $p->{password};
    my $case = $c->config->{user_case};
    $login= $case eq 'uc' ? uc($login)
     : ( $case eq 'lc' ) ? lc($login) : $login;
     
    _log "LOGIN: " . $p->{login};
    #_log "PW   : " . $p->{password}; #TODO only for testing!

	if( $login && $password ) {
		if( $login =~ /^local\/(.*)$/i ) {
			$c->stash->{login} = $1;
			$c->stash->{password} = $password;
			$c->forward('/auth/login_local');
		} else {
			my $auth = $c->authenticate({
					id          => $login, 
					password    => $password,
					});
			if( ref $auth ) {
				$c->stash->{json} = { success => \1, msg => _loc("OK") };
                $c->session->{username} = $login;
				$c->session->{user} = new Baseliner::Core::User( user=>$c->user );
			} else {
				$c->stash->{json} = { success => \0, msg => _loc("Invalid User or Password") };
			}
		}
    } else {
        # invalid form input
		$c->stash->{json} = { success => \0, msg => _loc("Missing User or Password") };
	}
	_log '------Login in: '  . $c->username ;
	$c->forward('View::JSON');	
    #$c->res->body("Welcome " . $c->user->username || $c->user->id . "!");
}

sub error : Private {
    my ( $self, $c, $username ) = @_;
    $c->stash->{error_msg} = _loc( 'Invalid User.' );
    $c->stash->{error_msg} .= ' '._loc( "User '%1' not found", $username ) if( $username );
    $c->stash->{template} = '/site/error.html';
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
	$c->stash->{template} = '/site/login.html';
}

sub saml_check : Private {
    my ( $self, $c ) = @_;
        my $header = $c->config->{saml_header} || 'samlv20';
        _log _dump $c->req->headers;
        _log _loc('SAML header: %1', $header );
	_log "LA BUENA";
        _log _loc('Current user: %1', $c->username );
        _log _loc('User exists: %1', $c->user_exists );
        use XML::Simple;
        return try {
                my $saml = $c->req->headers->{$header};
                _log "H=$saml";
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
                _log _loc('SAML Failed auth: %1', shift);
                return 0;
        };
}


1;

