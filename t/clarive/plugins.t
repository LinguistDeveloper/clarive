use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use TestEnv;

use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
    TestEnv->setup( base => "$root/../data/app-base", home => "$root/../data/app-base/app-home" );
}

use Clarive::App;
use Clarive::Plugins;

use Baseliner::Role::CI;    # WTF this is needed for CI
use BaselinerX::CI::status;

subtest 'all_plugins: picks up all plugins' => sub {
    my $cnt =  Clarive::Plugins->new->all_plugins;
    is $cnt, 2;
};

subtest 'all_plugins: picks up all plugins, but just names' => sub {
    my @pg =  Clarive::Plugins->new->all_plugins( id_only=>1 );
    ok $pg[0] !~ /\//;
};

subtest 'load_info: loads plugin info' => sub {
    my $pg = Clarive::Plugins->new;
    my $home = $pg->locate_plugin('my-plugin');
    my $info = $pg->load_info($home);
    is $info->{name}, 'My Plugin';
};

subtest 'locate_plugin: finds a plugin home' => sub {
    my $home =  Clarive::Plugins->new->locate_plugin('my-plugin');
    ok $home;
};

subtest 'locate_all: finds all dirs' => sub {
    my @paths =  Clarive::Plugins->new->locate_all('public');
    is @paths, 2;
};

subtest 'locate_first: finds file' => sub {
    my $item =  Clarive::Plugins->new->locate_first('modules/test-module.js');
    like $item->{path}, qr{app-base/plugins/my-plugin/modules/test-module.js};
};

subtest 'locate_first: doesnt find file' => sub {
    my $item =  Clarive::Plugins->new->locate_first('modules/not-here-module.js');
    is $item, undef;
};

subtest 'run_dir: loads file in init/ dir' => sub {
    my $path =  Clarive::Plugins->new->run_dir('init');
    my $ci = BaselinerX::CI::TestClassFromStatus->new( name=>'foo' );
    like ref $ci, qr/TestClassFromStatus/;
};

subtest 'for_each_file: recurse modules/ dir' => sub {

    my @files;
    my @plugins;

    Clarive::Plugins->new->for_each_file('modules',sub{ push @files, shift; push @plugins, shift });

    is @files, 2;
    is @plugins, 2;
    cmp_deeply \@plugins, ['my-plugin','my-plugin'];
};

done_testing;

sub _setup { }
