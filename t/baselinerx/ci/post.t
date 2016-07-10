use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use_ok 'BaselinerX::CI::post';

subtest 'text: returns text' => sub {
    _setup();

    my $post = TestUtils->create_ci('post');

    $post->put_data('hello');

    is $post->text, 'hello';
};

subtest 'text: returns unicode text' => sub {
    _setup();

    my $post = TestUtils->create_ci('post');

    $post->put_data('привет');

    is $post->text, 'привет';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
    );

    TestUtils->cleanup_cis;
}
