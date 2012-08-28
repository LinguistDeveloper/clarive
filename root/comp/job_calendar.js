<%init>
    
my $grid = $c->stash->{grid};
my $panel = $c->stash->{panel};
my $id_cal = $c->stash->{id_cal};
my $currentDate = $c->stash->{fecha_primer_dia_semana};

my $loc = DateTime::Locale->load( $c->language );
my $day_wide = $loc->day_format_wide;
my $firstday = Class::Date->new( $c->stash->{fecha_primer_dia_semana} );

</%init>
<script language="text/javascript">

Ext.onReady(function(){
        
    Ext.ns('Baseliner');
    Baseliner.editSlot =  function(dia,ini,fin, date) {
        var comp = Baseliner.showAjaxComp( '/job/calendar_edit', {  panel: '<% $panel %>', id_cal: '<% $id_cal %>', pdia: 'day-'+dia, pini: ini, pfin: fin, date: date } );
    }

    Baseliner.editId = function(id, date) {
        var comp = Baseliner.showAjaxComp( '/job/calendar_edit', { id: id, id_cal: '<% $id_cal %>', panel: '<% $panel %>', date: date} );
    }
    
    Baseliner.createRange = function(id, pdia, date) {
        var comp = Baseliner.showAjaxComp( '/job/calendar_edit', { id: id,  pdia: 'day-'+pdia, id_cal: '<% $id_cal %>', panel: '<% $panel %>', date: date, pini: "00:00", pfin: "24:00"} );
    }	
    
    Baseliner.deleteRange = function(id, pdia, date) {				
        Ext.Msg.show({
           title:'¿Eliminar ventana de pase para '+date+'?',
           msg: 'Pulse Sí para eliminar la ventana de pase seleccionada.<br>Recuerde que solo se eliminaran las franjas horarias para el día ' + date + '.',
           buttons: Ext.Msg.YESNO,
           fn: function(res){
               if(res == 'yes'){
                   Ext.Ajax.request({
                        url: '/job/calendar_delete',
                        params:{id: id, id_cal:'<% $id_cal %>',  panel: '<% $panel %>', pdia: pdia, date: date},
                        success : function(conn, response, options) {
                             Ext.get('<% $panel %>').load({url:'/job/calendar_show', params:{panel:'<% $panel %>', id_cal: '<% $id_cal %>', date: date}});
                             Ext.MessageBox.show({  
                                 title: 'Ventana eliminada',  
                                 msg: 'La ventana para el ' + date + ', ha sido eliminada.',  
                                 buttons: Ext.MessageBox.OK,  
                                 icon: Ext.MessageBox.INFO  
                             });  
                        },
                        failure: function (conn, response, options) {  
                             Ext.MessageBox.show({  
                                 title: 'Error al eliminar ventana',  
                                 msg: 'No se ha podido eliminar la ventana de pase para el ' + date + '.',  
                                 buttons: Ext.MessageBox.OK,  
                                 icon: Ext.MessageBox.ERROR  
                             });  
                         }						
                    });
                }
           },
           animEl: 'elId'
        });
    }

});
</script>
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
    my %has_date;

    my @cals = DB->BaliCalendar->search(
        { 'me.id' => $id_cal },
        {
          prefetch=>'windows',
          order_by=>[
              { -asc=>'seq' },
              { -asc=>'windows.day' },
              { -asc=>'windows.start_time' }
          ]
        }
    )->hashref->all;
    my $slots = Calendar::Slots->new();
    # create base (undefined) calendar
    $slots->slot( weekday=>$_, start=>'00:00', end=>'24:00', name=>'B', data=>{ type=>'B' } )
        for 1 .. 7;
    if( my $cal = shift @cals ) {
       for my $win ( _array( $cal->{windows} ) ) {
           #my $name = "$cal->{name} ($win->{type})==>" .( $win->{day}+1 );
           my $name = $win->{type};
           my $when;
           if( $win->{start_date} ) {
               my $d = Class::Date->new( $win->{start_date} );
               $when = substr($d->string,0,10);
               $slots->slot( date=>$when, start =>$win->{start_time}, end =>$win->{end_time}, name =>$name, data=>$win );
           } else {
               $when = $win->{day}+1;
               $slots->slot( weekday=>$when, start =>$win->{start_time}, end =>$win->{end_time}, name =>$name, data=>$win );
           }
           $win->{aaa} = $when . ' => ' . $win->{start_time} . ' - ' . $win->{end_time} ;
       }
    }
