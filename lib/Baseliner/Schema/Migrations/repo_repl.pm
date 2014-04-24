package Baseliner::Schema::Migrations::repo_repl;
use Mouse;

sub upgrade {
    mdb->migra->repository_repl;
}

sub downgrade {
}

1;

