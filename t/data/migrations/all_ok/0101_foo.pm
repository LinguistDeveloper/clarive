package TestMigration::0101_foo;
use Moo;

sub upgrade {
    $ENV{UPGRADE}++;
}

sub downgrade {
    $ENV{DOWNGRADE}++;
}

1;
