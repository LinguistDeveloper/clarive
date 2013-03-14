#!/usr/bin/env perl

=head1 bali_server

This script has two modes: direct Plack start 
and Catalyst::ScriptRunner server mode. 

These are Plack modes:

    BASELINER_SERVER_ENGINE=plack bali server 
    BASELINER_SERVER_ENGINE=Starman bali server 
    BASELINER_SERVER_ENGINE=Twiggy bali server 

These are Catalyst modes:

    BASELINER_SERVER_ENGINE=default bali server [ -d | -h | ... ]
    BASELINER_SERVER_ENGINE=prefork bali server [ -d | -h | ... ]

The main difference among them is that in Catalyst-mode
arguments are interpreted by Catalyst before 
being sent to Plack, so C<-d> is a working debug mode
that otherwise would have to be set like this:

    BASELINER_DEBUG=1 BASELINER_SERVER_ENGINE=Starman bali server

=cut

# configure trace
use FindBin;
use lib "$FindBin::Bin/../lib"; 
use Baseliner::Trace;
use v5.10;

use strict;

BEGIN { $ENV{CATALYST_SCRIPT_GEN} = 99; }

if( !$ENV{BASELINER_SERVER_ENGINE} || $ENV{BASELINER_SERVER_ENGINE} =~ /prefork|default/i ) {
    require Catalyst::ScriptRunner;
    Catalyst::ScriptRunner->run('Baseliner', 'Server');
} else {
    require Plack::Runner;


    my $runner = Plack::Runner->new;
    $runner->{server} = $ENV{BASELINER_SERVER_ENGINE}
        unless $ENV{BASELINER_SERVER_ENGINE} =~ /plack/i;
    say "Baseliner starting Plack server" 
        . ( $runner->{server} ? " ($runner->{server})" : "" );
    $runner->parse_options(@ARGV);
    $runner->run;
}

1;

