<%init>
    
my $panel = $c->stash->{panel};
my $id_cal = $c->stash->{id_cal};
my $slots = $c->stash->{slots};

my $loc = DateTime::Locale->load( $c->language );
my $day_wide = $loc->day_format_wide;
my $firstday = Class::Date->new( $c->stash->{monday} );

</%init>
<DIV class='job-calendar' ID="calendarDiv">

<FORM name="infForm" action="" method="GET">
    <TABLE border=0 style="height: 300px">
        <TR>
% foreach my $dd ( @{ $day_wide || [] } ) {
            <TH width='100' align=center><% $dd %></TH>
% }
        </TR>
        <TR>
<%perl>

    my $to_minute = sub { 
        my $t = shift;
        $t=~s/://g;
        ( substr( $t, 0, 2) * 60 ) + substr($t,2,2);
    };
    my $to_time = sub { substr( $_[0], 0, 2 ) . ':' . substr( $_[0], 2, 2 ) };
    my $to_dmy = sub {  my @x= $_[0] =~ /^(\d{4})(\d{2})(\d{2})/; join '/', $x[2],$x[1],$x[0] };
    my $tab_hour = 0;
    my $tab_min = 0;

    # now lets cache start dates, and avoid using $slots->find()
    my %by_wk;
    my %by_start;
    #my %has_date;
    for( $slots->all ) {
        my $wk = $_->weekday;
        #$has_date{ $wk } = 1 if $_->type eq 'date';
        push @{ $by_wk{ $wk } },  $_ ;
    }
    foreach my $day ( 1 .. 7 ) {
        $by_start{ $day }{ $_->{start} } = $_ for _array( $by_wk{ $day } );
        #my $slot = $slots->find( date=>$date, time=>$tab_now );  # TODO slow...
    }
    foreach my $row ( 1 .. 48 ) {
        my $tab_now = sprintf('%02d%02d', $tab_hour, $tab_min );
        print qq{<TR time="$tab_now">};
        foreach my $day ( 1 .. 7 ) {
            my $day0 = $day - 1 ;
            my $date = substr( $firstday + (( $day0 ).'D'), 0, 10);

            my $slot = $by_start{ $day }{ $tab_now };  # get slot from cache
            #  uncomment the following line if cache is not working
            # my $slot = $slots->find( date=>$date, time=>$tab_now );  # slow!

            if( $slot && $slot->start eq $tab_now ) {
                my $start = $slot->start;
                my $end   = $slot->end;
                my $type   = $slot->name;
                my $id = $slot->data->{id};
                #  my $fecha = '01/01/2012'; 
                my $startt = $to_time->( $start ); 
                my $endt = $to_time->( $end ); 
                my $datet = $to_dmy->( $slot->when ) if $slot->type eq 'date';

                my $span = ( $to_minute->($slot->end) - $to_minute->($slot->start) ) / 30;
                my $class = "slot_$type";
                $class = $class . '_off' unless $slot->data->{active};
                print qq[<TD style='cursor:hand' rowspan=$span
                    onmouseover='javascript:this.className="cal_slot $class slot_hover";'
                    onmouseout='javascript:this.className="cal_slot $class";'
                    align="center" class="cal_slot $class" ];
                if( $type eq 'B' ) {
                    print qq[ onclick='javascript: Baseliner.editSlot("$panel", "$id_cal", "$day0","$startt","$endt","")'>];
                } else {							
                    print qq[ onclick='javascript: Baseliner.editId("$panel", "$id_cal", "$id", "$datet")'>];
                }	
                my $date_icon = ' <img height=12 onmouseover="$(this).tooltip()" src="/static/images/icons/calendar.png" />' if $slot->type eq 'date';

                print qq[ $startt - $endt$date_icon</TD>];	
                #print sprintf q{<td style="font-size:8px" rowspan=%s>%s - %s (%s)</td>}, $span, $slot->start, $slot->end, $span;
            }
        }
        print qq{</TR>};
        $tab_min+=30;
        if( $tab_min > 59 ) {
            $tab_min=0; 
            $tab_hour++;
        }
    }

</%perl>
        </TR>
        <TR>
<%perl>	
    foreach my $dd ( 0..6 ) {
        my $date = $firstday + ($dd.'D');
        my ($year, $month, $day) = ($date->year,$date->month,$date->day);
        my $msg = _loc( 'new window') . "<br>$day/$month/$year";
        print qq{ <TD width='100'> };
        print qq{	<a href="javascript: Baseliner.createRange('$panel','$id_cal','0','$dd','$day/$month/$year')" class="x-link-button" style="font-size: 10px;">$msg</a>};		
        print qq{ </TD>};
    }
</%perl>
        </TR>	
    </TABLE>

</FORM>
<TABLE border="0" width="100%" cellpadding="2">
<TR>
        <TD width=20 class="slot_N" height=20>&nbsp;</TD>
        <TD width=100><% _loc("Normal") %></TD>

        <TD width=10>&nbsp;</TD>

        <TD width=20 class="slot_U">&nbsp;</TD>
        <TD width=100><% _loc("Urgent") %></TD>

        <TD width=10>&nbsp;</TD>

        <TD width=20 class="slot_X">&nbsp;</TD>
        <TD width=100><% _loc("No Job") %></TD>

        <TD width=10>&nbsp;</TD>

        <TD width=20 class="slot_B">&nbsp;</TD>
        <TD ><% _loc("Empty") %></TD>

</TR>
<TR>
        <TD width=20 class="slot_N_off" height=20>&nbsp;</TD>
        <TD width=100><% _loc("Normal") . " <i>(" . _loc("No Job") .")</i>" %></TD>

        <TD width=10>&nbsp;</TD>

        <TD width=20 class="slot_U_off">&nbsp;</TD>
        <TD width=100><% _loc("Urgent") . " <i>(" . _loc("No Job") .")</i>" %></TD>

        <TD width=10>&nbsp;</TD>

</TR>
</TABLE>
</DIV>
