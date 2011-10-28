use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Baseliner' }

# repo test
{
    use Baseliner::Sugar;
    my $data = { aa=>11, bb=>22 };
    repo->set( provider=>'tester', ns=>'1', data=>$data );
    my $item = repo->get( provider=>'tester', ns=>'1' );
    is( ref( $item ), 'HASH', 'data retrieved' );
    is( $item->{aa}, 11, 'data value retrieved' );
}

# kv test
{
    use Baseliner::Sugar;
    my $data = { aa=>11, bb=>22 };
    kv->set( provider=>'tester', ns=>'2', data=>$data );
    my $item = kv->get( provider=>'tester', ns=>'1' )->kv;
    is( ref( $item ), 'HASH', 'kv data retrieved' );
    is( $item->{aa}, 11, 'kv data value retrieved' );
}





