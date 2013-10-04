package Baseliner::Schema::Profiler;
use strict;

use base 'DBIx::Class::Storage::Statistics';

use Time::HiRes qw(time);

my $start;

sub query_start {
    my $self = shift();
    my $sql = shift();
    my @params = @_;

    my $lev = substr( $ENV{DBIC_TRACE}, 0, 1 );
    $self->print("\n::: $sql: ".join(', ', @params)."\n");
    $self->print( Util->_whereami ) if defined $lev && $lev > 2;
    $start = time();
}

sub query_end {
    my $self = shift();
    my $sql = shift();
    my @params = @_;

    my $elapsed = sprintf("%0.4f", time() - $start);
    $self->print("   --> Execution took $elapsed seconds.\n");
    $start = undef;
    #push(@{ $calls{$sql} }, {
    #    params => \@params,
    #    elapsed => $elapsed
    #});
}

1;
