use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;

use Baseliner::Utils qw(_dump);

use_ok 'Baseliner::Model::Notification';

subtest 'decode_data: modifies key/value to mid/name' => sub {
    my $model = _build_model();

    my $output = $model->decode_data( _dump( { scopes => { status => { foo => 'bar' } } } ) );

    is_deeply $output, {
        scopes => {
            status => [
                {   mid  => 'foo',
                    name => 'bar'
                }
            ]
        }
    };
};

subtest 'encode_scopes: modifies mid/name to key/value' => sub {
    my $model = _build_model();

    my $output = $model->encode_scopes( ( { status => [ { mid => 'foo', name => 'bar' } ] } ) );

    is_deeply $output, { status => { 'foo' => 'bar' } };
};

done_testing;

sub _build_model {
    return Baseliner::Model::Notification->new();
}
