package BaselinerX::Job::Controller::Calendar;
use strict;
use base 'Catalyst::Controller';
use JavaScript::Dumper;
use Baseliner::Utils;
use DateTime;
use Try::Tiny;

{
    package BaselinerX::Calendar::Window;
    use Moose;
    has 'day'        => ( is => 'rw', isa => 'Str' );
    has 'id'         => ( is => 'rw', isa => 'Str' );
    has 'ns'         => ( is => 'rw', isa => 'Str' );
    has 'bl'         => ( is => 'rw', isa => 'Str' );
    has 'type'       => ( is => 'rw', isa => 'Str' );
    has 'start_time' => ( is => 'rw', isa => 'Str' );
    has 'end_time'   => ( is => 'rw', isa => 'Str' );
    has 'active'     => ( is => 'rw', isa => 'Str' );
    no Moose;
}

# Esta constante define los tipos de herencia:
#use constant CALENDAR_UNION => 'U';
#use constant CALENDAR_INTERSEC => 'I';
#use constant CALENDAR_UNIQUE => 'E';

use constant CALENDAR_UNION    => 'HI';
use constant CALENDAR_INTERSEC => 'HE';
use constant CALENDAR_UNIQUE   => 'NO';
my %CALENDAR_TYPES = (
    CALENDAR_UNION    => 'Union',
    CALENDAR_INTERSEC => 'Interseccion',
    CALENDAR_UNIQUE   => 'Exclusion'
);


use Baseliner::Core::Baseline;
sub calendar_list_json : Path('/job/calendar_list_json') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ( $start, $limit, $query, $dir, $sort, $cnt ) = @{ $p }{ qw/start limit query dir sort/ };
    my $rs = $c->model( 'Baseliner::BaliCalendar' )->search( undef, { order_by => $sort ? "$sort $dir" : undef } );
    my @rows;

    while ( my $r = $rs->next ) {
        next if ( $query && !query_array( $query, $r->name, $r->description, $r->ns ) );
        push @rows,
            {
            id          => $r->id,
            name        => $r->name,
            description => $r->description,
            bl          => $r->bl,
            bl_desc     => Baseliner::Core::Baseline->name( $r->bl ),
            ns          => $r->ns,
            ns_desc     => $c->model( 'Namespaces' )->find_text( $r->ns )
            }
            if ( ( $cnt++ >= $start ) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    $c->stash->{ json } = { data => \@rows };
    $c->forward( 'View::JSON' );
}

sub load_calendar_types : Private {
    my ( $self, $c ) = @_;
    my @cal_types = ();
    foreach my $k ( keys %CALENDAR_TYPES ) {
        my $type = [ $k, $CALENDAR_TYPES{ $k } ];
        push @cal_types, $type;
    }
    $c->stash->{ calendar_types } = \@cal_types;
}

sub calendar_list : Path('/job/calendar_list') {
    my ( $self, $c ) = @_;

    #$c->stash->{ns_query} = { does=>['Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };
    $c->stash->{can_edit} = 
        $c->model('Permissions')->is_root( $c->username ) 
        ||
        $c->model('Permissions')
            ->user_has_action( username=>$c->username, action=>'action.job.calendar.edit', bl=>'*' );
    $c->stash->{ ns_query } = { does => [ 'Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };
    $c->forward( '/namespace/load_namespaces' );
    $c->forward( '/baseline/load_baselines' );
    $c->forward( '/calendar/load_calendar_types' );
    $c->stash->{ template } = '/comp/job_calendar_grid.mas';
}

#sub calendar_add : Path( '/job/calendar_add' ) {
#my ( $self, $c ) = @_;
#$c->stash->{template} = '/comp/job_calendar_comp.mas';
#}

sub calendar_update : Path( '/job/calendar_update' ) {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        if( $p->{action} eq 'create' ) {
            my $r1 = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $p->{ ns }, bl => $p->{ bl } } );
            if ( my $r = $r1->first ) {
                die _loc( "A calendar (%1) already exists for namespace %2 and baseline %3", $r->name, $p->{ ns }, $p->{ bl } );
            } else {
                my $row = $c->model('Baseliner::BaliCalendar')->create({
                        name        => $p->{ name },
                        description => $p->{ description },
                        ns          => $p->{ ns },
                        bl          => $p->{ bl }
                    }
                );
                if ( $p->{ copyof } ) {
                    my $copyOf = int( $p->{ copyof } );
                    $row = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $p->{ ns }, bl => $p->{ bl } } )->first;
                    my $new_id = $row->id;
                    my $rs = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id_cal => $copyOf } );

                    while ( my $r = $rs->next ) {
                        $c->model( 'Baseliner::BaliCalendarWindow' )->create(
                            {
                                start_time => $r->start_time,
                                end_time   => $r->end_time,
                                start_date => $r->start_date,
                                end_date   => $r->end_date,
                                day        => $r->day,
                                type       => $r->type,
                                active     => $r->active,
                                id_cal     => $new_id
                            }
                        );
                    }
                }
            }
        }
        elsif ( $p->{ action } eq 'delete' ) {
            my $row = $c->model( 'Baseliner::BaliCalendar' )->search( { id => $p->{ id_cal } } );
            $row->delete;
        }
        else {
            my $row = $c->model( 'Baseliner::BaliCalendar' )->search( { id => $p->{ id_cal } } )->first;
            $row->name( $p->{ name } );
            $row->description( $p->{ description } );
            $p->{ ns } and $row->ns( $p->{ ns } );
            $p->{ bl } and $row->bl( $p->{ bl } );
            $row->update;
        }
    };
    if ( $@ ) {
        _log $@;
        $c->stash->{ json } = { success => \0, msg => _loc( "Error modifying the calendar: " ) . $@ };
    }
    else {
        $c->stash->{ json } = { success => \1, msg => _loc( "Calendar '%1' modified", $p->{ name } ) };
    }
    $c->forward( 'View::JSON' );
}

