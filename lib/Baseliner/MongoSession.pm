package Baseliner::MongoSession;
use Moose;
our $VERSION = '0.02';
use namespace::autoclean;
use Storable;
use Try::Tiny;

BEGIN { extends 'Catalyst::Plugin::Session::Store' }

has collectionname => (
    isa => 'Str',
    is => 'ro',
    lazy_build => 1,
);

use Sereal;
has _encoder => qw(is rw isa Object lazy 1 default), sub{ 
    Sereal::Encoder->new({ compress=>1, compress_threshold=>1_024_000, compress_level=>1, canonical=>1 }) 
}; 
has _decoder => qw(is rw isa Object lazy 1 default), sub{ Sereal::Decoder->new }; 

sub _cfg_or_default {
    my ($self, $name, $default) = @_;

    my $cfg = $self->_session_plugin_config;

    return $cfg->{$name} || $default;
}

sub _build_collectionname {
    my ($self) = @_;
    return $self->_cfg_or_default('collectionname', 'session');
}

sub _serialize {
    my ($self, $data) = @_;
    my $d = $self->_encoder->encode( $data );
    return $d;
}

sub _deserialize {
    my ($self, $data, $type) = @_;
    my $d = try { $self->_decoder->decode($data) } catch { try { Storable::thaw( $data ) } catch { $data } }; # XXX Storable is legacy, deprecate
    return $d;
}

sub collection {
    my ($self)=@_;
    mdb->collection($self->collectionname);
}

sub get_session_data {
    my ($self, $key) = @_;

    my ($prefix, $id) = split(/:/, $key);

    my $found = $self->collection->find_one({ _id => $id },
        { $prefix => 1, 'expires' => 1 });

    return undef unless $found;

    if ($found->{expires} && time() > $found->{expires}) {
        $self->delete_session_data($id);
        return undef;
    }

    # rgo: $prefix can be either session or expires (but not sure), session includes sessiond data.
    return $prefix eq 'session' && length $found->{$prefix} 
        ? $self->_deserialize($found->{$prefix}, $found->{type}) 
        : $prefix eq 'expires' 
            ? $found->{$prefix}
            : $self->_deserialize($found->{$prefix},$found->{type});
}

sub store_session_data {
    my ($self, $key, $data) = @_;

    my ($prefix, $id) = split(/:/, $key);

    # we need to not serialize the expires date, since it comes in as an
    # integer and we need to preserve that in order to be able to use
    # mongodb's '$lt' function in delete_expired_sessions()
    my $serialized;
    if ($prefix =~ /^expires$/) {
        $serialized = $data;
    } else {
        $serialized = $self->_serialize($data);
    }

    $self->collection->update({ _id => $id },
        { '$set' => { $prefix => $serialized, type=>'sereal' }, '$currentDate'=>{t=>boolean::true} }, { upsert => 1 });
}

sub delete_session_data {
    my ($self, $key) = @_;

    my ($prefix, $id) = split(/:/, $key);

    my $found = $self->collection->find_one({ '$or'=>[ {_id => $id},{ _id=>$key }] });
    return unless $found;

    if (exists($found->{$prefix})) {
        if ((scalar(keys(%$found))) > 2) {
            $self->collection->update({ _id => $id },
                { '$unset' => { $prefix => 1 }} );
            return;
        } else {
            $self->collection->remove({ _id => $id });
        }
    }
}

sub delete_expired_sessions {
    my ($self) = @_;

    $self->collection->remove({ 'expires' => { '$lt' => time() } });
}

__PACKAGE__->meta->make_immutable;

1;

