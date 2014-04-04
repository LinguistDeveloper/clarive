use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Baseliner::Utils;

{
    my $chk = sub{
       my ($orig,$v) = @_;
       my $k=0;
       while( $v =~ /(\d+)(\w)\s?/g ) {
           my ($n,$t) = ($1,$2);
           $k += $n * ( $t eq 'Y' ? 31622400 : $t eq 'M'?2629743.999999999317419: $t eq 'D'?86400: $t eq 'h'?3600: $t eq 'm'?60 : 1); 
       }
       my $d = abs(($k-$orig)/$orig);
       ok $d < .1, "to_dur check: $d < .01 ($orig,$k - $v)";
    };
    $chk->( $_, Util->to_dur($_) ) for map { int( $_ * 12 ** (1+($_ % 10)) )  } 1..1000;
    
}

done_testing;

