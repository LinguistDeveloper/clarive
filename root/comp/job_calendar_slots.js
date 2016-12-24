<%init>
    
my $panel = $c->stash->{panel};
my $id_cal = $c->stash->{id_cal};
my $slots = $c->stash->{slots};

my $firstday = Class::Date->new( $c->stash->{monday} );

my $table = $c->build_helper('CalendarSlots')->slots;

</%init>

<DIV class='job-calendar' ID="calendarDiv">

<FORM name="infForm" action="" method="GET">
    <TABLE class='job-calendar-slots-table'>
        <TR>
% foreach my $header (@{ $table->{headers} }) {
            <TH><% $header %></TH>
% }
        </TR>
<%perl>
    foreach my $row ( @{ $table->{rows} } ) {
        print qq{<TR time="$row->{time}">};

        foreach my $col ( @{ $row->{columns} } ) {
            next unless %$col;

            my $rowspan = $col->{rowspan} // '';
            my $type    = $col->{type}    || 'B';

            my $class = "slot_$type";
            $class = $class . '_off' unless $col->{active};

            print qq[<TD style='cursor:hand' rowspan=$rowspan
                onmouseover='javascript:this.className="cal_slot $class slot_hover";'
                onmouseout='javascript:this.className="cal_slot $class";'
                align="center" class="cal_slot $class" ];

            if ( $col->{type} eq 'B' ) {
                print qq[ onclick='javascript: Baseliner.editSlot("$panel", "$id_cal", "$col->{day}","$col->{start}","$col->{end}","")'>];
            }
            else {
                print qq[ onclick='javascript: Baseliner.editId("$panel", "$id_cal", "$col->{id}", "$col->{date}")'>];
            }

            my $date_icon =
              $col->{date}
              ? ' <img height=12 onmouseover="$(this).tooltip()" src="/static/images/icons/calendar.svg" />'
              : '';

            print qq[ $col->{duration}$date_icon</TD>];
        }

        print qq{</TR>};
    }
</%perl>
</TABLE>
<TABLE cellpadding="2" id="days_week">
        <TR>
<%perl> 
    foreach my $dd ( 0..6 ) {
        my $date = $firstday + ($dd.'D');
        my ($year, $month, $day) = ($date->year,$date->month,$date->day);
        my $msg = _loc( 'new slot') . "<br>$day/$month/$year";
        print qq{ <TD width='100'> };
        print qq{    <a href="javascript: Baseliner.createRange('$panel','$id_cal','0','$dd','$day/$month/$year')" class="x-link-button" style="font-size: 10px;">$msg</a>};        
        print qq{ </TD>};
    }
</%perl>
        </TR>   

</TABLE>
</FORM>
<TABLE   cellpadding="2"  id="caption_key">
<TR>
        <TD class="slot_N" height=20>&nbsp;</TD>
        <TD class="slots-caption" ><% _loc("Normal") %></TD>

        <TD class="slot_U">&nbsp;</TD>
        <TD class="slots-caption"><% _loc("Urgent") %></TD>

        <TD class="slot_X">&nbsp;</TD>
        <TD class="slots-caption"><% _loc("No Job") %></TD>

        <TD class="slot_B">&nbsp;</TD>
        <TD class="slots-caption"><% _loc("Empty") %></TD>

        <TD class="slot_N_off" height=20>&nbsp;</TD>
        <TD class="slots-caption-big"><% _loc("Normal") . " <i>(" . _loc("No Job") .")</i>" %></TD>

        <TD  class="slot_U_off">&nbsp;</TD>
        <TD class="slots-caption-big"><% _loc("Urgent") . " <i>(" . _loc("No Job") .")</i>" %></TD
</TR>
</TABLE>
</DIV>