#:tip_venya:
package BaselinerX::Job::CalendarUtils;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Exporter::Tidy default => 
  [qw/build_calendar print_calendar calendar_data next_hour make_empty_calendar
      convert_hour build_week_calendar print_week_calendar calendar_ids_from_job
      merge_calendars calendar_json calendar_ids ceiling floor
      current_distribution_type/];
use List::Util qw/reduce/;
use DateTime;

=head1 METHODS

=cut

sub colors { G => 'Gray', U => 'Red', N => 'Green' }

sub colors_to_code { G => 0, N => 1, U => 2 }

sub code_to_colors { 0 => 'G', 1 => 'N', 2 => 'U' }

sub str_to_hour { # Str -> Str
  my ($hour) = @_;
  my ($hh, $mm) = ($1, $2) if $hour =~ m/(..)(..)/;
  "${hh}:${mm}";
}

=head2 next_hour

Returns the next hour. Works on blocks of 30 minutes.

    next_hour 1200;
    #=> 1230
  
    next_hour 1230;
    #=> 1300
    
=cut
sub next_hour { # Str -> Str
  my ($hour) = @_;
  $hour  = "${hour}0" if length $hour < 4;
  my $hh = substr $hour, 0, 2;
  my $mm = substr $hour, 2, 2;
  return "${hh}30" if $mm eq '00';
  my $mock = $hh + 1;
  $hh < 9 ? "0${mock}00" : "${mock}00";
}

=head2 make_empty_calendar

Initializes a calendar with the following structure:
  
    [[0000, 'G'],
     [0030, 'G'],
     [0100, 'G'],
     [0130, 'G'],
     ...
     [2330, 'G'],
     [2400, 'G']]
     
=cut
sub make_empty_calendar { # -> Array
  sub make_empty_calendar_tail {
    my ($hour, $color, $limit, @hours) = @_;
    my $next_hour = next_hour $hour;
    return @hours if $hour > $limit;
    make_empty_calendar_tail($next_hour, $color, $limit, 
                             @hours, ["$hour", $color]);
  }
  make_empty_calendar_tail '0000', 'G', '2400';
}

=head2 print_calendar

Prints the calendar.

=cut
sub print_calendar {
  my @registers = @_;
  my %colors = colors();
  for my $entry (@registers) {
    say "$entry->[0]  $colors{$entry->[1]}";
  }
}


=head2 calendar_data 

Gets raw calendar data from the database, given the day (starting by 0) and
the calendar_id.

=cut
sub calendar_data { # Int * Int -> Array[HashRef]
  my ($day, $id_cal) = @_;
  my @data = do {
    my $model = Baseliner->model('Baseliner::BaliCalendarWindow');
    my $where = {day => $day, id_cal => $id_cal};
    my $args  = {select   => [qw/start_time end_time type active/], 
                 order_by => 'start_time'};
    my $rs    = $model->search($where, $args);
    rs_hashref($rs);
    $rs->all;
  };
  @data;
}

=head2 convert_hour

Converts the hour to hh:mm to hhmm.

=cut
sub convert_hour { # Str -> Str
  my ($hour) = @_;
  $hour =~ s/://g;
  "$hour";
}

sub time_struct {
  map { convert_hour $_ } map { $_->{start_time}, $_->{end_time} } @_;
}

sub get_urgente {
  time_struct grep($_->{active} && $_->{type} eq 'U', @_);
}

sub get_ventana {
  time_struct grep($_->{active} && $_->{type} eq 'N', @_);
}

sub get_nopase {
  time_struct grep(!$_->{active}, @_);
}

sub split_into_half_hours {
  my ($begin, $end) = @_;
  my $current_hour = $begin;
  my @ret;
  while ($current_hour <= $end) {
    push @ret, $current_hour;
    $current_hour = next_hour $current_hour;
  }
  @ret;
}

sub split_into_half_hours_range {
  my @regs = @_;
  my @ret;
  push @ret, split_into_half_hours((shift @regs),
                                   (shift @regs)) while @regs;
  @ret;
}

sub in_range_p {
  my ($hour, @regs) = @_;
  for my $reg (split_into_half_hours_range @regs) {
    return 1 if $reg eq $hour;
  }
  return;
}

sub print_nopase_p {
  my ($current_hour, @calendar) = @_;
  in_range_p $current_hour, get_nopase @calendar;
}

sub print_urgente_p {
  my ($current_hour, @calendar) = @_;
  in_range_p $current_hour, get_urgente @calendar;
}

sub print_ventana_p {
  my ($current_hour, @calendar) = @_;
  in_range_p $current_hour, get_ventana @calendar;
}

=head2 build_calendar

Given the day and calendar id, returns a calendar with the same structure 
as B<make_empty_calendar> but modified with the actual data from the
database.

