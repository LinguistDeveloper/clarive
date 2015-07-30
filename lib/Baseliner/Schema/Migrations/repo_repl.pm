package Baseliner::Schema::Migrations::repo_repl;
use Moose;

sub upgrade {
    Util->_fail('Collection repl already exists') if mdb->repl->count;
    mdb->migra->repository_repl;
}

sub downgrade {
}

1;

