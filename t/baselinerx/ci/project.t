use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Baseliner::CI;
use Clarive::ci;
use Baseliner::Core::Registry;
use Baseliner::Role::CI;    # WTF this is needed for CI
use BaselinerX::CI::variable;

use_ok('BaselinerX::CI::project');

subtest 'variable any env' => sub {
    _setup();

    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ '*'=>{ var=>11 } } );
    is $prj->merged_variables->{var}, 11;
};

subtest 'variable some env' => sub {
    _setup();

    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ '*'=>{ var=>11 }, 'TEST'=>{ var=>99 } } );
    is $prj->merged_variables->{var}, 11;
    is $prj->merged_variables('TEST')->{var}, 99;
};

subtest 'variable not in some env' => sub {
    _setup();

    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ '*'=>{ var=>11 }, 'TEST'=>{ var=>99 } } );
    is $prj->merged_variables('PROD')->{var}, 11;
};

subtest 'variable from project default' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ '*'=>{ var=>11 }, 'TEST'=>{ var=>99 } } );
    is $prj->merged_variables('PROD')->{var}, 11;
};

subtest 'variable from variable default' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ 'TEST'=>{ var=>99 } } );
    is $prj->merged_variables('PROD')->{var}, 77;
};

subtest 'other variable from variable default' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $var2 = TestUtils->create_ci('variable',  name=>'other', variables=>{ '*'=>66, 'PROD'=>88 } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ } );
    is $prj->merged_variables('PROD')->{other}, 88;
    is $prj->merged_variables->{other}, 66;
};

subtest 'variable from parent' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, 'TEST'=>{ var=>200 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ '*'=>{ other=>10 },  } );
    is $prj->merged_variables('TEST')->{var}, 200;
};

subtest 'variable from parent without any variables' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, 'TEST'=>{ var=>200 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad );
    is $prj->merged_variables('TEST')->{var}, 200;
};

subtest 'variable any bl is before parent' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, 'TEST'=>{ var=>200 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ '*'=>{ var=>10 },  } );
    is $prj->merged_variables('TEST')->{var}, 10;
};

subtest 'variable some bl is before parent' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, 'TEST'=>{ var=>200 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ '*'=>{ var=>10 }, TEST=>{ var=>50 } } );
    is $prj->merged_variables('TEST')->{var}, 50;
};

subtest 'variable any bl from parent' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    is $prj->merged_variables('PROD')->{var}, 100;
};

subtest 'variable from default and skips parent' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    is $prj->merged_variables('PROD')->{var}, 77;
};

subtest 'variable from default no bl' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    is $prj->merged_variables->{var}, 44;
};

subtest 'variable from default some other bl' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ 'TEST'=>{var=>88 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    is $prj->merged_variables('QA')->{var}, 44;
};

subtest 'variable from default some other bl from saved and instantiated ci' => sub {
    _setup();

    my $var = TestUtils->create_ci('variable',  name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    my $dad = BaselinerX::CI::project->new(name=>'dad', moniker => 'daa', variables=>{ 'TEST'=>{var=>88 } } );
    $dad->save;
    my $prj = BaselinerX::CI::project->new(name=>'prj', moniker => 'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    my $mid = $prj->save;
    is( ci->new($mid)->merged_variables('QA')->{var}, 44 );
};

subtest 'import_template: throws an exception if not template' => sub {
    _setup();

    my $mid = BaselinerX::CI::project->new(name=>'dad', moniker => 'daa', variables=>{ 'TEST'=>{var=>'88' } } );
    $mid->save;
    like exception { ci->new($mid)->import_template() }, qr/Error: missing template/;
};

subtest 'import_template: keeps local variables if template is empty' => sub {
    _setup();

    my $template = TestUtils->create_ci('env_template',  name=>'template' );
    my $mid = BaselinerX::CI::project->new(name=>'dad', moniker => 'daa', variables=>{ 'TEST'=>{var=>'88' } } );
    $mid->save;

    ci->new($mid)->import_template(undef, {template=>$template->mid});

    my $variables = ci->new($mid)->{variables};
    cmp_deeply $variables, {'TEST' => {var=>'88'} };
};

subtest 'import_template: imports template variables' => sub {
    _setup();

    my $template = TestUtils->create_ci('env_template',  name=>'template', variables=>{ 'TEST'=>{var=>'88' } });
    my $mid = BaselinerX::CI::project->new(name=>'dad', moniker => 'daa');
    $mid->save;

    ci->new($mid)->import_template(undef, {template=>$template->mid});

    my $variables = ci->new($mid)->{variables};
    cmp_deeply $variables, {'TEST' => {var=>'88'} };
};

subtest 'import_template: overwrites local variables' => sub {
    _setup();

    my $template = TestUtils->create_ci('env_template',  name=>'template', variables=>{ 'TEST'=>{var=>'88' }, '*'=>{server=>'22'} });
    my $mid = BaselinerX::CI::project->new(name=>'dad', moniker => 'daa', variables=>{ 'TEST'=>{var=>'66' }, '*'=>{server=>'22'}});
    $mid->save;

    ci->new($mid)->import_template(undef, {template=>$template->mid});

    my $variables = ci->new($mid)->{variables};
    cmp_deeply $variables, {'TEST'=>{var=>'88' }, '*'=>{server=>'22'} };
};

done_testing();

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'Baseliner::Model::Permissions',
    );

    TestUtils->cleanup_cis;

    Clarive->config->{decrypt_key} = '44444';
}
