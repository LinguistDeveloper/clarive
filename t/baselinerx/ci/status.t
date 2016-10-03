use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;

use_ok 'BaselinerX::CI::status';

subtest 'combo_list: returns status when filter on status name' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $status_1 = TestUtils->create_ci( 'status', name => 'New',    type => 'I' );
    my $status_2 = TestUtils->create_ci( 'status', name => 'Active', type => 'I' );
    my $status_3 = TestUtils->create_ci( 'status', name => 'Finish', type => 'I' );

    my $ci = _build_ci_status();
    my $statuses = $ci->combo_list( { query => 'finish' } );

    is $statuses->{data}[0]->{name},      'Finish';
    is $statuses->{data}[0]->{id_status}, $status_3->{mid};
};

subtest 'combo_list: returns status when query is empty' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $status_1 = TestUtils->create_ci( 'status', name => 'New',    type => 'I' );
    my $status_2 = TestUtils->create_ci( 'status', name => 'Active', type => 'I' );
    my $status_3 = TestUtils->create_ci( 'status', name => 'Finish', type => 'I' );

    my $ci = _build_ci_status();
    my $statuses = $ci->combo_list( { query => '' } );

    is $statuses->{data}[0]->{name}, 'Active';
    is $statuses->{data}[1]->{name}, 'Finish';
    is $statuses->{data}[2]->{name}, 'New';
};

subtest 'combo_list: returns status when filter on id status' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        username => 'root'
    );

    my $status_1 = TestUtils->create_ci( 'status', name => 'New',    type => 'I' );
    my $status_2 = TestUtils->create_ci( 'status', name => 'Active', type => 'I' );
    my $status_3 = TestUtils->create_ci( 'status', name => 'Finish', type => 'I' );

    my $query = "$status_1->{id_status}" . "|" . "$status_2->{id_status}";

    my $ci = _build_ci_status();
    my $statuses = $ci->combo_list( { query => $query, valuesqry => 'true' } );

    is $statuses->{data}[0]->{name}, 'Active';
    is $statuses->{data}[1]->{name}, 'New';
};

subtest 'combo_list: returns query when extra values' => sub {
    _setup();

    my $ci = _build_ci_status();
    my $statuses = $ci->combo_list( { query => 'custom value', valuesqry => 'true', with_extra_values => 'true' } );

    is $statuses->{data}[0]->{name}, 'custom value';
};

done_testing;

sub _build_ci_status {
    BaselinerX::CI::status->new();
}

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::CI',

    );
    TestUtils->cleanup_cis;
    mdb->role->drop;
}