=cut
sub build_calendar {
  my ($day, $id_cal) = @_;
  my @current_calendar = calendar_data $day, $id_cal;
  my @calendar  = make_empty_calendar();  # The calendar to modify and return.
  for my $entry (@calendar) {
    my $hour = $entry->[0];
    do { $entry->[1] = 'G'; next } if print_nopase_p  $hour, @current_calendar;
    do { $entry->[1] = 'U'; next } if print_urgente_p $hour, @current_calendar;
    do { $entry->[1] = 'N'; next } if print_ventana_p $hour, @current_calendar;
  }
  @calendar;
}


=head2 build_week_calendar

The same as B<build_calendar> but for the whole week.

=cut
sub build_week_calendar {
  my ($id_cal) = @_;
  my @data;
  push @data, [build_calendar $_, $id_cal] for 0..6;
  @data;
}

sub print_week_calendar {
  my @calendar = build_week_calendar $_[0];
  say "      L M X J V S D\n";
  for my $i (0 .. (scalar @{$calendar[0]} - 1)) {
    my $drawp = 'If I am the first iteration print a newline!';
    my $it    = 0;
    for my $day (@calendar) {
      my ($hour, $color) = ($day->[$i][0], $day->[$i][1]);
      print "$hour  " if !!$drawp;
      print "$color ";
      print "\n" if $it == 6;
      $drawp = '' if !!$drawp;
      $it++;
    }
  }
}

sub cons_natures { # Str * Array[Str] -> Array[Str]
  my ($packagename, @ns) = @_;
  my @natures = natures_from_packagenames $packagename;
  push @ns, "harvest.nature/$_" for @natures;
  @ns;
}

=head2 calendar_ids_from_job

Given the packagename, the BL and the NS of a job. Rebuilds the NS with the
natures added in and returns any calendar ids matching with the job's BL and
complete NS. It also returns the priority for the given calendar id, ranging
from 1 to 3. Where 3 is CAM, 2 is NATURE and 1 GENERIC. The array is sorted
from bigger to smaller priority so normally you would just take the first
value.
  
  calendar_ids_from_job 'SCT.N-000019 DISTRIBUCION COMPLETA ORACLE', 
                        'TEST', 
                        qw{/ application/SCT};
  #=> [{id => 33, priority => 3},
  #    {id => 30, priority => 1}];

=cut
sub calendar_ids_from_job { # Str * Str * Array[Str] -> Array[HashRef]
  my ($packagename, $bl, @_ns) = @_;
  my @ns = cons_natures $packagename, @_ns;
  my $model = Baseliner->model('Baseliner::BaliCalendar');
  sort { $a->{priority} < $b->{priority} }
  grep { $_ } 
  map {
    my $id = do {
      my $rs = $model->search({bl => $bl, ns => $_});
      rs_hashref($rs);
      $rs->all ? $rs->next->{id} : q{};
    };
    my $priority = $_ =~ /application\// ? 3
                 : $_ =~ /\w+\.nature\// ? 2
                 : $_ eq '/'             ? 1
                 : 0
                 ;
    {priority => $priority, id => $id} if $priority && $id;
  } @ns;
}

sub calendar_ids { # Str * Str * Array[Str] -> Array[Int]
  my ($packagename, $bl, @_ns) = @_;
  my @ns = cons_natures $packagename, @_ns;
  my $model = Baseliner->model('Baseliner::BaliCalendar');
  grep { $_ } map {
  my $rs = $model->search({bl => $bl, ns => $_});
  rs_hashref($rs);
  $rs->all ? $rs->next->{id} : q{};
  } @ns;
}

=head2 merge_calendars

Given the day of the week (starting from zero) and an array of calendar ids,
merge the resulting calendars into a virtual one, where the distribution type
will be the AND of the three different kinds of products (No distribution,
normal distribution and urgent distribution), having urgent distribution a
bigger priority over normal distribution.

The result is a normal calendar.

  merge_calendars 1, (30, 33);
  #=> [['0000', 'G'],
  #    ['0030', 'G'],
  #    ['0100', 'N'],
  #    ...
  #   ]

=cut
sub merge_calendars { # Int * Array[Int] -> Array[Str, Int]
  my ($day_of_week, @calendar_ids) = @_;
  my @calendars = map { [map { $_->[1] = $_->[1] eq 'G' ? 0 : $_->[1] eq 'N' ? 1 : 2; $_ } @{$_}] }
                  map { [build_calendar $day_of_week, $_] } @calendar_ids;
  my @virtual_calendar;
  for (my $i = 0 ; $i < scalar @{$calendars[0]} ; $i++) {
    # Check whether we can distribute in this hour by making an AND of the type
    # of distribution window.
    # | 0 -> No distribution     (G)
    # | 1 -> Normal distribution (N)
    # | n -> Urgent distribution (U)
    my $product = reduce { $a * $b } map { $_->[$i]->[1] } @calendars;
    my $hour    = $calendars[0]->[$i]->[0];  # This will always be like this.
    my %code_to_colors = code_to_colors();
    push @virtual_calendar, [$hour, $code_to_colors{$product}];
  }
  @virtual_calendar;
}

