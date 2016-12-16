use strict;
use warnings;

use Test::More;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use Clarive::mdb;
use Baseliner::Encryptor;
use BaselinerX::CI::variable;

subtest 'save_data: encrypts variables' => sub {
    _setup();

    {

        package Clarive::TestPasswordVariable;
        use Moose;
        with 'FakeCI';
        with 'Baseliner::Role::CI::VariableStash';
        sub icon { }
    }

    my $var = BaselinerX::CI::variable->new( name => 'var_pass', var_type => 'password' );
    $var->save;

    Clarive->config->{decrypt_key} = '11111';

    my $ci = Clarive::TestPasswordVariable->new( variables => { '*' => { var_pass => 'bar' } } );
    $ci->save_data( $ci, $ci, {} );

    my $enc_pass = Baseliner::Encryptor->decrypt( $ci->{db_data}{variables}{'*'}{var_pass}, Clarive->config->{decrypt_key} );
    is( substr( $enc_pass, 10, -10 ), 'bar' );
};

subtest 'save_data: database data saved encrypted' => sub {
    _setup();

    {

        package Clarive::TestPasswordVariable4;
        use Moose;
        with 'Baseliner::Role::CI::VariableStash';
        sub icon { }
    }

    my $var = BaselinerX::CI::variable->new( name => 'var_pass', var_type => 'password' );
    $var->save;

    Clarive->config->{decrypt_key} = '22222';

    my $pass = 'foobar';
    my $ci   = Clarive::TestPasswordVariable4->new( variables => { '*' => { var_pass => $pass } } );
    my $mid  = $ci->save;

    is(
        substr(
            Baseliner::Encryptor->decrypt( mdb->master_doc->find_one( { mid => $mid } )->{variables}{'*'}{var_pass} ),
            10, -10
        ),
        $pass
    );
};

subtest 'load_data: decrypts variables' => sub {
    _setup();

    {

        package Clarive::TestPasswordVariable2;
        use Moose;
        with 'FakeCI';
        with 'Baseliner::Role::CI::VariableStash';
        sub icon { }
    }

    my $var = BaselinerX::CI::variable->new( name => 'var_pass', var_type => 'password' );
    $var->save;

    Clarive->config->{decrypt_key} = '33333';

    my $password = Baseliner::Encryptor->encrypt( ( 'x' x 10 ) . 'bar' . ( 'x' x 10 ), Clarive->config->{decrypt_key} );
    my $ci = Clarive::TestPasswordVariable2->new( variables => { '*' => { var_pass => $password } } );
    $ci->load_data( '123', $ci );

    is $ci->variables->{'*'}{var_pass}, 'bar';
};

subtest 'cloak_password_variables: hides passwords in the variables stash' => sub {
    _setup();

    {

        package Clarive::TestPasswordVariable3;
        use Moose;
        with 'FakeCI';
        with 'Baseliner::Role::CI::VariableStash';
        sub icon { }
    }

    my $var = BaselinerX::CI::variable->new( name => 'var_pass', var_type => 'password' );
    $var->save;

    Clarive->config->{decrypt_key} = '7777';

    my $ci = Clarive::TestPasswordVariable3->new( variables => { '*' => { var_pass => 'bar' } } );
    my $mid = $ci->save;

    is_deeply( $ci->cloak_password_variables, { '*' => { var_pass => $Baseliner::CI::password_hide_str } } );
};

done_testing;

{

    package FakeCI;
    use Moose::Role;

    sub save_data { $_[0]->{db_data} = $_[1]; }
    sub load_data { }
}

sub _setup {
    Baseliner::Core::Registry->clear;
    TestUtils->cleanup_cis;
    TestUtils->register_ci_events;
}
