use strict;
use warnings;
use Test::More;
use Try::Tiny;

BEGIN { use_ok 'Catalyst::Test', 'Baseliner',  }
use HTTP::Request::Common;
use Baseliner::Plug;

my $m = Baseliner->model('ConfigStore');

# login
my $res = request POST '/login', [ login=>'local/root', password=>'admin' ];
my $cookie = $res->header('Set-Cookie');

{
    register 'config.testing' => {
        metadata=>[
            { id=>'name', default=>'foo' },
        ]
    };

    is( $m->get('config.testing')->{name}, 'foo', 'config registry and get ok');

    $m->store_long( data=>{ 'config.testing.name'=>'bar' }, bl=>'TEST' );  

    #is( $m->get('config.testing')->{name}, 'foo', 'get * ok');

    is( $m->get('config.testing', bl=>'TEST')->{name}, 'bar', 'get bl TEST ok');

    $m->store_long( data=>{ 'config.testing.name'=>'proddy' }, bl=>'PROD' );  
    is( $m->get('config.testing', bl=>'PROD')->{name}, 'proddy', 'get bl PROD ok');

    #TODO broken: (won't look for default from register)
    # is( $m->get('config.testing', bl=>'NOT_EXISTS')->{name}, 'foo', 'get bl fallback to default ok');
    # is( $m->get('config.testing')->{name}, 'foo', 'get ns fallback to default ok');

    $m->store_long( data=>{ 'config.testing.name'=>'deaf' } );  
    is( $m->get('config.testing', bl=>'NOT_EXISTS')->{name}, 'deaf', 'get bl fallback to default ok');

    $m->store_long( data=>{ 'config.testing.name'=>'proj' }, ns=>'project/1' );  
    is( $m->get('config.testing', ns=>'project/1')->{name}, 'proj', 'get ns ok');
    is( $m->get('config.testing', bl=>'PROD' )->{name}, 'proddy', 'get ns-bl fallback ok');
    is( $m->get('config.testing' )->{name}, 'deaf', 'get ns fallback to default ok');
}

done_testing;


