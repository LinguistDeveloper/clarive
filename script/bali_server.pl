#!/usr/bin/env perl

=head1 bali_server

This script has two modes: direct Plack start 
and Catalyst::ScriptRunner server mode. 

These are Plack modes:

    BASELINER_SERVER=plack bali server 
    BASELINER_SERVER=Starman bali server 
    BASELINER_SERVER=Twiggy bali server 

These are Catalyst modes:

    BASELINER_SERVER=default bali server [ -d | -h | ... ]
    BASELINER_SERVER=prefork bali server [ -d | -h | ... ]

The main difference among them is that in Catalyst-mode
arguments are interpreted by Catalyst before 
being sent to Plack, so C<-d> is a working debug mode
that otherwise would have to be set like this:

    BASELINER_DEBUG=1 BASELINER_SERVER=Starman bali server

=cut

# configure trace
use FindBin;
use lib "$FindBin::Bin/../lib"; 
use Baseliner::Trace;
use v5.10;

use strict;

BEGIN { $ENV{CATALYST_SCRIPT_GEN} = 99; }

if( !$ENV{BASELINER_SERVER} || $ENV{BASELINER_SERVER} =~ /prefork|default/i ) {
    require Catalyst::ScriptRunner;
    Catalyst::ScriptRunner->run('Baseliner', 'Server');
} else {
    require Plack::Runner;


    my $runner = Plack::Runner->new;
    $runner->{server} = $ENV{BASELINER_SERVER}
        unless $ENV{BASELINER_SERVER} =~ /plack/i;
    say "Baseliner starting Plack server" 
        . ( $runner->{server} ? " ($runner->{server})" : "" );
    $runner->parse_options(@ARGV);
    $runner->run;
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