sub calendar : Path( '/job/calendar' ) {
    my ( $self, $c ) = @_;
    my $id_cal = $c->stash->{ id_cal } = $c->req->params->{ id_cal };
    $c->stash->{ ns_query } = { does => [ 'Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };
    $c->forward( '/namespace/load_namespaces' );
    $c->forward( '/baseline/load_baselines' );
    $c->forward( '/calendar/load_calendar_types' );

    # load the calendar row data
    $self->init_date( $c );
    $c->stash->{ calendar } = $c->model( 'Baseliner::BaliCalendar' )->search( { id => $id_cal } )->first;
    $c->stash->{ template } = '/comp/job_calendar_comp.mas';
}

sub calendar_show : Path( '/job/calendar_show' ) {
    my ( $self, $c ) = @_;
    my $id_cal = $c->stash->{ id_cal } = $c->req->params->{ id_cal };

    # get the panel id to be able to refresh it
    $c->stash->{ panel } = $c->req->params->{ panel };

    # load the calendar row data
    $self->init_date( $c );

    $c->stash->{ calendar } = $c->model( 'Baseliner::BaliCalendar' )->search( { id => $id_cal } )->first;

    # prepare the html grid data
    $c->stash->{ grid }     = $c->forward( '/calendar/grid' );
    $c->stash->{ template } = '/comp/job_calendar.mas';
}

sub preview_calendario : Path( '/job/preview_calendar' ) {
    my ( $self, $c ) = @_;
    my $id_cal = $c->stash->{ id_cal } = $c->req->params->{ id_cal };

    $c->session->{ preview_ns } = $c->req->params->{ ns };
    $c->session->{ preview_bl } = $c->req->params->{ bl };
    $c->stash->{ preview_date } = $c->req->params->{ date };

    $c->stash->{ ns_query } = { does => [ 'Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };

    # load the calendar row data
    $self->init_date( $c );
    $c->stash->{ calendar } = $c->model( 'Baseliner::BaliCalendar' )->search( { id => $id_cal } )->first;
    $c->stash->{ template } = '/comp/preview_calendar_comp.mas';
}

sub preview_calendar_show : Path( '/job/preview_calendar_show' ) {
    my ( $self, $c ) = @_;
    my $p = $c->request->params;
    $c->session->{ preview_ns } = $c->session->{ preview_ns } || $p->{ ns };
    $c->session->{ preview_bl } = $c->session->{ preview_bl } || $p->{ bl };
    $c->stash->{ preview_date } = $c->stash->{ preview_date } || $p->{ date };

    # get the panel id to be able to refresh it
    $c->stash->{ panel } = $p->{ panel };

    # load the calendar row data
    $self->init_date( $c );

    #$c->stash->{calendar} = $c->model('Baseliner::BaliCalendar')->search({ id => $id_cal })->first;
    # prepare the html grid data
    $c->stash->{ grid }     = $c->forward( '/calendar/grid_preview' );
    $c->stash->{ template } = '/comp/preview_calendar.mas';
}

sub init_date {
    my ( $self, $c ) = @_;
    my $date_str = $c->req->params->{ date } || $c->stash->{ preview_date };
    my $dt = ( $date_str ) ? $self->parseDateTime( $date_str ) : $c->session->{ currentDate } || DateTime->now();

    $c->stash->{ fecha_date }              = $dt;
    $c->stash->{ fecha_dia }               = $dt->day();
    $c->stash->{ fecha_mes }               = $dt->month();
    $c->stash->{ fecha_anyo }              = $dt->year();
    $c->stash->{ fecha_primer_dia_semana } = $self->getFirstDateTimeOfWeek( $dt );

    $c->session->{ currentDate }           = $dt;
    $c->session->{ currentFirstDayOfWeek } = $self->getFirstDateTimeOfWeek( $dt );

}

sub addDaysToDateTime {
    my ( $self, $date, $days ) = @_;
    use Date::Calc qw(Add_Delta_Days);
    my ( $year, $month, $day ) = Add_Delta_Days( $date->year(), $date->month(), $date->day(), $days );
    my $dt = DateTime->new( year => $year, month => $month, day => $day );
    return $dt;
}

sub parseDateTime {
    my ( $self, $date_str ) = @_;
    my ( $dd, $mm, $yyyy ) = ( $date_str =~ /(\d+)\/(\d+)\/(\d+)/ );
    return DateTime->new( year => $yyyy, month => $mm, day => $dd );
}

sub parseDateTimeToDbix {
    my ( $self, $date ) = @_;
    return ( $date )
        ? ( $date->year() . '-' . sprintf( "%02d", $date->month() ) . '-' . sprintf( "%02d", $date->day() ) . ' 00:00:00' )
        : undef;
}


sub parseJSON {
    my ( $self, $date ) = @_;
    return ( $date )
        ? ( "new Date(" . $date->year() . "," . sprintf( "%02d", $date->month() - 1 ) . "," . sprintf( "%02d", $date->day() ) . ")" )
        : undef;
}

sub parseDateTimeToSlot {
    my ( $self, $date ) = @_;
    return ( $date ) ? ( $date->year() . '-' . sprintf( "%02d", $date->month() ) . '-' . sprintf( "%02d", $date->day() ) ) : undef;
}

sub parseDateTimeToForm {
    my ( $self, $date ) = @_;
    return ( $date->day() . '/' . $date->month() . '/' . $date->year() ) if ( $date );
}

sub getFirstDateTimeOfWeek {
    my ( $self, $date ) = @_;
    my $dweek = ( $date->wday() - 1 ) * -1;
    my $dt = $self->addDaysToDateTime( $date, $dweek );
    return $dt;
}


sub calendar_edit : Path( '/job/calendar_edit' ) {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{ panel } = $p->{ panel };
    my $id     = $p->{ id };
    my $id_cal = $p->{ id_cal };
    my $win    = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id => $id } )->first;
    my $pdia   = $p->{ pdia };
    my $activa = 0;

    if ( !$win && !$pdia ) {
        $c->stash->{ not_found } = 1;
    }
    else {
        my $inicio;
        my $dia;
        my $fin;
        my $tipo;
        my $date;

        if ( $pdia ) {    # new window
            $c->stash->{ create } = 1;
            $dia    = substr( $pdia, 4 );
            $inicio = $p->{ pini };
            $fin    = $p->{ pfin };
            $tipo   = "N";
        }
        else {            # existing window
            $inicio = $win->start_time;
            $fin    = $win->end_time;
            $dia    = $win->day;
            $tipo   = $win->type;
            $activa = $win->active;
            $date   = $win->start_date;
        }
        $c->stash->{ id }     = $id;
        $c->stash->{ id_cal } = $id_cal;
        $c->stash->{ dia }    = $dia;
        $c->stash->{ inicio } = $inicio;
        $c->stash->{ fin }    = $fin;
        $c->stash->{ tipo }   = $tipo;
        $c->stash->{ activa } = $activa;

        $c->stash->{ date } = $p->{ date } || $self->parseDateTimeToForm( $date );
    }
    $c->stash->{ template } = '/comp/job_calendar_edit.mas';
}

sub calendar_submit : Path('/job/calendar_submit') {
    my ( $self, $c ) = @_;
    my $p           = $c->req->params;
    my $id_cal      = $p->{ id_cal };
    my $cierra      = 0;
    my $id          = $p->{ id };
    my $cmd         = $p->{ cmd };
    my $ven_dia     = $p->{ ven_dia };
    my $ven_ini     = $p->{ ven_ini };
    my $ven_fin     = $p->{ ven_fin };
    my $ven_tipo    = $p->{ ven_tipo };
    my $date_str    = $p->{ date };
    my $currentDate = $self->parseDateTime( $date_str ) if ( $date_str );

    eval {
        my @diaList;
        if ( $ven_dia eq "L-V" ) {
            my @diaList = ( 0 .. 4 );
        }
        elsif ( $ven_dia eq "L-D" ) {
            my @diaList = ( 0 .. 6 );
        }
        else {
            push @diaList, $ven_dia;
        }
        foreach my $ven_dia ( @diaList ) {
            if ( $cmd eq "B" ) {

                #delete row
                if ( $id ) {
                    $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id => $id } )->first->delete;

                    #stmt.executeUpdate("DELETE FROM distventanas WHERE id=" + id);
                    $cierra = 1;
                }
                else {
                    die( "<H5>Error: id '$id' de ventana no encontrado.</H5>" );
                }
            }
            elsif ( $cmd eq "A" or $cmd eq "AD" ) {
                my $active = ( $cmd eq "A" );

                #InfVentana.Ventana ven=iv.getVentanaRec(ven_dia,ven_ini);
                my $ven = get_window( $id_cal, $ven_dia, $ven_ini );

                if ( ref $ven && !( $id eq $ven->{ id } ) && !( "X" eq $ven->{ tipo } ) && !( $ven_ini eq $ven->{ fin } ) && !$currentDate )
                {
                    _log "-----------VENTANA: ven: $ven id: $id tipo: "
                        . $ven->{ tipo }
                        . " ven_ini: $ven_ini ven_fin: "
                        . $ven->{ fin }
                        . " currentDate: $currentDate";

                    #Inicio esta en una ventana ya existente
                    die(      "<h5>Error: la hora de inicio de ventana ($ven_ini) se solapa con la siguiente ventana:<br>"
                            . "-----------VENTANA: ven: $ven id: $id tipo: "
                            . $ven->{ tipo }
                            . " ven_ini: $ven_ini ven_fin: "
                            . $ven->{ fin }
                            . " currentDate: $currentDate"
                            . "<li>DIA="
                            . $ven->{ dia }
                            . "<li>INICIO="
                            . $ven->{ start }
                            . "<li>FIN="
                            . $ven->{ fin }
                            . "<li>TIPO="
                            . $ven->{ tipo }
                            . " </h5>" );
                }
                else {

                    #ven=iv.getVentanaRec(ven_dia,ven_fin);
                    $ven = get_window( $id_cal, $ven_dia, $ven_ini );
                    if (   $ven
                        && !( $id      eq $ven->{ id } )
                        && !( "X"      eq $ven->{ tipo } )
                        && !( $ven_fin eq $ven->{ start } )
                        && !$currentDate )
                    {

                        #Fin esta en una ventana ya existente
                        die(      "<h5>Error: la hora de fin de ventana ($ven_fin) se solapa con la siguiente ventana: "
                                . "-----------VENTANA: ven: $ven id: $id tipo: "
                                . $ven->{ tipo }
                                . " ven_ini: $ven_ini ven_fin: "
                                . $ven->{ fin }
                                . " currentDate: $currentDate"
                                . "<li>DIA="
                                . $ven->{ dia }
                                . "<li>INICIO="
                                . $ven->{ start }
                                . "<li>FIN="
                                . $ven->{ fin }
                                . "<li>TIPO="
                                . $ven->{ tipo }
                                . " </h5>" );
                    }
                    else {
                        unless ( $id ) {    #new row
                            my $r = $c->model( 'Baseliner::BaliCalendarWindow' )->create(
                                {
                                    id_cal     => $id_cal,
                                    day        => $ven_dia,
                                    type       => $ven_tipo,
                                    active     => $active,
                                    start_time => $ven_ini,
                                    end_time   => $ven_fin,
                                    start_date => $self->parseDateTimeToDbix( $currentDate ),
                                    end_date   => $self->parseDateTimeToDbix( $currentDate )
                                }
                            );
                        }
                        else {    #existing
                            my $row = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id => $id } )->first;
                            $row->day( $ven_dia );
                            $row->type( $ven_tipo );
                            $row->start_time( $ven_ini );
                            $row->end_time( $ven_fin );
                            $row->update;
                        }

                        $c->forward( '/calendar/colindantes' );
                        $cierra = 1;
                    }
                }
            }
            elsif ( $cmd eq "C1" || $cmd eq "C0" ) {

                #Activar
                my $row = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id => $id } )->first;
                $row->active( substr( $cmd, 1 ) );
                $row->update;
                $cierra = 1;
            }
            else {
                die( "<h5>Error: Comando desconocido o incompleto.</h5>" );
            }

            last unless ( $cierra );
        }
    };
    if ( $@ ) {
        _log $@;
        $c->stash->{ json } = { success => \0, msg => _loc( "Error modifying the calendar: " ) . $@ };
    }
    else {
        $c->stash->{ json } = { success => \1, msg => _loc( "Calendar modified." ) };
    }

    $c->forward( 'View::JSON' );
}

