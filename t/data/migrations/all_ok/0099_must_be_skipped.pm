package TestMigration::0099_must_be_skipped;
use Moo;

sub upgrade {
    die 'SKIP ME!';
}

sub downgrade {
}

1;
