package Baseliner::Cache;
use Mouse;
use URI::Escape qw(uri_escape uri_unescape);
use JSON::XS;

sub set {
    my ($self,$key,$value)=@_;
    $key = JSON::XS->new->utf8->canonical->encode( $key ) if ref $key;
    mdb->cache->update({ _id=>$key },{ _id=>$key,v=>(ref $value ? Storable::freeze($value) : undef) },{ upsert=>1 });
}

sub get {
    my ($self,$key)=@_;
    $key = JSON::XS->new->utf8->canonical->encode( $key ) if ref $key;
    my $doc = mdb->cache->find_one({ _id=>$key },{ _id=>0 });
    return undef unless $doc;
    my $value = $doc->{v};
    return undef unless $value;
    Storable::thaw($value);
}

sub remove {
    my ($self,$key)=@_;
    $key = JSON::XS->new->utf8->canonical->encode( $key ) if ref $key;
    mdb->cache->remove({ _id=>$key });
}

sub get_keys {
    my ($self,)=@_;
    map { $_->{_id} } mdb->cache->find->fields({ _id=>1 });
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