sub calendar_delete : Path('/job/calendar_delete') {
    my ( $self, $c ) = @_;
    my $p           = $c->req->params;
    my $id_cal      = $p->{ id_cal };
    my $panel       = $p->{ panel };
    my $date_str    = $p->{ date };
    my $currentDate = $self->parseDateTime( $date_str );

    if ( $c->model( 'Baseliner::BaliCalendarWindow' )
        ->search( { id_cal => $id_cal, start_date => $self->parseDateTimeToDbix( $currentDate ) } )->delete_all )
    {
        $c->stash->{ json } = { success => \1, msg => _loc( "Calendar deleted." ) };
    }
    else {
        $c->stash->{ json } = { success => \0, msg => _loc( "Error deleting the calendar: " ) };
    }
    $c->forward( 'View::JSON' );
}

=head2 calendar_range

From a list of ns, finds all applicable ranges. 

If bl is supplied, the bl calendar has preference over all other calendars. For example:

    - /, *                      <== least precedence
    - /, DES
    - /apl/APL_ABC, *
    - /apl/APL_ABC, DES
    - /package/P1102121, *
    - /package/P1102121, DES    <== most precendence

=cut


#TODO needs to include specific date ranges as priority
use Baseliner::Core::Namespace;

sub calendar_range : Private {
    my ( $self, $c ) = @_;
    my $day = $c->stash->{ day };
    my @ns = @{ $c->stash->{ ns } || [] };
    my @range;
    #_log "CAL----VOY: " . _dump( \@ns );
    my $date = parse_date( 'dd/mm/Y', $day );
    my $week_day = $date->day_of_week() - 1;

    for my $ns ( $c->model( 'Namespaces' )->sort_ns( { asc => 1 }, @ns ) ) {
        my $ns_desc = $c->model( 'Namespaces' )->find_text( $ns );
        for my $bl ( $c->stash->{ bl } ? ( '*', $c->stash->{ bl } ) : '*' ) {
            my $bl_desc = Baseliner::Core::Baseline->name( $bl );

            #_log "CAL===>BL=$bl, NS=$ns ";
            my $rs = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => $bl } );
            while ( my $r = $rs->next ) {

                #_log "CALENDAR===========>" . $r->name . " day=$day, $date=$date, week_day=$week_day";
                my $rs2 = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id_cal => $r->id, day => $week_day } );
                while ( my $r2 = $rs2->next ) {

                    #_log "====> NS=" . $r->ns ;
                    #_log "NS=" . $r->ns . ", DATA=" . _dump $r2->get_columns;
                    if ( $r2->active ) {
                        # last range has the most precedence
                        @range = range_add( \@range, "$ns_desc ($bl_desc)", $r2->start_time, $r2->end_time, $r2->type );
                        #push @range, { start=>$r2->start_time, end=>$r2->end_time, };
                    }
                }
            }
        }
    }
    $c->stash->{ calendar_range } = \@range;
    $c->stash->{ calendar_range_expand } = [ range_expand( $date, @range ) ];
}

