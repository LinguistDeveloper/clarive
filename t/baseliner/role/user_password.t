use strict;
use warnings;

use Test::More;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

require Baseliner;

subtest 'save_data: encrypts' => sub {
    { package Clarive::TestUserPasswordRole;
        use Moose;
        with 'FakeCI';
        with 'Baseliner::Role::UserPassword';
    }

    my $ci = Clarive::TestUserPasswordRole->new( user=>'foo', password=>'bar' );
    Baseliner->config->{decrypt_key} = '11111';
    $ci->save_data( $ci, $ci, {} );

    is substr( Baseliner->decrypt( $ci->{db_data}->{password}, Baseliner::Role::UserPassword->_gen_user_key('foo') ), 10, -10 ), 'bar';
};

subtest 'load_data: decrypts' => sub {
    { package Clarive::TestUserPasswordRole2;
        use Moose;
        with 'FakeCI';
        with 'Baseliner::Role::UserPassword';
    }

    Baseliner->config->{decrypt_key} = '11111';
    my $password = Baseliner->encrypt(( 'x' x 10 ) . 'bar' . ( 'x' x 10 ) , Baseliner::Role::UserPassword->_gen_user_key('foo') );
    my $ci = Clarive::TestUserPasswordRole2->new( user=>'foo', password=>$password );
    $ci->load_data( '123', $ci );

    is $ci->password, 'bar';
};

done_testing;

{
    package FakeCI;
    use Moose::Role;

    sub save_data { $_[0]->{db_data} = $_[1]; }
    sub load_data {}
}
