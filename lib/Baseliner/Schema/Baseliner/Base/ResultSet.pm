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

1;

