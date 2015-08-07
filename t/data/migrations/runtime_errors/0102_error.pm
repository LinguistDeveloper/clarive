package TestMigration::0102_error;
use Moo;

sub upgrade {
    die 'runtime error';
}

sub downgrade {
}

1;
