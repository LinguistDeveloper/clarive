#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catalyst::Test 'Baseliner';
use Devel::REPL::Script 'run';
#use Devel::REPL;
#my $repl = Devel::REPL->new;
#$repl->run;
