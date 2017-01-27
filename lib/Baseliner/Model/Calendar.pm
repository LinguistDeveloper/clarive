package Baseliner::Model::Calendar;
use Moose;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Model' }

our $DEFAULT_SEQ = 100;

sub delete_multi {
    my $self = shift;
    my (%params) = @_;

    my $ids = $params{ids};

    mdb->calendar->remove( { id => mdb->in($ids) } );
    mdb->calendar_window->remove( { id_cal => mdb->in($ids) } );

    return 1;
}

sub check_dates {
    my ($self, $date, $bl, @ns) = @_;

    my @rel_cals = mdb->calendar->find(
        {
            ns=> { '$in' => [ @ns, '/', 'Global', undef ] },
            bl=> { '$in' => [ $bl, '*'] }
        })->all;
    my @ns_cals = map { $_->{ns} } @rel_cals;
    my $hours = @ns_cals
            ? $self->merge_calendars( ns=>mdb->in(@ns_cals), bl=>$bl, date=>$date )
            : {};

    my $tz = _tz();
    my @hour_store = ();

    for my $hour_key ( sort keys %$hours ) {
        my $hour = $hours->{$hour_key};

        next if $hour->{type} =~ /X|B/;

        my $server_date = Class::Date->new( $date->ymd . ' ' .  $hour->{hour}, $tz );

        push @hour_store, [
            $hour->{hour},
            $hour->{name},
            $hour->{type},
            $server_date->strftime('%Y-%m-%d %k:%M %z')
        ];
    }

    return \@hour_store, @rel_cals;
}

sub merge_calendars {
    my ($self,%p) = @_;

    my $bl = $p{bl};
    my $now = Class::Date->new( _dt() );
    my $date = $p{date} || $now;
    $date = Class::Date->new( $date ) if ref $date ne 'Class::Date' ;

    my $start_hour = $now->ymd eq $date->ymd ? sprintf("%02d%02d", $now->hour , $now->minute) : '';

    my $where = { active => mdb->true };
    $where->{bl} = ['*'];
    $where->{ns} = $p{ns} if $p{ns};
    push $where->{bl} , $p{bl} if $p{bl};
    $where->{bl} = mdb->in( $where->{bl} );

    my @cals = mdb->calendar->find($where)
        ->sort({ seq=>1 })
        ->sort({ day => 1 })
        ->sort({ start_time => 1 })->all;

    my @slots_cal;
    for my $cal (@cals) {
        my $id_cal = $cal->{id};
        my @win_cals = mdb->joins(
            calendar => { id=>$id_cal },
            id => id_cal =>
            calendar_window => {} );

        my $slots = Calendar::Slots->new();
        for my $win ( _array @win_cals ) {
            my $name = "$cal->{name} ($win->{type})==>" . ( $win->{day} + 1 );
            if ( $win->{start_date} ) {
                my $d = Class::Date->new( $win->{start_date} );
                $slots->slot(
                    date  => substr( $d->string, 0, 10 ),
                    start => $win->{start_time},
                    end   => $win->{end_time},
                    name  => $name,
                    data => { cal => $cal->{name}, type => $win->{type} }
                );
            } else {
                $slots->slot(
                    weekday => $win->{day} + 1,
                    start   => $win->{start_time},
                    end     => $win->{end_time},
                    name    => $name,
                    data    => { cal => $cal->{name}, type => $win->{type}, seq => $cal->{seq} }
                );
            }
        }
        push @slots_cal, $slots;
    }

    my $date_w = $date->wday -1;
    $date_w <= 0  and $date_w += 7;
    my $date_s = $date->strftime('%Y%m%d');
    my %list;
    _debug "TOD=$date, W=$date_w, S=$date_s, START=$start_hour";

    for my $s ( map { $_->sorted } @slots_cal ) {
       next if $s->type eq 'date' && $s->when ne $date_s;
       next if $s->type eq 'weekday' && $s->when ne $date_w;

       for( $s->start .. $s->end-1 ) {
         my $time = sprintf('%04d',$_);
         next if $s->data->{type} eq 'B';
         next if $start_hour && $time < $start_hour;
         next if substr( $time, 2,2) > 59 ;
         next if $time == 2400;
         # now choose which slot to use for this minute
         #   giving higher precedence to the ASCII value of TYPE letter
         #     X > U > N - using ord for ascii values
         $s->data->{seq} //= $DEFAULT_SEQ;
         if( ! exists $list{$time}
             || ord $s->data->{type} > ord $list{ $time }->{type}
             || $s->data->{seq} > $list{ $time }->{seq}
             ) {
            $list{$time} = {
                type => $s->data->{type},
                cal  => $s->data->{cal},
                seq  => $s->data->{seq},
                hour => sprintf( '%s:%s', substr( $time, 0, 2 ), substr( $time, 2, 2 ) ),
                name => sprintf( "%s (%s)", $s->data->{cal}, $s->data->{type} ),
                start => $s->start,
                end   => $s->end,
            };
         }
       }
    }
    return \%list;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
