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

subtest 'decode_data: correctly decodes data' => sub {
    my $model = _build_model();

    my $output = $model->decode_data( _dump( { scopes => { step => ['bar'] } } ) );

    is_deeply $output, { scopes => { step => [ { name => 'bar' } ] } };
};

subtest 'encode_scopes: modifies mid/name to key/value' => sub {
    my $model = _build_model();

    my $output = $model->encode_scopes( ( { status => [ { mid => 'foo', name => 'bar' } ] } ) );

    is_deeply $output, { status => { 'foo' => 'bar' } };
};

subtest 'decode_data: converts list of steps names to list of hashes' => sub {
    my $model = _build_model();

    my $data = { scopes => { step => ['foo'] } };

    my $output = $model->decode_scopes( ($data), 'step' );

    is_deeply $output, [ { name => 'foo' } ];
};

subtest 'isValid: returns 1 if the value of the scopes exists in notify_scope ' => sub {
    my $model = _build_model();

    my $p = {
        data         => { scopes => { step => [ { name => 'foo' }, { name => 'bar' } ] } },
        notify_scope => { step   => 'foo' }
    };

    my $output = $model->isValid($p);

    is $output, 1;
};

done_testing;

sub _build_model {
    return Baseliner::Model::Notification->new();
}
