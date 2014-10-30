package Baseliner::Cache;
use v5.10;
use Mouse;
use URI::Escape qw(uri_escape uri_unescape);
use Try::Tiny;
use JSON::XS;

use Sereal;
has encoder => qw(is rw isa Object lazy 1 default), sub{ 
    Sereal::Encoder->new({ compress=>1, compress_threshold=>768, compress_level=>1, canonical=>1 }) 
}; 
has decoder => qw(is rw isa Object lazy 1 default), sub{ Sereal::Decoder->new }; 
has expire_seconds => qw(is rw isa Num default), sub { 3600*24 }; # one expiration day by default

sub dt {
    state $tz = Util->_tz();
    #DateTime::Tiny->now( time_zone=>$tz );
    scalar time();
}

sub BUILD {
    my $self = shift;
    #if( !mdb->db_cache->get_collection('system.namespaces')->find({ name=>qr/\.cache$/ })->count ) {
    if( scalar mdb->cache->get_indexes < 5 ) {   # works if the collection does not exist or missing indexes
        mdb->cache->drop_indexes;
        Util->_debug( 'Creating mongo cache indexes. Expire seconds=' . $self->expire_seconds ); 
        my $coll = mdb->db_cache->get_collection('cache');
        $coll->ensure_index($_,{ background=>1 }) for (
            { mid=>1 }, { d=>1 }, { d=>1, mid=>1 },
        );
        $coll->ensure_index({ t=>1 },{ expire_after_seconds=>0+$self->expire_seconds });
        #mdb->db_cache->eval(q{function(r){ return db.cache.ensureIndex({ t:1 },{ expireAfterSeconds:r }) }}, [$self->expire_seconds] );
    }
    else {
        # reconfigure expire seconds
        mdb->db_cache->run_command([ collMod=>"cache", index=>{keyPattern=>{t=>1}, expireAfterSeconds=>(0+$self->expire_seconds) }]);
    }
}

sub set {
    my ($self,$key,$value)=@_;
    return try {
        my $key_frozen = ref $key || length($key)>750 ? $self->encoder->encode($key) : $key;
        my $value_frozen = $self->encoder->encode($value);
        
        # if it's too big for mongo, don't store it and remove it
        if( length($value_frozen) >= 16_777_216 ) {
            $self->remove( $key );
            return;
        }
        #Util->_warn('key too large=' . length($key_frozen) ) if length($key_frozen) >= 800;
        return if length($key_frozen) >= 800;
        my $setter = { v=>$value_frozen };
        if( ref $key eq 'HASH' ) {
            $$setter{d}=$$key{d} if defined $$key{d};
            $$setter{mid}=$$key{mid} if defined $$key{mid};
        }
        mdb->cache->update({ _id=>$key_frozen },{ '$currentDate'=>{t=>boolean::true}, '$set'=>$setter },{ upsert=>1 });
    } catch {
        my $err = shift;        
        Util->_error( Util->_loc('Cache set error %1 for key %2', $err, 
                try{ Util->_encode_json($key) } catch { Util->_dump($key) } ) 
        );
        return;
    };
}

sub get {
    my ($self,$key)=@_;
    my $key_frozen = ref $key || length($key)>750 ? $self->encoder->encode($key) : $key;
    #my $doc = mdb->cache->find_one({ _id=>$key_frozen },{ _id=>0, d=>0, mid=>0, t=>0 });
    my $doc = mdb->cache->find_and_modify({
        query  => { _id    => $key_frozen },
        update => { '$currentDate'=>{t=>boolean::true} }, #'$set' => { t=>$self->dt() } },
        new    => 1,
        fields => { _id=>0, d=>0, mid=>0, t=>0 }
    });
    return undef unless $doc;
    my $value = $doc->{v};
    return undef unless $value;
    return try { 
        $self->decoder->decode($value);
    } catch { 
        my $err = shift;
        Util->_error( Util->_loc('Cache decode error of key `%1` (`%2`)', Util->_dump($key), $key_frozen ) );
        Util->_error( $value );
        mdb->cache->remove({ _id=>$key_frozen });
        undef;
    };
}

sub remove {
    my ($self,$key)=@_;
    my $key_frozen = ref $key || length($key)>750 ? $self->encoder->encode($key) : $key;
    my $ret = mdb->cache->remove({ _id=>$key_frozen },{ safe=>1 });
    # if $key does not match anything, delete domains and mids { d=>'xx' }, { mid=>'999' }
    mdb->cache->remove($key) if $ret && !$$ret{n} && ref $key eq 'HASH';  
}

sub get_keys {
    my ($self,)=@_;
    map { $_->{_id} } mdb->cache->find->fields({ _id=>1 })->all;
}

sub compute {
    my ($self)=@_;
    ...
}

sub clear {
    my ($self)=@_;
    mdb->cache->remove;
}

1;
