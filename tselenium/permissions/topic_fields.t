use strict;
use warnings;

use Test::More;

use TestDriver;
use Selenium::ActionChains;

my $driver = TestDriver->new;

$driver->setup('TestPermissionsTopicFields');

subtest 'cannot edit topic fields without permissions' => sub {
    $driver->login('can_edit_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('.ui-topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    $driver->find_extjs_component('.ui-topic-panel .ui-btn-edit')->elem->click;

    my $form = $driver->wait_for_extjs_component('.ui-topic-panel .ui-topic-form');

    my $fields = $form->eval(<<'EOF');
var fields = {};
cmp.getForm().items.each(function(item) {
    fields[item.name] = {
        name: item.name,
        disabled: item.disabled
    };
});
return fields;
EOF

    is $fields->{project}->{disabled}, 1;
    is $fields->{release}->{disabled}, 1;
};

subtest 'can edit topic fields with permissions' => sub {
    $driver->login('can_edit_topic_fields', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('.ui-topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    $driver->find_extjs_component('.ui-topic-panel .ui-btn-edit')->elem->click;

    my $form = $driver->wait_for_extjs_component('.ui-topic-panel .ui-topic-form');

    my $fields = $form->eval(<<'EOF');
var fields = {};
cmp.getForm().items.each(function(item) {
    fields[item.name] = {
        name: item.name,
        disabled: item.disabled
    };
});
return fields;
EOF

    is $fields->{project}->{disabled}, 0;
    is $fields->{release}->{disabled}, 0;
};

subtest 'cannot see topic fields without permissions' => sub {
    $driver->login('can_see_some_topic_fields', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('.ui-topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    $driver->find_extjs_component('.ui-topic-panel .ui-btn-edit')->elem->click;

    my $form = $driver->wait_for_extjs_component('.ui-topic-panel .ui-topic-form');

    my $fields = $form->eval(<<'EOF');
var fields = {};
cmp.getForm().items.each(function(item) {
    fields[item.name] = {
        name: item.name,
        disabled: item.disabled
    };
});
return fields;
EOF

    ok !$fields->{release};
};

$driver->quit;

done_testing;
