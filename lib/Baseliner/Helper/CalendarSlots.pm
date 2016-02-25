package Baseliner::Helper::CalendarSlots;
use Moose;

use DateTime::Locale;
use Class::Date;
use Baseliner::Utils qw(_array);

has c => qw(is ro weak_ref 1);

sub slots {
    my $self = shift;

    my $c = $self->c;

    my $slots = $c->stash->{slots};

    my $loc      = DateTime::Locale->load( $c->language );
    my $firstday = Class::Date->new( $c->stash->{monday} );

    my @headers = @{ $loc->day_format_wide };

    my $to_minute = sub {
        my $t = shift;
        $t =~ s/://g;
        ( substr( $t, 0, 2 ) * 60 ) + substr( $t, 2, 2 );
    };
    my $to_time = sub { substr( $_[0], 0, 2 ) . ':' . substr( $_[0], 2, 2 ) };
    my $to_dmy = sub { my @x = $_[0] =~ /^(\d{4})(\d{2})(\d{2})/; join '/', $x[2], $x[1], $x[0] };
    my $tab_hour = 0;
    my $tab_min  = 0;

    my %by_wk;
    my %by_start;

    for ( $slots->all ) {
        my $wk = $_->weekday;

        push @{ $by_wk{$wk} }, $_;
    }
    foreach my $day ( 1 .. 7 ) {
        $by_start{$day}{ $_->{start} } = $_ for _array( $by_wk{$day} );
    }

    my @rows;

    # Every 30 minutes
    foreach ( 1 .. 48 ) {
        my $row = {};

        my $tab_now = sprintf( '%02d%02d', $tab_hour, $tab_min );

        $row->{time} = $tab_now;

        # Every weekday
        foreach my $day ( 1 .. 7 ) {
            my $col = {};

            my $day0 = $day - 1;
            my $date = substr( $firstday + ( ($day0) . 'D' ), 0, 10 );

            my $slot = $by_start{$day}->{$tab_now};

            if ( $slot && $slot->start eq $tab_now ) {
                my $start = $slot->start;
                my $end   = $slot->end;
                my $type  = $slot->name;
                my $id    = $slot->data->{id};

                #  my $fecha = '01/01/2012';
                my $startt = $to_time->($start);
                my $endt   = $to_time->($end);
                my $datet  = $slot->type eq 'date' ? $to_dmy->( $slot->when ) : '';

                my $span = ( $to_minute->( $slot->end ) - $to_minute->( $slot->start ) ) / 30;

                $col->{rowspan} = $span;
                $col->{type}    = $type;
                $col->{active}  = $slot->data->{active};

                my $class = "slot_$type";
                $class = $class . '_off' unless $slot->data->{active};

                $col->{id}  = $id;
                $col->{day} = $day - 1;

                $col->{start} = $startt;
                $col->{end}   = $endt;
                $col->{date}  = $datet;

                $col->{duration} = "$startt - $endt";
            }

            push @{ $row->{columns} }, $col;
        }

        $tab_min += 30;

        if ( $tab_min > 59 ) {
            $tab_min = 0;
            $tab_hour++;
        }

        push @rows, $row;
    }

    return { headers => \@headers, rows => \@rows };
}

1;
