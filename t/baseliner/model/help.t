use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;
use TestUtils ':catalyst';

use Carp;
my $root;
BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
}

BEGIN {
    TestEnv->setup( base=>"$root/../../data/app-base", home=>"$root/../../data/app-base/app-home" );
}

use Baseliner::Core::Registry;
use Baseliner::Model::Help;

subtest 'docs_dirs: finds all base and home docs dirs' => sub {
    _setup();
    my $help = Baseliner::Model::Help->new;
    my @dirs = $help->docs_dirs;
    is scalar @dirs, 2;
};

subtest 'build_doc_tree: help tree is built from directory' => sub {
    _setup();

    my $help = Baseliner::Model::Help->new;
    my @tree = $help->build_doc_tree({ query=>'' }, Path::Class::dir("$root/../../data/app-base/app-home/docs") );
    is $tree[0]->{text}, 'Help Test';
};

subtest 'doc_search: finds simple string' => sub {
    _setup();
    my $doc = {
        title=>'test',
        text=>"this is a test",
    };
    my $help = Baseliner::Model::Help->new;
    $help->doc_search($doc,'is');
    ok length $doc->{found};
};

subtest 'doc_search: doesnt find simple string' => sub {
    _setup();
    my $doc = {
        title=>'test',
        text=>"this is a test",
    };
    my $help = Baseliner::Model::Help->new;
    $help->doc_search($doc,'noooo');
    ok !exists $doc->{found};
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

