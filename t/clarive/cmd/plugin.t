use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;

use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );
    TestEnv->setup( base => "$root/../../data/app-base", home => "$root/../../data/app-base/app-home" );
}

use Clarive::Cmd::plugin;
use Path::Class qw(dir);

subtest 'run_info: gets plugin info' => sub {
    my $cmd = _build_cmd();

    ok $cmd->run_info(plugin=>'my-plugin');
};

subtest 'run_new: generates dir' => sub {
    my $cmd = _build_cmd();

    my $tmp = Util->_tmp_dir;
    my $plugin_id = 'test-plugin-' . int rand 99999;

    local $cmd->app->{plugins_home} = $tmp;

    my $plugin_home = dir( $tmp, $plugin_id );
    $plugin_home->rmtree;

    $cmd->run_new(plugin=>$plugin_id);

    ok -e $plugin_home . '/plugin.yml';

    $plugin_home->rmtree;
};


sub _build_cmd {
    my (%params) = @_;

    return Clarive::Cmd::plugin->new( app => $Clarive::app, opts => {} );
}

done_testing;
