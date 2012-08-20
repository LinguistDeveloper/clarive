package Baseliner::Trace;
use strict;

if( $INC{'Devel/Trace/More.pm'} ) {
    require Time::HiRes;
    our $t0 = [Time::HiRes::gettimeofday() ];
    Devel::Trace::More::filter_on( sub {
        my ($p, $file, $line, $code) = @_;
        return unless "$file-$code" =~ /baseliner/i;
        $file =~ s/$ENV{BASELINER_HOME}//g;
        my $t = sprintf( "[%.04f]", Time::HiRes::tv_interval( $t0 ) );
        print STDERR "$t $file:$line: $code\n";
        return 0;
    });
}

1;
