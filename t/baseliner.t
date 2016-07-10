use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use Cwd ();
use TestEnv;
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
    TestEnv->setup( base => "$root/data/app-base", home => "$root/data/app-base/app-home" );
}
use TestUtils;

use Class::Load qw(is_class_loaded);

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::CI::status;
use Baseliner::Utils;

# mock Baseliner subs
our $config = {};
require Baseliner;
sub Baseliner::config { $config };    # XXX had to monkey patch this one so config works

subtest 'core encrypt-decrypt working' => sub {
    _setup();

    Baseliner->config->{decrypt_key} = '11111';

    my $enc = Baseliner->encrypt('123');
    is(Baseliner->decrypt($enc), '123');
};

subtest 'plugins public/ available for static serving' => sub {
    _setup();

    my $app = Baseliner->build_app();   ## FIXME this can only be done once! Baseliner->new doesnt work, etc.

    ok grep { $_ =~ m{app-base/plugins/foo-plugin/public} } @{ Baseliner->config->{static}->{include_path} };

    my $classname = Util->to_ci_class('TestClassFromStatus');
    ok is_class_loaded( $classname );
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',
    );
}
