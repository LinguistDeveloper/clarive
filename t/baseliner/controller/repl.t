use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;

use TestEnv;
use Carp;
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
}

BEGIN {
    TestEnv->setup( base => "$root/../../data/app-base", home => "$root/../../data/app-base/app-home" );
}

use TestUtils ':catalyst';
use Baseliner::Utils qw(_dump _load);

use_ok 'Baseliner::Controller::REPL';

subtest 'eval: perl code executed' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c(
        req => {
            params => {
                eval                       => 1,
                dump                       => "yaml",
                show                       => "cons",
                lang                       => 'perl',
                code                       => 'my $x = 123;',
                _merge_with_params         => 1,
                as_json                    => 1,
                _bali_login_count          => 0,
                _bali_notify_valid_session => 1

            }
        }
    );

    $controller->eval($c);

    #warn Util->_dump( $c->stash->{json},1 );
    my $res = _load( $c->stash->{json}{result} );
    is $res, 123;
};

subtest 'eval: javascript code executed' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c(
        req => {
            params => {
                eval                       => 1,
                dump                       => "yaml",
                show                       => "cons",
                lang                       => 'js-server',
                code                       => 'var x = 123; x',
                _merge_with_params         => 1,
                as_json                    => 1,
                _bali_login_count          => 0,
                _bali_notify_valid_session => 1

            }
        }
    );

    $controller->eval($c);

    my $res = _load( $c->stash->{json}{result} );
    is $res, 123;
};

subtest 'repl: code saved to history' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c(
        req => {
            params => {
                lang                       => 'perl',
                code                       => 'var x = 123; x',
            }
        }
    );

    $controller->eval($c);
    $controller->tree_hist($c);
    is scalar( @{ $c->stash->{json} } ), 1;
};

subtest 'tidy: tidy some code' => sub {
    _setup();

    my $controller = _build_controller();
    my $c = _build_c(
        req => {
            params => {
                code                       => "if(1){\n22;}",
                _merge_with_params         => 1,
                as_json                    => 1,
                _bali_login_count          => 0,
                _bali_notify_valid_session => 1
            }
        }
    );

    $controller->tidy($c);

    my $lines = scalar split /\n/, $c->stash->{json}{code} ;
    is $lines, 3;
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );

    TestUtils->cleanup_cis;
}

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::REPL->new( application => '' );
}
