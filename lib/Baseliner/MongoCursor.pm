package Baseliner::MongoCursor;
use Mouse;
extends 'MongoDB::Cursor';

=head2 await_data

Use with a tailable cursor. If we are at the end of the data, 
block for a while rather than returning no data. After a 
timeout period, we do return as normal.

Boolean value, defaults to 0.

=cut

has await_data => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
);

sub each {
    my ($self, $code ) = @_;
    while( my $doc = $self->next ) {
        $code->($doc);
    }
}

=head2 _do_query

Overwrite this parent method to support await_data, 
until the mainline is patched.

=cut

sub _do_query {
    my ($self) = @_;

    if ($self->started_iterating) {
        return;
    }

    my $opts = ($self->_tailable() << 1) |
        (($MongoDB::Cursor::slave_okay | $self->slave_okay) << 2) |
        ($self->await_data << 5) |
        ($self->immortal << 4) |
        ($self->partial << 7);

    my ($query, $info) = MongoDB::write_query($self->_ns, $opts, $self->_skip, $self->_limit, $self->_query, $self->_fields);
    $self->_request_id($info->{'request_id'});

    $self->_client->send($query);
    $self->_client->recv($self);

    $self->started_iterating(1);
}

1;
