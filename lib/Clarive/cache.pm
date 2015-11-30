package cache;
use strict;
use Try::Tiny;

our $ccache;

sub setup {
    my ($self,$cache_type) = @_;
    $cache_type //= Clarive->config->{cache};
    # CHI cache setup
    require Baseliner::Utils;
    my $setup_fake_cache = sub {
       { package Nop; sub AUTOLOAD{ } };
       $ccache = bless {} => 'Nop';
    };
    if( !$cache_type ) {
        $setup_fake_cache->();
    } else {
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
        my %user_config = %{ Clarive->config->{cache_config} || {} } ;
        $ccache = eval {
            if( $cache_type eq 'mongo' ) {
                require Baseliner::Cache;
                Baseliner::Cache->new( @$cache_config, %user_config );
            } else {
                require CHI;
                CHI->new( @$cache_config, %user_config );
            }
        }; 
        if( $@ ) {
            Util->_error( Util->_loc( "Error configuring cache: %1", $@ ) );
            $setup_fake_cache->();
        } else {
            Util->_debug( "CACHE Setup ok: " . join' ', %{ +{ @$cache_config, %user_config } } );
        }
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
    Util->_debug(-1, "+++ CACHE SET: " . ( ref $key ? Util->_to_json($key) : $key ) ) if $ENV{CLARIVE_CACHE_TRACE}; 
    Util->_debug( Util->_whereami ) if $ENV{CLARIVE_CACHE_TRACE} > 1 ;
    $ccache->set( $key, $value ) 
}
sub get { 
    my ($self,$key)=@_;
    return if !$ccache;
    return if $Clarive::_no_cache || $Baseliner::_no_cache;
    Util->_debug(-1, "--- CACHE GET: " . ( ref $key ? Util->_to_json($key) : $key ) ) if $ENV{CLARIVE_CACHE_TRACE}; 
    $ccache->get( $key ) 
}
sub remove { 
    my ($self,$key)=@_;
    return if !$ccache;
    Util->_debug(-1, "--- CACHE REMOVE: " . ( ref $key ? ( ref $key eq 'Regexp' ? Util->_dump($key) : Util->_to_json($key) ) : $key ) ) if $ENV{CLARIVE_CACHE_TRACE}; 
    ref $key eq 'Regexp' ?  $self->remove_like($key) : $ccache->remove( $key ) ;
}
sub keys { $ccache->get_keys( @_ ) }
sub compute { $ccache->compute( @_ ) }
sub clear { $ccache->clear }
sub remove_like { my $re=$_[1]; cache->remove($_) for cache->keys_like($re); } 
sub keys_like { my $re=$_[1]; $re='.*' unless length $re; grep /$re/ => cache->keys; }

__PACKAGE__->setup();

1;
