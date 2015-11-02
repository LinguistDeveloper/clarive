use strict;
use warnings;

use Test::More;
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

subtest 'variable default hash, any env' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'testing_var', variables=>{ '*'=>11, 'PROD'=>22 } );
    $var->save; # default hash requires saving first
    is( BaselinerX::CI::variable->default_hash()->{testing_var} , 11 );
};

subtest 'variable default hash, some env' => sub {
    _setup_clear();
    my $var = BaselinerX::CI::variable->new( name=>'testing_var', variables=>{ '*'=>11, 'PROD'=>22 } );
    $var->save; # default hash requires saving first
    is( BaselinerX::CI::variable->default_hash('PROD')->{testing_var} , 22 );
};

done_testing;
