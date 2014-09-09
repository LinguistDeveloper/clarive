package Baseliner::Cache;
use Mouse;
use URI::Escape qw(uri_escape uri_unescape);
use JSON::XS;

sub set {
    my ($self,$key,$value)=@_;
    # Storable::freeze($value) does not work for non-ref $value
    #   so, if it's not a ref, bless into a fake type Cache::SV so that we know to unbless/deref on "get" below
    my $frozen = ref $value 
        ? Storable::freeze($value) 
        : Storable::freeze(bless( \$value => 'Cache::SV' )); 
    if( length($frozen) < 16777216){
        $key = JSON::XS->new->utf8->canonical->encode( $key ) if ref $key;
        return if length $key > 1024;
        mdb->cache->update({ _id=>$key },{ _id=>$key,v=>(ref $value ? Storable::freeze($value) : undef) },{ upsert=>1 });
    }
}

sub get {
    my ($self,$key)=@_;
    $key = JSON::XS->new->utf8->canonical->encode( $key ) if ref $key;
    return undef if length $key > 1024;
    my $doc = mdb->cache->find_one({ _id=>$key },{ _id=>0 });
    return undef unless $doc;
    my $value = $doc->{v};
    return undef unless $value;
    my $ret = Storable::thaw($value);
    return ref($ret) eq 'Cache::SV' ? $$ret : $ret;
}

sub remove {
    my ($self,$key)=@_;
    $key = JSON::XS->new->utf8->canonical->encode( $key ) if ref $key;
    mdb->cache->remove({ _id=>$key });
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
