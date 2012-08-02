#!/usr/bin/perl 
=head1 NAME

bali feature

=head1 DESCRIPTION

Add, update and manage features.

=cut
use strict;
use warnings;
use v5.10;
use Baseliner::Utils;

say 'Baseliner Feature Manager 1.0';
my $verb = ""; #shift;
my %opts = _get_options @ARGV;

#say "Options $verb" . _dump \%opts;

sub usage { say "Usage: "; say join '',<DATA>; }

keys %opts or do { usage(); exit 1 };

chdir $ENV{BASELINER_HOME};
my $base = qq{git submodule %s http://git.vasslabs.com/git/%s.git %s};
while( my ($cmd, $v) = each %opts ) {
    for( $cmd ) {
        when( 'add' ) {
            my $s = sprintf $base => $cmd, $v, "features/$v"; 
            say $s ;
            system $s;
            system qw/git submodule init/;
            system qw/git submodule update/;
        }
        when( 'update' ) {
            my $s = sprintf $base => $cmd, $v;
            say $s ;
            system $s;
        }
        when( 'h' ) {
            usage();
        }
        default {
            say "Unrecognized command: '$_'";
            usage();
        }
    }
}

__DATA__

bali feature --<cmd> <param>

    --add <feature_name>      add git submodule, then init and update 
    --update <feature_name>   add git submodule and done   

examples:

    bali feature --add artifacts
