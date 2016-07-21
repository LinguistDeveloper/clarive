use strict;
use warnings;

use Test::More;

use TestDriver;

my $driver = TestDriver->new;

$driver->setup('TestPermissionsExplorer');

subtest 'cannot see lifecycle panel without permission' => sub {
    $driver->login('nobody', 'password');

    ok $driver->element_not_visible('#explorer');
};

subtest 'can see lifecycle panel with permission' => sub {
    $driver->login('can_see_lifecycle', 'password');

    ok $driver->element_visible('#explorer');
};

subtest 'cannot see releases in lifecycle panel without permission' => sub {
    $driver->login('can_see_lifecycle', 'password');

    ok $driver->element_not_visible('#explorer-releases');
};

subtest 'can see releases in lifecycle panel with permission' => sub {
    $driver->login('can_see_lifecycle_releases', 'password');

    ok $driver->element_visible('#explorer-releases');
};

subtest 'cannot see dashboards in lifecycle panel without permission' => sub {
    $driver->login('can_see_lifecycle', 'password');

    ok $driver->element_not_visible('.ui-explorer-dashboards');
};

subtest 'can see dashboards in lifecycle panel with permission' => sub {
    $driver->login('can_see_lifecycle_dashboards', 'password');

    ok $driver->element_visible('.ui-explorer-dashboards');
};

subtest 'cannot see reports in lifecycle panel without permission' => sub {
    $driver->login('can_see_lifecycle', 'password');

    ok $driver->element_not_visible('.ui-explorer-reports');
};

subtest 'can see reports in lifecycle panel with permission' => sub {
    $driver->login('can_see_lifecycle_reports', 'password');

    ok $driver->element_visible('.ui-explorer-reports');
};

$driver->quit;

done_testing;
