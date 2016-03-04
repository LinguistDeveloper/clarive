use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use_ok 'Baseliner::Model::TopicExporter::Yaml';

subtest 'export: exports data' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content = $exporter->export( { foo => 'bar' } );

    like $content, qr/---\nfoo: bar/;
};

done_testing;

sub _setup {
}

sub _build_exporter {
    Baseliner::Model::TopicExporter::Yaml->new;
}
