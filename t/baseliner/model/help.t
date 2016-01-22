use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst';
use Baseliner::Utils qw(_dir _file);

my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
    TestEnv->setup( base => "$root/../../data/app-base", home => "$root/../../data/app-base/app-home" );
}

use Baseliner::Model::Help;

subtest 'docs_dirs: finds all base and home docs dirs' => sub {
    _setup();

    my $help = Baseliner::Model::Help->new;

    my @dirs = $help->docs_dirs;

    cmp_deeply \@dirs, [ re(qr{app-home/docs/en}), re(qr{features/testfeature/docs/en}) ];
};

subtest 'docs_dirs: finds all base and home docs dirs by language' => sub {
    _setup();

    my $help = Baseliner::Model::Help->new;

    my @dirs = $help->docs_dirs('es');

    cmp_deeply \@dirs, [ re(qr{app-home/docs/es}), re(qr{features/testfeature/docs/es}) ];
};

subtest 'build_doc_tree: help tree is built from directory' => sub {
    _setup();

    my $help = Baseliner::Model::Help->new;
    my @tree = $help->build_doc_tree( { query => '' }, _dir("$root/../../data/app-base/app-home/docs/en") );

    cmp_deeply \@tree,
      [
        {
            'icon' => ignore(),
            'text' => 'Help Test',
            'data' => {
                'path' => 'test.markdown'
            },
            'search_results' => {
                'matches' => undef,
                'found'   => undef
            },
            'leaf' => \1
        }
      ];
};

subtest 'build_doc_tree: help tree is built from directory by language' => sub {
    _setup();

    my $help = Baseliner::Model::Help->new;
    my @tree = $help->build_doc_tree( { query => '' }, _dir("$root/../../data/app-base/app-home/docs/es") );

    is $tree[0]->{text}, 'Ayuda Test';
};

subtest 'build_doc_tree: returns only matches results when query' => sub {
    _setup();

    my $help = Baseliner::Model::Help->new;
    my @tree =
      $help->build_doc_tree( { query => 'Help' }, _dir("$root/../../data/app-base/app-home/docs/en") );

    cmp_deeply \@tree,
      [
        {
            'icon' => ignore(),
            'text' => 'Help Test',
            'data' => {
                'path' => 'test.markdown'
            },
            'search_results' => {
                'matches' => '21',
                'found'   => "<strong>Help</strong> Test.\n..."
            },
            'leaf' => \1
        }
      ];
};

subtest 'doc_matches: finds simple string' => sub {
    _setup();

    my $doc = {
        title => 'test',
        text  => "this is a test",
    };

    my $help = Baseliner::Model::Help->new;

    ok $help->doc_matches( $doc, 'is' );
    ok length $doc->{found};
};

subtest 'doc_matches: doesnt find simple string' => sub {
    _setup();

    my $doc = {
        title => 'test',
        text  => "this is a test",
    };

    my $help = Baseliner::Model::Help->new;

    ok !$help->doc_matches( $doc, 'noooo' );
    ok !exists $doc->{found};
};

subtest 'parse_body: parses body' => sub {
    _setup();

    my $help = Baseliner::Model::Help->new;

    my $data = $help->parse_body(
        _file("$root/../../data/app-base/app-home/docs/es/test.markdown"),
        _dir("$root/../../data/app-base/app-home/docs/es")
    );

    cmp_deeply $data, {
        'name' => 'test',
        'path' => re(qr{app-home/docs/es/test\.markdown$}),
        'tags' => [],
        'body' => '
Ayuda Test.
',
        'index' => 100,
        'tpl'   => 'default',
        'html'  => '<p>Ayuda Test.</p>
',
        'uniq_id' => 'test',
        'yaml'    => '---
title: Ayuda Test
',
        'text' => 'Ayuda Test.
',
        'id'    => 'test',
        'title' => 'Ayuda Test'
    };
};

done_testing;

sub _setup { }