#die substr( "$firstday", 0, 10 );
    $slots = $slots->week_of( substr( "$firstday", 0, 10 ) );
     #_debug _dump $slots;
     _debug _dump [ $slots->sorted ];

    my $to_minute = sub { 
        my $t = shift;
        $t=~s/://g;
        ( substr( $t, 0, 2) * 60 ) + substr($t,2,2);
    };
    my $tab_hour = 0;
    my $tab_min = 0;
    foreach my $row ( 1 .. 48 ) {
        my $tab_now = sprintf('%02d%02d', $tab_hour, $tab_min );
        print qq{<TR time="$tab_now">};
        foreach my $day ( 1 .. 7 ) {
            my $day0 = $day - 1 ;
            my $date = substr( $firstday + (( $day0 ).'D'), 0, 10);
            my $slot = $slots->find( date=>$date, time=>$tab_now );
            # _error $slot;
            #_debug " $day - $tab_now " . _dump $slot;
            if( $slot && $slot->start eq $tab_now ) {
                my $start = $slot->start;
                my $end   = $slot->end;
                my $type   = $slot->name;
                my $id = $slot->data->{id};
                #  my $fecha = '01/01/2012'; 

                my $span = ( $to_minute->($slot->end) - $to_minute->($slot->start) ) / 30;
                my $class = "slot_$type";
                $class = $class . '_off' unless $slot->data->{active};
                print qq[<TD style='cursor:hand' rowspan=$span
                    onmouseover='javascript:this.className="cal_slot $class slot_hover";'
                    onmouseout='javascript:this.className="cal_slot $class";'
                    align="center" class="cal_slot $class" ];
                if( $type eq 'B' ) {
                    print qq[ onclick='javascript: Baseliner.editSlot("$day0","$start","$end","")'>];
                } else {							
                    print qq[ onclick='javascript: Baseliner.editId("$id")'>];
                }	
                print qq[ $start - $end</TD>];	
                #print sprintf q{<td style="font-size:8px" rowspan=%s>%s - %s (%s)</td>}, $span, $slot->start, $slot->end, $span;
            } else  {
                #print qq{ <td></td> };
                #die "Nooo" unless $slot;
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

        print qq{ <TD width='100'> };
        if($has_date{$dd}){
            print qq{	<a href="#" class="x-link-button-remove" onclick="javascript: Baseliner.deleteRange('0','$dd','$day/$month/$year')">borrar ventana<br>para el $day/$month/$year</a>};
        }else{
            print qq{	<a href="#" class="x-link-button" style="font-size: 10px;" onclick="javascript: Baseliner.createRange('0','$dd','$day/$month/$year')">crear ventana<br>$day/$month/$year</a>};		
        }
        print qq{ </TD>};
    }
</%perl>
        </TR>	
    </TABLE>

</FORM>
<TABLE border="0" width="100%" cellpadding="2">
<TR>
        <TD><B>Leyenda Ventanas de pase: </B></TD>
        <TD width=1>&nbsp;</TD>
        <TD class="slot_N" width=20 height=20>&nbsp;</TD>
        <TD>Pase</TD>
        <TD width=10>&nbsp;</TD>
        <TD class="slot_U" width=20>&nbsp;</TD>

        <!-- Eric :: Ahora mismo está un poco raro... Se intuye que no pase significa que no se -->
        <!--         puede distribuir, por lo que rompe totalmente con la idea de un pase       -->
        <!--         urgente. Lo mejor sería dejar no pase como vacío y urgente en color rojo.  -->
        <!-- <TD>No pase/Urgente</TD> -->

        <TD>Urgente</TD>
        <TD width=10>&nbsp;</TD>
        <TD class="slot_B" width=20>&nbsp;</TD>
        <!-- <TD>Vacio/Urgente</TD> -->
        <TD>Vacío</TD>
        <TD>&nbsp;</TD>
        <TD>&nbsp;</TD>
        <TD>&nbsp;</TD>
</TR>
<TR>
        <TD><B>Leyenda calendario: </B></TD>
        <TD width=10>&nbsp;</TD>
        <TD style="border:solid 1px #000000" class="x-datepickerplus-pase-leyenda">&nbsp;</TD>
        <TD>Ventana semanal</TD>
        <TD width=10>&nbsp;</TD>
        <TD class="x-datepickerplus-eventdates-leyenda">&nbsp;</TD>
        <TD>Ventana de fecha</TD>
        <TD width=10>&nbsp;</TD>
        <TD style="border:solid 1px #000000;" class="x-datepickerplus-weekends-leyenda" width=15>&nbsp;</TD>
        <TD>Fin de semana</TD>
        <TD width=10>&nbsp;</TD>
        <TD class="x-datepickerplus-nationalholidays-leyenda" width=15>&nbsp;</TD>
        <TD>Fiestas nacionales</TD>
</TR></TABLE>

</DIV>


