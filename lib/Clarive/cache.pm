package cache;
use strict;

our $ccache;

sub setup {
    # CHI cache setup
    require Baseliner::Utils;
    my $setup_fake_cache = sub {
       { package Nop; sub AUTOLOAD{ } };
       $ccache = bless {} => 'Nop';
    };
    if( !Clarive->config->{cache} ) {
        $setup_fake_cache->();
    } else {
        my $cache_type = Clarive->config->{cache};
        my $cache_defaults = {
                fastmmap  => [ driver => 'FastMmap', root_dir   => Util->_tmp_dir . '/clarive-cache', cache_size => '256m' ],
                memory    => [ driver => 'Memory' ],
                rawmemory => [ driver => 'RawMemory', datastore => {}, max_size => 1000 ],
                sharedmem => [ driver => 'SharedMem', size => 1_000_000, shmkey=>93894384 ],
                redis     => [ driver => 'BaselinerRedis', namespace => 'cache', server => ( Clarive->config->{redis}{server} // 'localhost:6379' ), debug => 0 ],
                mongo     => [ driver => 'Mongo' ] # not CHI
        };
        my $cache_config = ref $cache_type eq 'ARRAY' 
            ? $cache_type :  ( $cache_defaults->{ $cache_type } // $cache_defaults->{fastmmap} );
        $ccache = eval {
            if( $cache_type eq 'mongo' ) {
                require Baseliner::Cache;
                Baseliner::Cache->new( @$cache_config );
            } else {
                require CHI;
                CHI->new( @$cache_config );
            }
        }; 
        if( $@ ) {
            Util->_error( Util->_loc( "Error configuring cache: %1", $@ ) );
            $setup_fake_cache->();
        } else {
            Util->_debug( "CACHE Setup ok: " . join' ', @$cache_config );
        }
    }

    # clear cache on restart
    if( Clarive->debug ) {
        cache->clear;  
    }
    
    return 1;
}

sub keyify { 
    my ($self,$key)=@_;
    return ref $key ? Storable::freeze( $key ) : $key;
}
sub set { 
    my ($self,$key,$value)=@_;
    return if !$ccache;
    Util->_debug(-1, "+++ CACHE SET: " . ( ref $key ? Util->_to_json($key) : $key ) ) if $ENV{BALI_CACHE_TRACE}; 
    Util->_debug( Util->_whereami ) if defined $ENV{BALI_CACHE_TRACE} && $ENV{BALI_CACHE_TRACE} > 1 ;
    $ccache->set( $key, $value ) 
}
sub get { 
    my ($self,$key)=@_;
    return if !$ccache;
    return if $Clarive::_no_cache || $Baseliner::_no_cache;
    return if !$ccache;
    Util->_debug(-1, "--- CACHE GET: " . ( ref $key ? Util->_to_json($key) : $key ) ) if $ENV{BALI_CACHE_TRACE}; 
    $ccache->get( $key ) 
}
sub remove { 
    my ($self,$key)=@_;
    return if !$ccache;
    ref $key eq 'Regexp' ?  $self->remove_like($key) : $ccache->remove( $key ) ;
}
sub keys { $ccache->get_keys( @_ ) }
sub compute { $ccache->compute( @_ ) }
sub clear { $ccache->clear }
sub remove_like { my $re=$_[1]; cache->remove($_) for cache->keys_like($re); } 
sub keys_like { my $re=$_[1]; $re='.*' unless length $re; grep /$re/ => cache->keys; }

setup();

1;
