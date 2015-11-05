use strict;
use warnings;
use lib 't/lib';

use Test::More;
use TestEnv;
use TestUtils ':catalyst';
BEGIN { TestEnv->setup; }

use_ok 'Baseliner::Role::ControllerValidator';

subtest 'sets correct response on validation errors' => sub {
    my $controller = TestController->new;

    my $c = mock_catalyst_c( req => { params => {} } );

    $controller->action($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => {
                foo => 'REQUIRED'
            }
        }
      };
};

subtest 'returns action response on success' => sub {
    my $controller = TestController->new;

    my $c = mock_catalyst_c( req => { params => { foo => 1 } } );

    $controller->action($c);

    is_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => 'ok',
        }
      };
};

done_testing;

package TestController;
use Moose;

BEGIN { with 'Baseliner::Role::ControllerValidator'; }

sub action {
    my ( $self, $c ) = @_;

    return unless $self->validate_params( $c, foo => { isa => 'Int' } );

    $c->stash->{json} = { success => \1, msg => 'ok' };
    return 'bar';
}

1;
