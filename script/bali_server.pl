#!/usr/bin/env perl

# configure trace
use FindBin;
use lib "$FindBin::Bin/../lib"; 
use Baseliner::Trace;
use v5.10;

use strict;

BEGIN { $ENV{CATALYST_SCRIPT_GEN} = 99; }

if( $ENV{BASELINER_PLACK_SERVER} ) {
    require Plack::Runner;

    say "Plackup start...";

    my $runner = Plack::Runner->new;
    $runner->{server} = 'Starman';
    $runner->parse_options(@ARGV);
    $runner->run;
} else {
    require Catalyst::ScriptRunner;
    Catalyst::ScriptRunner->run('Baseliner', 'Server');
}

1;

__DATA__
my $port              = $ENV{BASELINER_PORT} || $ENV{CATALYST_PORT} || 3000;
my $min_servers = $ENV{BASELINER_SERVER_MIN} || 5;
my $max_servers = $ENV{BASELINER_SERVER_MAX} || 50;
my $max_requests = $ENV{BASELINER_SERVER_MAX_REQUESTS} || 1000;
my $min_spare_servers = $ENV{BASELINER_SERVER_MIN_SPARE} || 3;
my $max_spare_servers = $ENV{BASELINER_SERVER_MAX_SPARE} || 10;
my $restart           = $ENV{BASELINER_RELOAD} || $ENV{CATALYST_RELOAD} || 0;

