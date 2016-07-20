package BaselinerX::Auth;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller' };

register 'event.auth.logout' => { name => 'User Logout', description =>_locl('User Logout'), vars=>['username','login','mode'] } ;
register 'event.auth.ok' => { name => 'Login Ok', description =>_locl('Login Ok'), vars=>['username','login','mode'] } ;
register 'event.auth.failed' => { name => 'Login Failed', description =>_locl('Login Failed'), vars=>['username','login','status','mode'] } ;
register 'event.auth.saml_ok' => { name => 'Login by SAML Ok', description =>_locl('Login by SAML Ok'), vars=>['username','mode'] } ;
register 'event.auth.saml_failed' => { name => 'Login by SAML Failed', description =>_locl('Login by SAML Failed'), vars=>['username','mode'] } ;
register 'event.auth.cas_ok' => { name => 'Login by CAS Ok', description =>_locl('Login by CAS Ok'), vars=>['username','mode'] } ;
register 'event.auth.cas_failed' => { name => 'Login by CAS Failed', description =>_locl('Login by CAS Failed'), vars=>['username','mode'] } ;
register 'event.auth.surrogate_ok' => { name => 'Surrogate Ok', description =>_locl('Surrogate Ok'), vars=>['username','mode'] } ;
register 'event.auth.surrogate_failed' => { name => 'Surrogate Failed', description => _locl('Surrogate Failed'), vars=>['username','to_user'] } ;
register 'event.auth.attempt' => { name => 'User Login Attempt', description => _locl('User Login Attempt'), vars=>['username'] } ;

register 'service.auth.ok' => {
    name => 'Authorize User Login',
    icon => '/static/images/icons/user_green.svg',
    handler=>sub{
        my ($self, $c, $data ) = @_;
        $c->stash->{login_data}{login_ok} = 1;
    }
};

register 'service.auth.deny' => {
    name => 'Deny User Login',
    icon => '/static/images/icons/user_red.svg',
    handler=>sub{
        my ($self, $c, $data ) = @_;
        $c->stash->{login_data}{login_ok} = 0;
    }
};

register 'service.auth.message' => {
    name => 'Login Error Message',
    icon => '/static/images/icons/user_red.svg',
    data => { msg=>'User authentication denied by rule', args=>[] },
    handler=>sub{
        my ($self, $c, $data ) = @_;
        $c->stash->{login_data}{login_msg} = $data->{msg};
    }
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
