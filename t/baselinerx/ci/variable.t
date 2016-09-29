use strict;
use warnings;

use Test::More;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup qw(_setup_clear);

use File::Temp qw(tempfile);

use Baseliner;
use Baseliner::CI;
use Clarive::ci;
use Clarive::mdb;
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

subtest 'encrypt variable on save' => sub {
    _setup_clear();

    Clarive->config->{decrypt_key} = '33333';

    my $var =
      BaselinerX::CI::variable->new( name => 'testing_var', var_type => 'password', variables => { '*' => 'bar' } );
    my $mid = $var->save;

    my $enc_pass = Baseliner::Role::CI::VariableStash->_encrypt_variable('bar');

    is(
        Baseliner::Role::CI::VariableStash->_decrypt_variable(
            mdb->master_doc->find_one( { mid => $mid } )->{variables}{'*'}
        ),
        'bar'
    );
};

done_testing;
