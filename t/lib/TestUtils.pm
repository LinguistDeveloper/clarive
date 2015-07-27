package TestUtils;

use strict;
use warnings;

use Clarive::mdb;
use Clarive::ci;

sub cleanup_cis {
    my $class = shift;

    mdb->master->drop;
    mdb->master_doc->drop;
    mdb->master_rel->drop;
}

sub create_amazon_account {
    my $class = shift;

    my $account = ci->amazon_account->new(
        mid        => "1",
        access_key => 'ACCESS KEY',
        secret_key => 'SECRET KEY',
        region     => 'us-west-2',
        active     => 1,
        @_
    );
    $account->save;
    return $account;
}

sub create_amazon_instance {
    my $class = shift;

    my $instance = ci->amazon_instance->new(
        mid         => "2",
        instance_id => 'i-1234567890',
        @_
    );
    $instance->save;
    return $instance;
}

1;
