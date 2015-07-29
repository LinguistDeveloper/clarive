use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;

BEGIN {
    plan skip_all => 'set TEST_LIVE to run this test' unless $ENV{TEST_LIVE};
}

{
    require Clarive::mdb;
    require Clarive::cache;
    cache->clear;
    cache->set('kk', 100 );
    is( cache->get('kk'), 100, 'key simple' );
    {
        local $Clarive::_no_cache = 1;
        is( cache->get('kk'), undef, 'key no cache' );
    }
    cache->remove('kk');
    is( cache->get('kk'), undef, 'simple remove' );
    
    cache->set({ a=>[1,2,3] }, 99 );
    is( cache->get({ a=>[1,2,3] }), 99, 'key complex' );
    cache->remove({ a=>[1,2,3] });
    is( cache->get({ a=>[1,2,3] }), undef, 'key complex remove' );
    
    # domain checks
    cache->set({ d=>'nn', bb=>$_ }, 66) for 1..10;
    is( cache->get({ d=>'nn', bb=>10 }), 66, 'domain multi' );
    is( cache->get({ bb=>10 }), undef, 'no domain' );
    cache->remove({ d=>'nn' });
    is( cache->get({ d=>'nn', bb=>10 }), undef, 'domain nothing' );
    
    # mid checks
    cache->set({ mid=>$_, aa=>"aa$_" }, "vv$_" ) for 1..10;
    is( cache->get({ mid=>10, aa=>"aa10" }), "vv10", 'mid multi' );
    cache->remove({ mid=>10 });
    is( cache->get({ mid=>10, aa=>"aa10" }), undef, 'mid multi removed' );
    
    # mid and domain
    cache->clear;
    cache->set({ d=>'nn', mid=>"$_", aa=>"aa$_" }, "vv$_" ) for 1..10;
    is( cache->get({ d=>'nn', mid=>"10", aa=>"aa10" }), "vv10", 'mid-domain multi' );
    
    cache->set({ d=>'nn', mid=>"33", aa=>"aa44" }, "vv44" );
    is( cache->get({ d=>'nn', mid=>"33", aa=>"aa44" }), "vv44", 'mid-domain get' );
    cache->remove({ d=>'nn', mid=>"33", aa=>"aa44" }, "vv44" );
    is( cache->get({ d=>'nn', mid=>"33", aa=>"aa44" }), undef, 'mid-domain gone' );

    cache->remove({ d=>'nn' });
    is( cache->get({ d=>'nn', mid=>"10", aa=>"aa10" }), undef, 'mid-domain removed' );
    
    # clear
    cache->set('kk', 100 );
    cache->clear;
    is( cache->get('kk'), undef, 'key simple clear' );
    
    # longkeys
    {
        my $k = 'x' x 1000;
        cache->set($k, 100 );
        is( cache->get($k), 100, 'key long' );
    }
    
    {
        my $k = 'x' x 10000;
        cache->set($k, 88 );
        is( cache->get($k), 88, 'key longer' );
    }
    
    {
        my $k = 'x' x 100000;
        cache->set($k, 66 );
        is( cache->get($k), undef, 'key longest, even compressed' );
    }
    
    # multi-set
    cache->clear;
    cache->set('kk', 100 );
    cache->set('kk', 100 );
    cache->set('xx', 100 );
    is( scalar cache->keys, 2, 'just 2 keys'); 
    
    # hash key
    cache->clear;
    cache->set({ aa=>11, bb=>22 }, 3232 );
    is( cache->get({ aa=>11, bb=>22 }), 3232, 'hash ordered' );
    is( cache->get({ bb=>22, aa=>11 }), 3232, 'hash unordered' );
    
    # arrays
    cache->clear;
    cache->set([100, 200,{ aa=>11 }], [11,22] );
    is_deeply( cache->get([100, 200,{ aa=>11 }]), [11,22], 'array is array' );
    is( cache->get([200,{ aa=>11 }, 100]), undef, 'array must be ordered' );
    
    # regex
    cache->clear;
    cache->set( "aa-$_", "$_" ) for 1..100;
    is( scalar cache->keys, 100, '100 keys'); 
    cache->remove( qr/aa-9/ );
    is( scalar cache->keys, 89, '89 keys removed regex'); 
    cache->remove( qr/^aa-1/ );
    is( scalar cache->keys, 77, '77 keys removed regex'); 
    cache->remove_like( qr/^aa-2/ );
    is( scalar cache->keys, 66, '66 keys remove_like'); 
    is( scalar cache->get('aa-2'), undef, 'really remove_like'); 
    
    # simple d and mid
    cache->clear;
    cache->set({ mid=>'33'}, "nn" );
    is( cache->get({ mid=>'33' }), 'nn', 'simple mid' );
    cache->set({ d=>'44' }, "xx" );
    cache->set({ d=>'55' }, "yy" );
    is( cache->get({ d=>'44' }), 'xx', 'simple domain' );
    cache->remove({ d=>'44' });
    is( cache->get({ d=>'55' }), 'yy', 'simple domain remove one' );
    
    # values
    cache->clear;
    cache->set({ mid=>'33'}, undef );
    is( scalar cache->keys, 1, '1 keys even if undef'); 
    is( cache->get({mid=>'33'}), undef, 'undef saved' );
    { package XX; use Mouse; has yy=>qw(is rw isa Num); has me=>qw(is rw isa Any weak_ref 1) }
    cache->set({ mid=>'33'}, XX->new( yy=>44 ) );
    is( cache->get({mid=>'33'})->yy, 44, 'value object' );
    { 
        my $obj = XX->new( yy=>77 );
        $obj->me( $obj ); # circular
        cache->set({ mid=>'33'}, $obj );
        is( cache->get({mid=>'33'})->me->yy, 77, 'value object circular' );
    }
    { 
        my $v = 'x' x 10_000_000; 
        cache->set( 'ff', $v );
        is( length(cache->get('ff')), 10_000_000, 'value big' );
        $v = join ',', map { rand($_) } 1..2_000_000;  # rand so that Sereal compressor is not able to reduce much
        cache->set( 'ff', $v );
        is( cache->get('ff'), undef, 'value too big for mongo' );
        
    }
    
    
    # done!
    cache->clear;

}

done_testing;
