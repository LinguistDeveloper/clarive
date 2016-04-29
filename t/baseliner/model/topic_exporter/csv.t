use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::LongString;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use Encode;

use_ok 'Baseliner::Model::TopicExporter::Csv';

subtest 'export: exports data' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content =
      $exporter->export( [ { foo => 'bar' }, { foo => 'baz' } ], columns => [ { id => 'foo', name => 'Foo' } ] );

    like $content, qr/"bar"\n"baz"/;
};

subtest 'export: exports data with unicode' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content =
      $exporter->export( [ { 'как' => 'дела?' } ], columns => [ { id => 'как', name => 'Как' } ] );

    like Encode::decode( 'UTF-8', $content ), qr/"дела\?"/;
};

subtest 'export: appends new lines until length is 1024' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content =
      $exporter->export( [ { foo => 'bar' }, { foo => 'baz' } ], columns => [ { id => 'foo', name => 'Foo' } ] );

    is length $content, 1025;
};

subtest 'export: split the field more_info in 4 field' => sub {
    _setup();

    my $exporter = _build_exporter();

    my $content = $exporter->export(
        [
            {
                title          => 'Test',
                user           => 'Developer',
                value          => '100',
                numcomment     => '2',
                referenced_in  => [ 'Foo', 'Bar' ],
                references_out => ['Baz'],
                num_file       => '1'
            },
            {
                title          => 'Test2',
                user           => 'Developer',
                value          => '50',
                numcomment     => '1',
                referenced_in  => ['Foo'],
                references_out => ['Bar'],
                num_file       => '2'
            }
        ],
        columns => [
            { id => 'title',      name => 'Title' },
            { id => 'user',       name => 'User Name' },
            { id => 'value',      name => 'Value Name' },
            { id => 'numcomment', name => 'More Info' }
        ]
    );

    is_string $content,
        "\xEF\xBB\xBF"
      . qq{"Title";"User Name";"Value Name";"More Info";"Referenced In";"References";"Attachments"\n}
      . qq{"Test";"Developer";"100";"2";"2";"1";"1"\n}
      . qq{"Test2";"Developer";"50";"1";"1";"1";"2"}
      . ( "\n" x 853 );
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
