#!/usr/bin/env perl

BEGIN {
    $ENV{CATALYST_SCRIPT_GEN} = 99;
}

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('Baseliner', 'Server');

1;

__DATA__
my $port              = $ENV{BASELINER_PORT} || $ENV{CATALYST_PORT} || 3000;
my $min_servers = $ENV{BASELINER_SERVER_MIN} || 5;
my $max_servers = $ENV{BASELINER_SERVER_MAX} || 50;
my $max_requests = $ENV{BASELINER_SERVER_MAX_REQUESTS} || 1000;
my $min_spare_servers = $ENV{BASELINER_SERVER_MIN_SPARE} || 3;
my $max_spare_servers = $ENV{BASELINER_SERVER_MAX_SPARE} || 10;
my $restart           = $ENV{BASELINER_RELOAD} || $ENV{CATALYST_RELOAD} || 0;