sub date_range : Private {
    my ( $self, $c ) = @_;
    my $start_date = $c->stash->{ start_date };
    my $end_date   = $c->stash->{ end_date };
    my @ns         = @{ $c->stash->{ ns } || [] };
    my @range_enabled;
    my @range_disabled;
    my @include;
    my %exclude;
    my @only;
    my %fechas;
    my $lastType = CALENDAR_UNION;
    use Switch;

    for my $ns ( $c->model( 'Namespaces' )->sort_ns( { asc => 1 }, @ns ) ) {
        my $ns_desc = $c->model( 'Namespaces' )->find_text( $ns );

        #Parche temporal BORRAME CUANDO SE ARREGLEN LOS NS
        $ns =~ s/_DESA|_CORR//g if ( $ns =~ /_DESA|_CORR/ );
        for my $bl ( $c->stash->{ bl } ? ( '*', $c->stash->{ bl } ) : '*' ) {
            my $bl_desc = Baseliner::Core::Baseline->name( $bl );
            _log "CAL===>BL=$bl, NS=$ns ";
            my $rs = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => $bl } );
            while ( my $r = $rs->next ) {
                my $currentDate   = $start_date;
                my $calendar_type = $r->type;
                $lastType = $calendar_type;
                while ( DateTime->compare( $currentDate, $end_date ) == -1 ) {
                    my $date_str     = $self->parseDateTimeToForm( $currentDate );
                    my $week_day     = $currentDate->day_of_week() - 1;
                    my $jsDateObject = $self->parseJSON( $currentDate );
                    my $rs2;
                    $rs2 =
                        $c->model( 'Baseliner::BaliCalendarWindow' )
                        ->search( { id_cal => $r->id, start_date => $self->parseDateTimeToDbix( $currentDate ) } );
                    $rs2 =
                        $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id_cal => $r->id, day => $week_day, start_date => undef } )
                        if ( not ref $rs2 or not $rs2->next );
                    $rs2->reset();

                    while ( my $r2 = $rs2->next ) {
                        if ( $r2->active == 1 ) {

                    #_log "------CREADO-----FECHA : " . $self->parseJSON($currentDate) . " DIA_SEMANA: $week_day ID_ENCONTRADO: " . $r2->id;
                            switch ( $calendar_type ) {
                                case ( CALENDAR_UNION ) { push @include, $jsDateObject; }
                                case ( CALENDAR_INTERSEC ) { $exclude{ $jsDateObject } = $ns; }
                                case ( CALENDAR_UNIQUE ) { push @only,    $jsDateObject; }
                                else                     { push @include, $jsDateObject; }
                            }

                            #push @range_enabled,$jsDateObject;
                        }
                        else {
                            push @range_disabled, $jsDateObject;
                        }
                    }
                    $currentDate = $self->addDaysToDateTime( $currentDate, 1 );
                }
            }
        }
    }

    $lastType = CALENDAR_INTERSEC if ( keys %exclude );
    $lastType = CALENDAR_UNIQUE   if ( scalar( @only ) > 0 );

    switch ( $lastType ) {
        case ( CALENDAR_UNIQUE ) {
            push @range_enabled, @only;
        }
        case ( CALENDAR_UNIQUE ) {
            for my $val ( @include ) {
                if ( $exclude{ $val } ne '' ) {
                    my $idx = -1;
                    foreach my $i ( 0 .. scalar( @range_disabled ) - 1 ) {
                        if ( $range_disabled[ $i ] eq $val ) {
                            $idx = $i;
                            last;
                        }
                    }
                    push @range_enabled, $val if ( $idx eq -1 );

                    #push @range_enabled, $val if(!map($val,@range_disabled));
                }
            }
        }
        else {
            push @range_enabled, keys %exclude;
            push @range_enabled, @only;
            push @range_enabled, @include;
        }
    }

    _log "----FECHAS ANTES DE PURGA ($lastType): " . join( " , ", @range_enabled );
    @range_enabled = purgeDateArray( @range_enabled, @range_disabled );
    _log "----FECHAS ANTES DE PURGA ($lastType): " . join( " , ", @range_enabled );

    $c->stash->{ range_enabled } = \@range_enabled;
}

sub date_intersec_range : Private {
    my ( $self, $c ) = @_;
    my $start_date = $c->stash->{ start_date };
    my $end_date   = $c->stash->{ end_date };
    my @ns         = @{ $c->stash->{ ns } || [] };
    my $count      = scalar @ns;
    my @range_enabled;
    my @range_disabled;
    my %valid_dates = ();

    for my $ns ( $c->model( 'Namespaces' )->sort_ns( { asc => 1 }, @ns ) ) {
        my $ns_desc = $c->model( 'Namespaces' )->find_text( $ns );
        $ns =~ s/_DESA|_CORR//g if ( $ns =~ /_DESA|_CORR/ );
        $valid_dates{ $ns } = ();
        for my $bl ( $c->stash->{ bl } ? ( '*', $c->stash->{ bl } ) : '*' ) {
            my $bl_desc = Baseliner::Core::Baseline->name( $bl );

            my $rs = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => $bl } );
            $rs = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => "*" } ) if ( not ref $rs or not $rs->next );
            $rs->reset();

            while ( my $r = $rs->next ) {
                my $currentDate = $start_date;
                while ( DateTime->compare( $currentDate, $end_date ) == -1 ) {
                    my $week_day     = $currentDate->day_of_week() - 1;
                    my $jsDateObject = $self->parseJSON( $currentDate );
                    my $rs2;
                    $rs2 =
                        $c->model( 'Baseliner::BaliCalendarWindow' )
                        ->search( { id_cal => $r->id, start_date => $self->parseDateTimeToDbix( $currentDate ) } );
                    $rs2 =
                        $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id_cal => $r->id, day => $week_day, start_date => undef } )
                        if ( not ref $rs2 or not $rs2->next );
                    $rs2->reset();
                    my $found = 0;

                    while ( my $r2 = $rs2->next ) {
                        $found = 1;
                        if ( defined( $r2->active ) && $r2->active == 1 ) {
                            push @{ $valid_dates{ $ns } }, $jsDateObject;
                            push @range_enabled, $jsDateObject;
                        }
                        else {
                            push @range_disabled, $jsDateObject;
                        }
                    }
                    push @range_disabled, $jsDateObject if ( $found eq 0 );
                    $currentDate = $self->addDaysToDateTime( $currentDate, 1 );
                }
            }
        }
    }

    # delete duplicates
    $c->stash->{ range_enabled }  = [ _unique @range_enabled ];
    $c->stash->{ range_disabled } = [ _unique @range_disabled ];
}

