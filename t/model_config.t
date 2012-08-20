use strict;
use warnings;
use Test::More tests => 12;

$ENV{BALI_CMD} = 1;

BEGIN { use_ok 'Catalyst::Test', 'Baseliner' }
BEGIN { use_ok 'Baseliner::Model::Permissions' }

require Baseliner;
my $c = Baseliner->new();
Baseliner->app( $c );

use Baseliner::Utils;


ok( my $cs = $c->model('ConfigStore'), 'model config store' );

{
    #my $data = $cs->get( 'config.nature.j2ee.build', ns=>'package/GBP.328.N-000002 carga inicial' );
    my $data = $cs->get( 'config.nature.j2ee.build', ns=>'application/GBP.0000' );
    print _dump $data;
}
{
    my $data = $cs->get( 'config.nature.j2ee.build', ns=>'harvest.subapplication/AppBPE', bl=>'DESA' );
    print _dump $data;
}
{
    for( 1..10 )  {
        my $data = $cs->get( 'config.nature.j2ee.build', ns=>'harvest.subapplication/AppBPE', bl=>'DESA' );
        print _dump $data;
    }
}
