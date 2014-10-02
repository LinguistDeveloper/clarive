package BaselinerX::Auth;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller' };

register 'event.auth.logout' => { name => 'User Logout' } ;
register 'event.auth.ok' => { name => 'Login Ok' } ;
register 'event.auth.failed' => { name => 'Login Failed' } ;
register 'event.auth.saml_ok' => { name => 'Login by SAML Ok' } ;
register 'event.auth.saml_failed' => { name => 'Login by SAML Failed' } ;
register 'event.auth.surrogate_ok' => { name => 'Surrogate Ok' } ;
register 'event.auth.surrogate_failed' => { name => 'Surrogate Failed' } ;

1;