sub time_range_intersec : Private {
    my ( $self, $c ) = @_;
#    my $date  = $c->stash->{ date_selected };
#    my @ns    = @{ $c->stash->{ ns } || [] };
#    my $count = scalar @ns;
#    use Calendar::Slots;
#    my @range_enabled;
#    my @range_disabled;
#    my @slots_validos;
#    my %valid_slots = ();
#    my $cal         = Calendar::Slots->new;
#
#    for my $ns ( $c->model( 'Namespaces' )->sort_ns( { asc => 1 }, @ns ) ) {
#        my $ns_desc = $c->model( 'Namespaces' )->find_text( $ns );
#
#        #Parche temporal BORRAME CUANDO SE ARREGLEN LOS NS
#        $ns =~ s/_DESA|_CORR//g if ( $ns =~ /_DESA|_CORR/ );
#        for my $bl ( $c->stash->{ bl } ? ( '*', $c->stash->{ bl } ) : '*' ) {
#            my $bl_desc = Baseliner::Core::Baseline->name( $bl );
#            my $rs = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => $bl } );
#            $rs = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => "*" } ) if ( not ref $rs or not $rs->next );
#            $rs->reset();
#
#            while ( my $r = $rs->next ) {
#                my $week_day = $date->day_of_week() - 1;
#                my $rs2;
#                $rs2 =
#                    $c->model( 'Baseliner::BaliCalendarWindow' )
#                    ->search( { id_cal => $r->id, start_date => $self->parseDateTimeToDbix( $date ) } );
#                $rs2 = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id_cal => $r->id, day => $week_day, start_date => undef } )
#                    if ( not ref $rs2 or not $rs2->next );
#                $rs2->reset();
#                my $found = 0;
#
#                while ( my $r2 = $rs2->next ) {
#						my $slot = {date=>$self->parseDateTimeToSlot($date), start=>$r2->start_time , end=>$r2->end_time, name=>$r2->type};
#                    if ( $r2->active == 1 ) {
#                        push @slots_validos, $slot;
#						  }else{
#                        push @range_disabled, $slot;
#                    }
#                    push @range_disabled, $slot if ( $found eq 0 );
#
#                }
#            }
#        }
#    }
#
#    addSlots( $cal, @slots_validos );
#
#    for my $time_range ( $cal->sorted() ) {
#        my $start_time = $self->parse_time( $time_range->start );
#        my $end_time   = $self->parse_time( $time_range->end );
#        my $type       = $time_range->name;
#
#        my $displayText = $start_time . ' - ' . $end_time;    # . ' - ' . (($type eq 'N')? _loc 'Normal Window' : _loc 'Urgent Window');
#        my $valueJson = '{ start_time: "' . $start_time . '", end_time: "' . $end_time . '", type: "' . $type . '"}';
#		push @range_enabled,{start_time=>$start_time, end_time=>$end_time, type=>$type, displayText => $displayText, valueJson=>$valueJson};
#    }

    # Eric -- No me entero de nada de lo de arriba, lo hago desde cero...
    my @just_another_range_enabled = do {
      use BaselinerX::Job::CalendarUtils;
      my $day_of_week  = $c->stash->{date_selected}->{local_c}->{day_of_week} - 1;
      my @ns           = @{$c->stash->{ns} || []};
      my $bl           = $c->stash->{bl} || '*';
      # my $packagename  = $c->stash->{packagename};
      my @packagename  = @{$c->stash->{packagename}}; # Eric 27/01/2012
      # _log 'packagenames -> ' . join ', ', @packagename;
      # _log "day_of_week -> $day_of_week";
      # _log 'ns -> ' . join ', ', @ns;
      # _log "bl -> $bl";
      # my @calendar_ids = calendar_ids $packagename, $bl, @ns;
      my @calendar_ids = _unique map { calendar_ids $_, $bl, @ns } @packagename; # Eric 27/01/2012
      # _log 'calendar_ids -> [' . (join ', ', @calendar_ids) . ']';
      calendar_json merge_calendars $day_of_week, @calendar_ids;
    };

    # $c->stash->{ time_range } = \@range_enabled;
    $c->stash->{time_range} = \@just_another_range_enabled;
    #_log 'time range -> ' . Data::Dumper::Dumper \@just_another_range_enabled;
}


# sub time_range : Private {
# my ($self,$c )=@_;
# my $date = $c->stash->{date_selected};
# my @ns = @{ $c->stash->{ns} || [] };
# my @range_enabled;
# my %fechas;

# for my $ns ( $c->model('Namespaces')->sort_ns({ asc=>1 }, @ns ) ) {
# my $ns_desc = $c->model('Namespaces')->find_text( $ns );
# for my $bl (  $c->stash->{bl}? ( '*', $c->stash->{bl} ) : '*' ) {
# my $bl_desc = Baseliner::Core::Baseline->name( $bl );
#_log "CAL===>BL=$bl, NS=$ns ";
# my $rs = $c->model('Baseliner::BaliCalendar')->search({ ns=>$ns, bl=>$bl });
# while( my $r = $rs->next ) {
# my $week_day = $date ->day_of_week() - 1;
# my $rs2;
# $rs2 = $c->model('Baseliner::BaliCalendarWindow')->search({ id_cal=>$r->id, start_date=>$self->parseDateTimeToDbix($date)});
# $rs2 = $c->model('Baseliner::BaliCalendarWindow')->search({ id_cal=>$r->id, day=>$week_day , start_date=>undef}) if(!$rs2 || !$rs2->next);
# $rs2->reset();
# while( my $r2 = $rs2->next ) {
# if( $r2->active == 1 ) {
# _log "------CREADO NS: $ns --FECHA : " . $self->parseDateTimeToDbix($date) . " DIA_SEMANA: $week_day ID_ENCONTRADO: " . $r2->id_cal;
# my $displayText = $r2->start_time . ' - ' . $r2->end_time . ' - ' . (($r2->type eq 'N')? _loc 'Normal Window' : _loc 'Urgent Window');
# my $valueJson = '{ start_time: "' . $r2->start_time . '", end_time: "' . $r2->end_time . '", type: "' . $r2->type . '"}';
# push @range_enabled,{start_time=>$r2->start_time, end_time=>$r2->end_time, type=>$r2->type, displayText => $displayText, valueJson=>$valueJson};
# }
# }
# }
# }
# }
# $c->stash->{time_range} = \@range_enabled;
# }

sub parse_time : Private {
    my ( $self, $t ) = @_;
    my $time = sprintf( "%02d", substr( $t, 0, 2 ) ) . ":" . sprintf( "%02d", substr( $t, 2, 3 ) );
    return $time;
}

sub time_range : Private {
    my ( $self, $c ) = @_;
    my $date = $c->stash->{ date_selected };
    my @ns = @{ $c->stash->{ ns } || [] };
    use Calendar::Slots;
    use Switch;
    my @range_enabled;
    my @range_disabled;
    my @include;
    my @excludes;
    my %exclude;
    my @only;
    my $lastType = CALENDAR_UNION;
    my %fechas;
    my $cal = Calendar::Slots->new;
    _log ">>>>>> time_range - sort_ns...";
    for my $ns ( $c->model( 'Namespaces' )->sort_ns( { asc => 1 }, @ns ) ) {
        my $ns_desc = $c->model( 'Namespaces' )->find_text( $ns );
        #Parche temporal BORRAME CUANDO SE ARREGLEN LOS NS
        $ns =~ s/_DESA|_CORR//g if ( $ns =~ /_DESA|_CORR/ );
        for my $bl ( $c->stash->{ bl } ? ( '*', $c->stash->{ bl } ) : '*' ) {
            my $bl_desc = Baseliner::Core::Baseline->name( $bl );
            _log "CAL===>BL=$bl, NS=$ns ";
            my $rs = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => $bl } );
            while ( my $r = $rs->next ) {
                my $week_day = $date->day_of_week() - 1;
                my $rs2;
                $rs2 =
                    $c->model( 'Baseliner::BaliCalendarWindow' )
                    ->search( { id_cal => $r->id, start_date => $self->parseDateTimeToDbix( $date ) } );
                $rs2 = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id_cal => $r->id, day => $week_day, start_date => undef } )
                    if ( not ref $rs2 or not $rs2->next );
                $rs2->reset();
                while ( my $r2 = $rs2->next ) {
                        my $slot = {date=>$self->parseDateTimeToSlot($date), start=>$r2->start_time , end=>$r2->end_time, name=>$r2->type};
                    my $calendar_type = $r->type;
                    $lastType = $calendar_type;
                    if ( $r2->active == 1 ) {
                        _log "------CREADO-----FECHA : "
                            . $self->parseDateTimeToSlot( $date )
                            . " DIA_SEMANA: $week_day ID_ENCONTRADO: "
                            . $r2->id;

                       #$cal->slot( date=>$self->parseDateTimeToSlot($date), start=>$r2->start_time , end=>$r2->end_time, name=>$r2->type );
                        switch ( $calendar_type ) {
                            case ( CALENDAR_UNION ) { push @include, $slot; }
                            case ( CALENDAR_INTERSEC ) { $exclude{ $slot->{ date } } = $ns; push @excludes, $slot; }
                            case ( CALENDAR_UNIQUE ) { push @only,    $slot; }
                            else                     { push @include, $slot; }
                        }
                    }
                    else {
                        push @range_disabled, $slot;
                    }
                }
            }
        }
    }

    $lastType = CALENDAR_INTERSEC if ( keys %exclude );
    $lastType = CALENDAR_UNIQUE   if ( scalar( @only ) > 0 );
    my @finalDates = ();

    switch ( $lastType ) {
        case ( CALENDAR_UNIQUE ) {
            #addSlots($cal, @only);
            @finalDates = @only;
        }
        case ( CALENDAR_INTERSEC ) {
            for my $val ( @include ) {
                if ( $exclude{ $val->{ date } } ne '' ) {
                    my $idx = -1;
                    foreach my $i ( 0 .. scalar( @range_disabled ) - 1 ) {
                        if ( $range_disabled[ $i ] eq $val ) {
                            $idx = $i;
                            last;
                        }
                    }
                    push @finalDates, $val;
                    #addSlots($cal, ($val)) if($idx eq -1);
                }
            }
        }
        else {
            @finalDates = ( @excludes, @only, @include );
            #addSlots($cal, @excludes);
            #addSlots($cal, @only);
            #addSlots($cal, @include);
        }
    }

    @finalDates = purgeSlotArray( @finalDates, @range_disabled );

    addSlots( $cal, @finalDates );

    for my $time_range ( $cal->sorted() ) {
        my $start_time = $self->parse_time( $time_range->start );
        my $end_time   = $self->parse_time( $time_range->end );
        my $type       = $time_range->name;

        my $displayText = $start_time . ' - ' . $end_time . ' - ' . ( ( $type eq 'N' ) ? _loc 'Normal Window' : _loc 'Urgent Window' );
        my $valueJson = '{ start_time: "' . $start_time . '", end_time: "' . $end_time . '", type: "' . $type . '"}';
        push @range_enabled,
            { start_time => $start_time, end_time => $end_time, type => $type, displayText => $displayText, valueJson => $valueJson };
    }

    $c->stash->{ time_range } = \@range_enabled;
}

