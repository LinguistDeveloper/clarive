package Baseliner::SchemaModel;
use strict;
use Baseliner::Core::DBI;
use base 'Catalyst::Model::DBIC::Schema';

sub dbcore {
    my $self = shift;
    return Baseliner::Core::DBI->new( dbi=>$self->storage->dbh );
}

=head1 DESCRIPTION

This module adds functionality (methods) to DBIC::Schema.

Replace this line in a model:

    use base 'Catalyst::Model::DBIC::Schema';

With:

    use base 'Baseliner::SchemaModel';

This is used in places like L<Baseliner::Model::Baseliner>.

=cut

1;