=head2 calendar_json

Given a calendar, returns an array of hashrefs with the JSON data needed when
checking for dates and times at new job creation.

  calendar_json merge_calendars 1, (30, 33);
  #=> [{'displayText' => '08:00 - 19:00',
  #     'end_time'    => '19:00',
  #     'start_time'  => '08:00',
  #     'type'        => 'U',
  #     'valueJson'   => '{start_time: "08:00", end_time: "19:00", type: "U"}'}]
        
=cut
sub calendar_json { # Array[Int] -> HashRef
  # Ignore blank entries and pick distributions exclusively.
  my @calendar = grep { $_->[1] ne 'G' } @_;
  my @calendar_format = do {
    my $first_hour;
    my $past_hour;
    my $past_type;
    my @data;
    for (my $i = 0 ; $i < scalar @calendar ; $i++) {
      my $entry = $calendar[$i];
      my $hour  = $entry->[0];
      my $type  = $entry->[1];
      # First iteration.
      unless ($first_hour) {
        $first_hour = $hour;
        $past_hour  = $hour;
        $past_type  = $type;
        next;
      }
      # Are we in the same type?
      if ($type eq $past_type && makes_sense_p($past_hour, $hour)) {  
        $past_hour = $hour;
      }
      # Otherwise... we saw changes! Record
      else {
        push @data, {start_time => $first_hour, end_time => $past_hour, type => $past_type};
        $first_hour = $hour;
        $past_hour  = $hour;
        $past_type  = $type;
      }
      # Last iteration
      if ($i == $#calendar) {  
        push @data, {start_time => $first_hour, end_time => $hour, type => $type};
      }
    }
    @data;
  };
  map { 
    {displayText => "$_->{start_time} - $_->{end_time}",
     end_time    => $_->{end_time},
     start_time  => $_->{start_time},
     type        => $_->{type},
     valueJson   => '{start_time: "' . $_->{start_time}
                  . '", end_time: "' . $_->{end_time}
                  . '", type: "'     . $_->{type} . '"}'}
  }
  map { 
    $_->{start_time} = str_to_hour $_->{start_time};
    $_->{end_time}   = str_to_hour $_->{end_time};
    $_ ;
  } @calendar_format;
}

=head2 ceiling

Returns the upper limit of a window, ignoring no distributions.
  
=cut 
sub ceiling { # Int * Int * Str * Str -> Str
  my ($day, $calendar_id, $_init_hour, $_end_hour) = @_;
  my $init_hour = convert_hour $_init_hour;
  my $end_hour  = convert_hour $_end_hour;
  my @data = grep { $_->{start_time} >= $end_hour }
             sort { $a->{start_time} > $b->{start_time} }
             grep { $_->{end_time} ne $end_hour && $_->{start_time} ne $init_hour }
             map {
               {end_time   => (convert_hour $_->{end_time}),
                start_time => (convert_hour $_->{start_time})}
             } calendar_data $day, $calendar_id;
  my $ceiling = $data[0]->{start_time} || '2400'; # Default value.
  str_to_hour $ceiling;
}

=head2 floor

Returns the bottom limit of a window, ignoring no distributions.

=cut
sub floor { # Int * Int * Str * Str -> Str
  my ($day, $calendar_id, $_init_hour, $_end_hour) = @_;
  my $init_hour = convert_hour $_init_hour;
  my $end_hour  = convert_hour $_end_hour;
  my @data = grep { $_->{end_time} <= $init_hour }
             sort { $a->{start_time} < $b->{start_time} }
             grep { $_->{end_time} ne $end_hour && $_->{start_time} ne $init_hour }
             map { 
               {end_time   => (convert_hour $_->{end_time}),
                start_time => (convert_hour $_->{start_time})}
             } calendar_data $day, $calendar_id;
  my $floor = $data[0]->{end_time} || '0000'; # Default value.
  str_to_hour $floor;
}

sub split_hh_mm {
  my ($hour) = @_;
  ($1, $2) if $hour =~ m/(..)(..)/;
}


=head2 makes_sense_p

Checks if the current hour and the past hour are still in the same window.

=cut
sub makes_sense_p {
  my ($past_hour, $curr_hour) = @_;
  my ($past_hh, $past_mm) = split_hh_mm $past_hour;
  my ($curr_hh, $curr_mm) = split_hh_mm $curr_hour;
  # The minutes shall never be the same.
  return 0 if $past_mm eq $curr_mm;
  # The difference in hours shall never be more than one.
  return 0 if $curr_hh - $past_hh > 1;
  # Otherwise it all makes sense.
  1;
}

sub current_distribution_type {
  my @calendar = @_;
  my $date = DateTime->now;
  my $hhmm = '' . ($date->hour + 1) . $date->minute;
  for my $aref (@calendar) {
  	my $hour = $aref->[0];
  	return $aref->[1];                 # Return the type of distribution.
  }
  die "Something went wrong!";
}

1;
