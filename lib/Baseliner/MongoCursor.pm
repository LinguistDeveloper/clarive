package Baseliner::MongoCursor;
use Moose;
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

# sub _do_query {
#     my ($self) = @_;
 
#     $self->_master->rs_refresh();
 
#     # in case the refresh caused a repin
#     $self->_client(MongoDB::Collection::_select_cursor_client($self->_master, $self->_ns, $self->_query));
 
#     if ($self->started_iterating) {
#         return;
#     }
 
#     my $opts = ($self->_tailable() << 1) |
#         (($MongoDB::Cursor::slave_okay | $self->slave_okay) << 2) |
#         ($self->await_data << 5) |
#         ($self->immortal << 4) |
#         ($self->partial << 7);
 
#     my ($query, $info) = MongoDB::write_query($self->_ns, $opts, $self->_skip, $self->_limit, $self->_query, $self->_fields);
#     $self->_request_id($info->{'request_id'});
 
#     if ( length($query) > $self->_client->_max_bson_wire_size ) {
#         MongoDB::_CommandSizeError->throw(
#             message => "database command too large",
#             size => length $query,
#         );
#     }
 
#     eval {
#         $self->_client->send($query);
#         $self->_client->recv($self);
#     };
#     if ($@ && $self->_master->_readpref_pinned) {
#         $self->_master->repin();
#         $self->_client($self->_master->_readpref_pinned);
#         $self->_client->send($query);
#         $self->_client->recv($self);
#     }
#     elsif ($@) {
#         # rethrow the exception if read preference
#         # has not been set
#         die $@;
#     }
 
#     $self->started_iterating(1);
# }

sub hash_on {
    my ($self, $col ) = @_;
    my %ret;
    for my $row ( $self->all ) {
        my $k = $row->{ $col };
        push @{ $ret{ $k } }, $row;
    }
    return wantarray ? %ret : \%ret;
}

# same, but with one hash per key
sub hash_unique_on {
    my ($self, $col ) = @_;
    my %ret;
    for my $row ( $self->all ) {
        my $k = $row->{ $col };
        $ret{ $k } = $row;
    }
    return wantarray ? %ret : \%ret;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
