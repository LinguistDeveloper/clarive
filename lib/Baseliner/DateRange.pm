package Baseliner::DateRange;
use Moose;

use Class::Date;
use Baseliner::Utils qw(_now);

sub build_pair {
    my $self = shift;
    my ( $range, $offset ) = @_;

    my $now = _now();

    $range ||= 'day';

    my $from = Class::Date->new( substr( $now, 0, 10 ) . ' 00:00:00' );
    my $to   = Class::Date->new( substr( $now, 0, 10 ) . ' 23:59:59' );

    if ( $range eq 'day' ) {
        if ($offset) {
            $from = $from + "-${offset}D";
            $to   = $to + "-${offset}D";
        }
    }
    elsif ( $range eq 'week' ) {
        my $start_of_week = 1;

        $from = substr( $now, 0, 10 ) . ' 00:00:00';
        $from = Class::Date->new($from);

        my $diff = $from->_wday - $start_of_week;
        if ( $diff < 0 ) {
            $diff += 7;
        }

        $from = $from->add("-${diff}D");

        if ($offset) {
            $offset *= 7;

            $from = $from + "-${offset}D";
            $to = substr( $from + "7D", 0, 10 ) . ' 23:59:59';
        }
    }
    elsif ( $range eq 'month' ) {
        $from = $from->month_begin;
        $to = substr( $from->month_end, 0, 10 ) . ' 23:59:59';

        if ($offset) {
            for ( 1 .. $offset ) {
                $from = $from->add("-1D");

                $from = $from->month_begin;
                $to = substr( $from->month_end, 0, 10 ) . ' 23:59:59';
            }
        }
    }
    elsif ( $range eq 'year' ) {
        my $year = $from->year;

        if ($offset) {
            $year -= $offset;
        }

        $from = $year . '-01-01 00:00:00';
        $to   = $year . '-12-31 23:59:59';
    }

    $to = Class::Date->new($to) unless ref $to;
    $to = $now if $to > Class::Date->new($now);

    return ( "$from", "$to" );
}

1;
