=head1 DESCRIPTION

This base class allows you to get some extra juice from the
DBIC resultset. 

    $c->model('Baseliner::BaliUser')->search()->each( sub { _log $_->username } );

    $c->model('Baseliner::BaliUser')->search()->hashref->each( sub { _log $_->{username} } );

=cut
package Baseliner::Schema::Baseliner::Base::ResultSet;
use strict;
use warnings;
use parent qw/DBIx::Class::ResultSet/;

__PACKAGE__->load_components("Helper::ResultSet::SetOperations");  # for the union
#__PACKAGE__->load_components("Helper::ResultSet");  # all helpers, but need testing

=head2 hashref

Changes the resultset so that hashes are returned
instead of methods.

    my @rows = $c->model('Baseliner::BaliUser')->search->hashref->all;
    $c->stash->{json} = { data=> \@rows };

=cut
sub hashref {
    my ($self ) = @_;
    $self->result_class('DBIx::Class::ResultClass::HashRefInflator');
    return $self;
}

=head2 each

Iterates over a result set, calling your code and 
setting C<$_> in the process. 

=cut
sub each {
    my ($self, $code ) = @_;
    while( my $row = $self->next ) {
        local $_ = $row;
        $code->($row);
    }
}

=head2 hash_on column_name

Creates a hash keyed on a column_name, such as:

    key1:
       - 
        col1: val1
        col2: val2
       - 
        col1: val3
        col2: val4

Returns a HASHREF (scalar) or HASH (list) depending on context.

=cut
sub hash_on {
    my ($self, $col ) = @_;
    my %ret;
    for my $row ( $self->hashref->all ) {
        my $k = $row->{ $col };
        push @{ $ret{ $k } }, $row;
    }
    return wantarray ? %ret : \%ret;
}

# same, but with one hash per key
sub hash_unique_on {
    my ($self, $col ) = @_;
    my %ret;
    for my $row ( $self->hashref->all ) {
        my $k = $row->{ $col };
        $ret{ $k } = $row;
    }
    return wantarray ? %ret : \%ret;
}

1;

