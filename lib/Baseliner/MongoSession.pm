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
    my $d = Storable::freeze( $data );
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
        ? Storable::thaw($found->{$prefix}) 
        : $prefix eq 'expires' 
            ? $found->{$prefix}
            : try { Storable::thaw($found->{$prefix}) } catch { $found->{$prefix} };
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
        { '$set' => { $prefix => $serialized } }, { upsert => 1 });
}

sub delete_session_data {
    my ($self, $key) = @_;

    my ($prefix, $id) = split(/:/, $key);

    my $found = $self->collection->find_one({ _id => $id });
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

