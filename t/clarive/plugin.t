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

subtest 'all_plugins: picks up all plugins' => sub {
    my $cnt =  Clarive::Plugins->all_plugins;
    is $cnt, 2;
};

subtest 'all_plugins: picks up all plugins, but just names' => sub {
    my @pg =  Clarive::Plugins->all_plugins( name_only=>1 );
    ok $pg[0] !~ /\//;
};

subtest 'locate_path: finds file' => sub {
    my $path =  Clarive::Plugins->locate_path('modules/test-module.js');
    like $path, qr{app-base/plugins/my-plugin/modules/test-module.js};
};

subtest 'locate_path: doesnt find file' => sub {
    my $path =  Clarive::Plugins->locate_path('modules/not-here-module.js');
    is $path, undef;
};

done_testing;

sub _setup { }
