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

my $verb = ""; #shift;
my %opts = _get_options @ARGV;

#say "Options $verb" . _dump \%opts;

chdir $ENV{BASELINER_HOME};
my $base = qq{git submodule %s http://git.vasslabs.com/git/%s.git %s};
while( my ($cmd, $v) = each %opts ) {
    given( $cmd ) {
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
    }
}