sub purgeDateArray {
    my ( @dates, @disabled ) = @_;
    my @finalDates = ();
    my $found      = 0;
    foreach my $date ( @dates ) {
        $found = 0;
        foreach my $newDate ( @finalDates ) {
            if ( $date eq $newDate ) {
                $found = 1;
                last;
            }
        }
        if ( $found == 0 ) {
            foreach my $disable ( @disabled ) {
                if ( $date eq $disable ) {
                    $found = 1;
                    last;
                }
            }
        }
        push @finalDates, $date if ( $found eq 0 );
    }
    return @finalDates;
}

sub purgeSlotArray {
    my ( @slots, @disabled ) = shift;
    my @finalArray = ();
    my $found      = 0;
    foreach my $slot ( @slots ) {
        $found = 0;
        foreach my $newSlot ( @finalArray ) {
            if ( $newSlot ne undef ) {
                if( ($slot->{date} eq $newSlot->{date}) and 
                            ($slot->{start} eq $newSlot->{start})  and 
                            ($slot->{end} eq $newSlot->{end}) and 
                            ($slot->{name} eq $newSlot->{name}) ){
                    $found = 1;
                    last;
                }
            }
        }
        if ( $found == 0 ) {
            foreach my $disable ( @disabled ) {
                if ( $disable ne undef ) {
                    if( ($slot->{date} eq $disable->{date}) and 
                                ($slot->{start} eq $disable->{start})  and 
                                ($slot->{end} eq $disable->{end}) and 
                                ($slot->{name} eq $disable->{name}) ){
                        $found = 1;
                        last;
                    }
                }
            }
        }
        push @finalArray, $slot if ( $found == 0 );
    }
    return @finalArray;
}

sub addSlots {
    my ( $cal, @slots ) = @_;
    foreach my $slot ( @slots ) {
        $cal->slot( date => $slot->{ date }, start => $slot->{ start }, end => $slot->{ end }, name => $slot->{ name } );
    }
}


=head2 range_add

Adds a new range into its place. 

=cut
sub range_add {
    my ( $r, $name, $start, $end, $type ) = @_;
    my @range;
    my $found;
    for my $r ( @{ $r || [] } ) {
        my @new_range = range_in( $r->{ name }, $r->{ start }, $r->{ end }, $r->{ type }, $name, $start, $end, $type );
        if ( @new_range ) {
            $found = 1;
            push @range, @new_range;
        }
        else {
            push @range, $r;
        }
    }
    unless ( $found ) {
        push @range, { name => $name, start => $start, end => $end, type => $type };
    }
    return @range;
}

=head2 range_in

The second range (more specific) has priority over the first range. 

One type has no precedence over another. If types are the same, ranges are merged. Else, ranges are split case by case..

