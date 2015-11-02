use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use lib 't/lib';
use TestEnv;
use TestSetup qw(_setup_clear);

TestEnv->setup;

use File::Temp qw(tempfile);

use Baseliner::CI;
use Clarive::ci;
use Baseliner::Core::Registry;
use Baseliner::Role::CI;    # WTF this is needed for CI
use BaselinerX::CI::project;
use BaselinerX::CI::variable;

subtest 'variable any env' => sub {
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ '*'=>{ var=>11 } } );
    is $prj->merged_variables->{var}, 11;
};

subtest 'variable some env' => sub {
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ '*'=>{ var=>11 }, 'TEST'=>{ var=>99 } } );
    is $prj->merged_variables->{var}, 11;
    is $prj->merged_variables('TEST')->{var}, 99;
};

subtest 'variable not in some env' => sub {
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ '*'=>{ var=>11 }, 'TEST'=>{ var=>99 } } );
    is $prj->merged_variables('PROD')->{var}, 11;
};

subtest 'variable from project default' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ '*'=>{ var=>11 }, 'TEST'=>{ var=>99 } } );
    is $prj->merged_variables('PROD')->{var}, 11;
};

subtest 'variable from variable default' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ 'TEST'=>{ var=>99 } } );
    is $prj->merged_variables('PROD')->{var}, 77;
};

subtest 'other variable from variable default' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $var2 = BaselinerX::CI::variable->new( name=>'other', variables=>{ '*'=>66, 'PROD'=>88 } );
    $var2->save;
    my $prj = BaselinerX::CI::project->new(name=>'prj', variables=>{ } );
    is $prj->merged_variables('PROD')->{other}, 88;
    is $prj->merged_variables->{other}, 66;
};

subtest 'variable from parent' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, 'TEST'=>{ var=>200 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ '*'=>{ other=>10 },  } );
    is $prj->merged_variables('TEST')->{var}, 200;
};

subtest 'variable any bl is before parent' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, 'TEST'=>{ var=>200 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ '*'=>{ var=>10 },  } );
    is $prj->merged_variables('TEST')->{var}, 10;
};

subtest 'variable some bl is before parent' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, 'TEST'=>{ var=>200 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ '*'=>{ var=>10 }, TEST=>{ var=>50 } } );
    is $prj->merged_variables('TEST')->{var}, 50;
};

subtest 'variable any bl from parent' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ '*'=>{ var=>100 }, } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    is $prj->merged_variables('PROD')->{var}, 100;
};

subtest 'variable from default and skips parent' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    is $prj->merged_variables('PROD')->{var}, 77;
};

subtest 'variable from default no bl' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    is $prj->merged_variables->{var}, 44;
};

subtest 'variable from default some other bl' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ 'TEST'=>{var=>88 } } );
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    is $prj->merged_variables('QA')->{var}, 44;
};

subtest 'variable from default some other bl from saved and instantiated ci' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'var', variables=>{ '*'=>44, 'PROD'=>77 } );
    $var->save;
    my $dad = BaselinerX::CI::project->new(name=>'dad', variables=>{ 'TEST'=>{var=>88 } } );
    $dad->save;
    my $prj = BaselinerX::CI::project->new(name=>'prj', parent_project=>$dad, variables=>{ TEST=>{ var=>50 } } );
    my $mid = $prj->save;
    is( ci->new($mid)->merged_variables('QA')->{var}, 44 );
};

done_testing;
