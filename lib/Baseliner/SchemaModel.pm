package Baseliner::SchemaModel;
use strict;
use Baseliner::Core::DBI;
use base 'Catalyst::Model::DBIC::Schema';

sub dbcore {
    my $self = shift;
    return Baseliner::Core::DBI->new( dbi=>$self->storage->dbh );
}

1;
