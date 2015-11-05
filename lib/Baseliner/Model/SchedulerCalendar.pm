package Baseliner::Model::SchedulerCalendar;
use Moose;

use Class::Date;
use List::Util qw(first);

sub has_time_passed {
    my $self = shift;
    my ($date_raw) = @_;

    my $date = Class::Date->new($date_raw);

    return $date <= $self->now;
}

sub calculate_next_exec {
    my $self = shift;
    my ( $last_date_raw, %options ) = @_;

    my $frequency = $options{frequency} || '1D';

    my $last_schedule = Class::Date->new($last_date_raw);

    my $now = $self->now;

    my $next_exec = $last_schedule + $frequency;

    if ( $next_exec < $now ) {
        $next_exec = $now + $frequency;
    }

    if ( $options{workdays} ) {
        $next_exec = $self->_next_workday($next_exec);
    }

    return $next_exec;
}

sub now {
    my $self = shift;

    my ( $Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST ) = localtime(time);
    $Year  += 1900;
    $Month += 1;

    return Class::Date->new( [ $Year, $Month, $Day, $Hour, $Minute ] );
}

sub _next_workday {
    my $self = shift;
    my ($date) = @_;

    while ( !$self->_is_workday($date) ) {
        $date = $date + "1D";
    }

    return $date;
}

sub _is_workday {
    my $self = shift;
    my ($date) = @_;

    my @workdays = ( 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday' );

    return !!first { $date->day_of_weekname eq $_ } @workdays;
}

1;
