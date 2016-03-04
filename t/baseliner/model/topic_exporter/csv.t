use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use_ok 'Baseliner::Model::TopicExporter::Csv';

subtest 'export: exports data' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content =
      $exporter->export( [ { foo => 'bar' }, { foo => 'baz' } ], columns => [ { id => 'foo', name => 'Foo' } ] );

    like $content, qr/"bar"\n"baz"/;
};

subtest 'export: appends new lines until length is 1024' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content =
      $exporter->export( [ { foo => 'bar' }, { foo => 'baz' } ], columns => [ { id => 'foo', name => 'Foo' } ] );

    is length $content, 1025;
};

done_testing;

sub _setup {
}

sub _build_exporter {
    Baseliner::Model::TopicExporter::Csv->new(
        renderer => sub {
            return [@_];
        }
    );
}
