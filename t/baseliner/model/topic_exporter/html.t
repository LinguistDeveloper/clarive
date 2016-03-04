use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use_ok 'Baseliner::Model::TopicExporter::Html';

subtest 'export: exports data' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content = $exporter->export( { foo => 'bar' } );

    is_deeply $content, [ data => { foo => 'bar' } ];
};

done_testing;

sub _setup {
}

sub _build_exporter {
    Baseliner::Model::TopicExporter::Html->new(
        renderer => sub {
            return [@_];
        }
    );
}