=cut
sub range_in {
    my ( $n1, $s1, $e1, $t1, $n2, $s2, $e2, $t2 ) = map { s/://; $_ } @_;
    my @ret;
    #_log "================CHEQUEO RANGO: $s1,$e1,$s2,$e2";
    return if ( ( $s1 < $s2 ) && ( $e1 < $s2 ) );
    return if ( ( $s1 > $e2 ) && ( $e1 > $e2 ) );
    if ( $t1 eq $t2 ) {    ## types match, merge ranges
        push @ret, { name => $n2, start => ( $s1 < $s2 ? $s1 : $s2 ), end => ( $e1 > $e2 ? $e1 : $e2 ), type => $t1 };
    }
    else {                 ## types are different, split ranges
        if ( ( $s1 < $s2 ) && ( $e1 < $e2 ) ) {    ##  s1 s2 e1 e2
            push @ret, { name => $n1, start => $s1, end => $s2, type => $t1 };
            push @ret, { name => $n2, start => $s2, end => $e2, type => $t2 };
        }
        elsif ( ( $s1 > $s2 ) && ( $e1 > $e2 ) ) {    ##  s2 s1 e2 e1
            push @ret, { name => $n1, start => $e2, end => $e1, type => $t1 };
            push @ret, { name => $n2, start => $s2, end => $e2, type => $t2 };
        }
        elsif ( ( $s1 > $s2 ) && ( $e1 < $e2 ) ) {    ##  s1 s2 e2 e1
            push @ret, { name => $n2, start => $s2, end => $e2, type => $t2 };
        }
        elsif ( ( $s1 < $s2 ) && ( $e1 > $e2 ) ) {    ##  s1 s2 e2 e1
            push @ret, { name => $n1, start => $s1, end => $s2, type => $t1 };
            push @ret, { name => $n2, start => $s2, end => $e2, type => $t2 };
            push @ret, { name => $n1, start => $e2, end => $e1, type => $t1 };
        }
    }

    #_log "=============SALIDA: " . _dump \@ret;
    return @ret;
}

sub to_num { ( my $n = shift ) =~ s/://g; return $n }

sub range_get {
    my ( $time, @range ) = @_;
    for my $r ( @range ) {
        return $r
            if ( to_num( $time ) >= to_num( $r->{ start } ) && to_num( $time ) < to_num( $r->{ end } ) );
    }
}
use DateTime;
sub range_expand {
    my $date  = shift;
    my @range = @_;
    my @ret;
    my $inc      = 1;                                                              # minute increment  TODO put this in inf
    my $today    = DateTime->today( time_zone => _tz );
    my $is_today = DateTime->compare( $date->truncate( to => 'day' ), $today );    # zero means it's today
    my $now      = DateTime->now( time_zone => _tz );
    $now->subtract( minutes => 1 );                                                ## so it starts immediately
         #_log "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TODAY=$is_today ,".$date->truncate( to=>'day').",".DateTime->today;
    foreach my $hh ( 0 .. 23 ) {
        for ( my $mm = 0 ; $mm < 60 ; $mm += $inc ) {
            my $dt = new DateTime( time_zone=>_tz, hour=>$hh, minute=>$mm, year=>$date->year, month=>$date->month, day=>$date->day );
            #_log "!!!!! NOW=$now, DT=$dt";
            next if ( $is_today == 0 && DateTime->compare( $now, $dt ) > 0 );
            #_log "#####   OK";
            # check if it's in range
            my $time = sprintf( "%02d:%02d", $hh, $mm );
            my $range = range_get( $time, @range );
            if ( ref $range ) {
                push @ret,
                    {
                    'time'    => $time,
                    name      => $range->{ name },
                    full_name => "$time ($range->{type})",
                    type      => $range->{ type },
                    available => 1
                    };
            }
            else {

                # just ignore closed ranges for now
                #push @ret, { 'time'=>$time, name=>_loc('Closed'), type=>'C', available=>0 };
            }
        }
    }
    return @ret;
}

=head2 grid

Calculates the HTML calendar weekly grid.

=cut
sub grid : Private {
    my ( $self, $c ) = @_;
    my $id_cal      = $c->stash->{ id_cal };
    my $date        = $c->stash->{ fecha_date };
    my $grid        = {};
    my $currentDate = $c->stash->{ fecha_primer_dia_semana };
    foreach my $dd ( 0 .. 6 ) {
        # $grid->{ $dd } = get_all_windows( $id_cal, $dd, $currentDate );
        # Eric -- 27/01/2012 
        # We have to fix the bug of the first window starting at zero and the
        # consecutive one getting the wrong start_date, which meses the
        # calendar up.
        # Get the normal data.
        my $aref = get_all_windows($id_cal, $dd, $currentDate);
        # Sort by start_time and end_time, to make sure that windows don't overlap.
        my @ll = sort { $a->{start_time} gt $b->{start_time} && $a->{end_time} gt $b->{end_time} } @{$aref};
        # Start at index 1, we don't have to check the first item.
        for (my $i = 1 ; $i < scalar @ll ; $i++) {
          # Sometimes, usually when the first window starts at zero, the next
          # no-distribution window starts at 00:00 instead of the end time of the
          # first window.
          if ($ll[$i - 1]->{start_time} eq $ll[$i]->{start_time}) {
            # In this case the window is totally wrong. I don't know which
            # causes this, but it serves no purpose.
            delete $ll[$i];
          }
        }
        # Get rid of empty hashrefs.
        $grid->{$dd} = [grep {scalar keys %{$_}} @ll];
        # End
        $currentDate = $self->addDaysToDateTime( $currentDate, 1 );
    }
    return $grid;
}

sub grid_preview : Private {
    my ( $self, $c ) = @_;
    my $ns          = $c->session->{ preview_ns };
    my $bl          = $c->session->{ preview_bl };
    my $currentDate = $c->stash->{ fecha_primer_dia_semana };
    $c->session->{ preview_ns } = undef;
    $c->session->{ preview_bl } = undef;
    my $grid = {};
    foreach my $dd ( 0 .. 6 ) {
        $grid->{ $dd } = get_all_windows_preview( $self, $ns, $bl, $dd, $currentDate );
        $currentDate = $self->addDaysToDateTime( $currentDate, 1 );
    }
    return $grid;
}

sub get_window {
    my ( $id_cal, $day, $hour, $date ) = @_;
    my $rs;

    $rs = Baseliner->model('Baseliner::BaliCalendarWindow')->search({ id_cal=>$id_cal, day=>$day, start_date=>parseDateTimeToDbix(undef,$date) }) if($date);    
    $rs = Baseliner->model('Baseliner::BaliCalendarWindow')->search({ id_cal=>$id_cal, day=>$day, start_date=>undef }) if(!$rs || !$rs->next);

    $rs->reset();
    while ( my $win = $rs->next ) {
        if ( inside_window( $win->start_time, $win->end_time, $hour ) ) {
            return {
                type       => $win->type,
                active     => $win->active,
                id         => $win->id,
                day        => $win->day,
                start_time => $win->start_time,
                end_time   => $win->end_time,
                start_date => $win->start_date,
                end_date   => $win->end_date,
            };
        }
    }
    return;
}

sub event_dates : Path('/calendar/event_dates') {
    my ( $self, $c ) = @_;
    my $p      = $c->req->params;
    my $id_cal = $p->{ id_cal };

    my $rs =
        Baseliner->model( 'Baseliner::BaliCalendarWindow' )
        ->search( { id_cal => $id_cal, start_date => { '<>', undef } }, { order_by => 'start_date' } );
    my @events;

    while ( my $r = $rs->next ) {
        push @events, $self->parseJSON( $r->start_date );
    }

    $c->stash->{ json } = { success => \1, data => join( ',', @events ) };

    $c->forward( 'View::JSON' );
}

sub event_nopase_dates : Path('/calendar/event_nopase_dates') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my @ns = split( ",", $p->{ ns } );

    my $month_days = 31;
    my $week_days  = 7;
    my $date       = $p->{ date };
    try {
        my $start_date = BaselinerX::Job::Controller::Calendar->parseDateTime( $date );
        $start_date = BaselinerX::Job::Controller::Calendar->addDaysToDateTime( $start_date, -$month_days );

        #$c->stash->{start_date} = BaselinerX::Job::Controller::Calendar->parseDateTime($date);
        $c->stash->{ start_date } = $start_date;
        #my $add_days = ($month_days - $c->stash->{start_date}->day() ) + $month_days + 7;
        my $add_days = ( $month_days * 5 ) + ( $week_days * 2 );
        $c->stash->{ end_date } = BaselinerX::Job::Controller::Calendar->addDaysToDateTime( $c->stash->{ start_date }, $add_days );
        $c->stash->{ bl }       = $p->{ bl };
        $c->stash->{ ns }       = \@ns;
        $c->forward( '/calendar/date_intersec_range' );
        # _log _dump $c->stash->{calendar_range_expand} ;
        $c->stash->{ json } = { success => \1, data => join( ",", @{ $c->stash->{ range_disabled } } ) };
    }
    catch {
        my $error = shift;
        $c->stash->{ json } = { success => \0, data => $error };
    };
    _log _dump $c->stash->{ json };
    $c->forward( 'View::JSON' );
}

sub get_all_windows {
    use Calendar::Slots;
    my ( $id_cal, $day, $date ) = @_;
    my $unique = 0;

    my $rs;
    my @windows;
    $rs =
        Baseliner->model( 'Baseliner::BaliCalendarWindow' )
        ->search( { id_cal => $id_cal, day => $day, start_date => parseDateTimeToDbix( undef, $date ) }, { order_by => 'start_time' } )
        if ( $date );
    $rs =
        Baseliner->model( 'Baseliner::BaliCalendarWindow' )
        ->search( { id_cal => $id_cal, day => $day, start_date => undef }, { order_by => 'start_time' } )
        if ( not ref $rs or not $rs->next );

    $rs->reset();
    while ( my $win = $rs->next ) {
            push @windows, {  
            type       => $win->type,
            active     => $win->active,
            id         => $win->id,
            day        => $day,
            start_time => $win->start_time,
            end_time   => $win->end_time,
            start_date => $win->start_date,
            end_date   => $win->end_date,
            };
        $unique = 1 if ( $win->start_time eq '00:00' and $win->end_time eq '24:00' );
    }

    my @new_windows;
    my $inserted_00  = 0;
    my $last_ventana = undef;

    foreach my $ventana ( @windows ) {
        if (    not inside_window( $ventana->{ start_time }, $ventana->{ end_time }, '00:00' )
            and $ventana->{ start_time } ne '00:00'
            and $inserted_00 == 0 )
        {
            push @new_windows,
                {
                type       => 'X',
                id         => undef,
                active     => 0,
                day        => $day,
                start_time => '00:00',
                end_time   => $ventana->{ start_time },
                start_date => $ventana->{ start_date },
                end_date   => $ventana->{ end_date },
                };
            $inserted_00 = 1;
        }
        if ( ref $last_ventana ) {
            if ( $last_ventana->{ end_time } lt $ventana->{ start_time } ) {
                push @new_windows, {  
                    type       => 'X',
                    id         => undef,
                    active     => 0,
                    day        => $day,
                    start_time => $last_ventana->{ end_time },
                    end_time   => $ventana->{ start_time },
                    start_date => $ventana->{ start_date },
                    end_date   => $ventana->{ end_date },
                    };
            }
        }
        $last_ventana = $ventana;
    }

    if(not inside_window($last_ventana->{start_time}, $last_ventana->{end_time}, '24:00') and $last_ventana->{end_time} ne '24:00' and not $unique){
            push @new_windows, {  
            type       => 'X',
            id         => undef,
            active     => 0,
            day        => $day,
            start_time => ( $last_ventana->{ end_time } ) ? $last_ventana->{ end_time } : '00:00',
            end_time   => '24:00',
            start_date => $last_ventana->{ start_date },
            end_date   => $last_ventana->{ end_date },
            };
    }

    push( @windows, @new_windows );
    my @sorted = sort { time_to_number( $a->{ start_time } ) <=> time_to_number( $b->{ start_time } ) } @windows;

    return \@sorted;
}

sub get_all_windows_preview {
    my ( $self, $ns, $bl, $day, $date ) = @_;
    my @nss = split( ",", $ns );
    my @id_calendar;
    my $unique = 0;
    my $rs;
    my %status;
    my @windows;
    _log "----------------------Previsualizando ventanas para $ns y $bl";
    foreach my $ns_cal(@nss){
        $rs = Baseliner->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns_cal, bl => $bl } )->first;
        push @id_calendar, $rs->id if ( $rs );
    }

    my $cal_count   = scalar( @id_calendar );
    my $total_count = 0;

    use Calendar::Slots;
    my $cal = Calendar::Slots->new;
    foreach my $id_cal ( @id_calendar ) {
        $rs =
            Baseliner->model( 'Baseliner::BaliCalendarWindow' )
            ->search( { id_cal => $id_cal, day => $day, start_date => parseDateTimeToDbix( undef, $date ) }, { order_by => 'start_time' } )
            if ( $date );
        $rs =
            Baseliner->model( 'Baseliner::BaliCalendarWindow' )
            ->search( { id_cal => $id_cal, day => $day, start_date => undef }, { order_by => 'start_time' } )
            if ( not ref $rs or not $rs->next );

        $rs->reset();
        my $found = 0;
        while ( my $win = $rs->next ) {
            $found = 1 if ( $win->active );
            $cal->slot(
                date  => $self->parseDateTimeToSlot( $date ),
                start => $win->start_time,
                end   => $win->end_time,
                name  => defined( $win->active ) ? $win->active : 0
            );
            $status{ $win->start_time } = $win->active;
        }
        $total_count++ if ( $found eq 1 );
    }

    if ( $total_count ne $cal_count ) {
        my @unique_window;
        push @unique_window,{  
            type       => 'N',
            active     => 0,
            id         => 0,
            day        => $day,
            start_time => '00:00',
            end_time   => '24:00',
            };
        return \@unique_window;
    }
    else {
        for my $time_range ( $cal->sorted() ) {
            my $start_time = $self->parse_time( $time_range->start );
            my $end_time   = $self->parse_time( $time_range->end );
            my $type       = $time_range->name;
            push @windows, {  
                type       => $type,
                active     => $status{ $start_time },
                day        => $day,
                start_time => $start_time,
                end_time   => $end_time,
                start_date => $date,
                end_date   => $date,
                };
            $unique = 1 if ( $start_time eq '00:00' and $end_time eq '24:00' );
        }
    }

    my @new_windows;
    my $inserted_00  = 0;
    my $last_ventana = undef;

    foreach my $ventana ( @windows ) {
        if (    not inside_window( $ventana->{ start_time }, $ventana->{ end_time }, '00:00' )
            and $ventana->{ start_time } ne '00:00'
            and $inserted_00 == 0 )
        {
            push @new_windows,
                {
                type       => 'X',
                id         => undef,
                active     => 0,
                day        => $day,
                start_time => '00:00',
                end_time   => $ventana->{ start_time },
                start_date => $ventana->{ start_date },
                end_date   => $ventana->{ end_date },
                };
            $inserted_00 = 1;
        }
        if ( ref $last_ventana ) {
            if ( $last_ventana->{ end_time } < $ventana->{ start_time } ) {
                push @new_windows,
                    {
                    type       => 'X',
                    id         => undef,
                    active     => 0,
                    day        => $day,
                    start_time => $last_ventana->{ end_time },
                    end_time   => $ventana->{ start_time },
                    start_date => $ventana->{ start_date },
                    end_date   => $ventana->{ end_date },
                    };
            }
        }
        $last_ventana = $ventana;
    }

    if (    not inside_window( $last_ventana->{ start_time }, $last_ventana->{ end_time }, '24:00' )
        and $last_ventana->{ end_time } ne '24:00'
        and not $unique )
    {
        push @new_windows,
            {
            type       => 'X',
            id         => undef,
            active     => 0,
            day        => $day,
            start_time => ( $last_ventana->{ end_time } ) ? $last_ventana->{ end_time } : '00:00',
            end_time   => '24:00',
            start_date => $last_ventana->{ start_date },
            end_date   => $last_ventana->{ end_date },
            };
    }

    push( @windows, @new_windows );
    my @sorted = sort { time_to_number( $a->{ start_time } ) <=> time_to_number( $b->{ start_time } ) } @windows;

    return \@sorted;
}

sub time_to_number {
    my $time = shift;
    hour_to_num( $time );
    return int( $time );
}

sub colindantes : Private {
    my ( $self, $c ) = @_;
    # check for windows touching my bottom
    my $rs = $c->model( 'Baseliner::BaliCalendarWindow' )->search( undef );
    while ( my $row = $rs->next ) {
#my $rs2 = $c->model('balicalendar')->search({ -or => { end_time=>$row->start_time, start_time=>$row->end_time }, type=>$row->type, day=>$row->day });
        my $rs2 = $c->model('Baseliner::BaliCalendarWindow')->search({ start_time=>$row->end_time, type=>$row->type, day=>$row->day });
        while ( my $row2 = $rs2->next ) {
            $row->end_time( $row2->end_time );
            $row->update;
            $row2->delete;
        }
    }
    # check for windows touching my head
    my $rs2 = $c->model( 'Baseliner::BaliCalendarWindow' )->search( undef );
    while ( my $row = $rs2->next ) {
        my $rs3 = $c->model('Baseliner::BaliCalendarWindow')->search({ end_time=>$row->start_time, type=>$row->type, day=>$row->day });
        while ( my $row3 = $rs3->next ) {
            $row->start_time( $row3->start_time );
            $row->update;
            $row3->delete;
        }
    }
}

sub hour_to_num {
    $_ =~ s/://g for ( @_ );
}

sub inside_window {
    my ( $start, $end, $hour ) = @_;
    hour_to_num( $start, $end, $hour );
    if ( $start && $end && $hour ) {
        return ( $hour >= $start && $hour < $end );
    } else {
        return 0;
    }
}

1;

