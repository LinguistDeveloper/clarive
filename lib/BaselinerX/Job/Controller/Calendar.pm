package BaselinerX::Job::Controller::Calendar;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Controller' };
use JavaScript::Dumper;
use Baseliner::Core::Baseline;
use Baseliner::Utils;
use Calendar::Slots 0.15;
use DateTime;
use Try::Tiny;

our $DEFAULT_SEQ = 100;

register 'menu.job.calendar' => {
    label    => _loc('Job Calendars'),
    url_comp => '/job/calendar_list',
    title    => _loc('Job Calendars'),
    actions  => ['action.job.calendar.view'],
    icon     => '/static/images/chromium/history_favicon.png'
};
register 'action.job.calendar.view' => { name => 'View Job Calendar' };
register 'action.job.calendar.edit' => { name => 'Edit Job Calendar' };

register 'config.job.calendar' => {
    metadata=> [
        { id=>'name', label => 'Calendar', type=>'text', width=>200 },
        { id=>'ns', label => 'Namespace', type=>'text', width=>300 },
        { id=>'ns_desc', label => 'Namespace Description', type=>'text', width=>300 },
    ],
};

sub calendar : Path( '/job/calendar' ) {
    my ( $self, $c ) = @_;
    my $id_cal = $c->stash->{ id_cal } = $c->req->params->{ id_cal };
    $c->stash->{ ns_query } = { does => [ 'Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application' ] };
    $c->stash->{ list_calendar } = 1;
    $c->forward( '/namespace/load_namespaces' );
    $c->forward( '/baseline/load_baselines' );
    $c->forward('/permissions/load_user_actions');

    # load the calendar row data
    $self->init_date( $c );
    $c->stash->{ calendar } = $c->model( 'Baseliner::BaliCalendar' )->search( { id => $id_cal } )->first;
    $c->stash->{ template } = '/comp/job_calendar_editor.js';
}

# slot editor
sub calendar_slots : Path( '/job/calendar_slots' ) {
    my ( $self, $c ) = @_;
    my $id_cal = $c->stash->{ id_cal } = $c->req->params->{ id_cal };

    # get the panel id to be able to refresh it
    $c->stash->{ panel } = $c->req->params->{ panel };
#    $c->forward('/permissions/load_user_actions');

    # load the calendar row data
    $self->init_date( $c );

    my $slots = $self->week_of( $id_cal, $c->stash->{ monday } );
    $c->stash->{ slots } = $slots;

    $c->forward('/permissions/load_user_actions');
    $c->stash->{ template } = '/comp/job_calendar_slots.js';
}

# used by the grid
sub calendar_list_json : Path('/job/calendar_list_json') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ( $start, $limit, $query, $dir, $sort, $cnt ) = @{ $p }{ qw/start limit query dir sort/ };
    $sort eq 'bl_desc' and $sort = 'bl';
    my $rs = DB->BaliCalendar->search( undef, { order_by => $sort ? "$sort $dir" : undef } );
    my @rows;

    while ( my $r = $rs->next ) {
        next if ( $query && !query_array( $query, $r->name, $r->description, $r->ns ) );
        push @rows,
            {
            id          => $r->id,
            name        => $r->name,
            description => $r->description,
            active      => $r->active,
            seq         => $r->seq,
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

sub calendar_list : Path('/job/calendar_list') {
    my ( $self, $c ) = @_;

    #$c->stash->{ns_query} = { does=>['Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };
    $c->stash->{can_edit} = 
        $c->model('Permissions')->is_root( $c->username ) 
        ||
        $c->model('Permissions')
            ->user_has_action( username=>$c->username, action=>'action.job.calendar.edit', bl=>'*' );
    $c->stash->{ ns_query } = { does => [ 'Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };
    $c->stash->{ list_calendar } = 1;
    $c->forward( '/namespace/load_namespaces' );
    $c->forward( '/baseline/load_baselines' );
    $c->stash->{ template } = '/comp/job_calendar_grid.js';
}

sub calendar_update : Path( '/job/calendar_update' ) {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
_log "PARAMS: " . _dump $p;
    my $ns = $p->{cam_natures};#join(",",_array $p->{ns});
    #$ns =~ s/,$//; #quitamos "," del final que quedaría en caso de eliminar una aplicación o naturaleza
    try {
        if( $p->{action} eq 'create' ) {
            my $r1 = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => $p->{ bl } } );
            if ( my $r = $r1->first ) {
                _fail _loc( "A calendar (%1) already exists for namespace %2 and baseline %3", $r->name, $ns, $p->{ bl } );
            } else {
                my $row = $c->model('Baseliner::BaliCalendar')->create({
                        name        => $p->{ name },
                        description => $p->{ description },
                        seq         => $p->{ seq } // $DEFAULT_SEQ,
                        active      => '1',
                        ns          => $ns,
                        bl          => $p->{ bl }
                    }
                );
                if ( $p->{ copyof } ) {
                    my $copyOf = int( $p->{ copyof } );
                    $row = $c->model( 'Baseliner::BaliCalendar' )->search( { ns => $ns, bl => $p->{ bl } } )->first;
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
        else { # update
            my $row = $c->model( 'Baseliner::BaliCalendar' )->search( { id => $p->{ id_cal } } )->first;
            $row->name( $p->{ name } );
            $row->description( $p->{ description } );
            length $p->{ seq } and $row->seq( $p->{ seq } );
            $p->{ active } eq 'on' ?  $row->active( '1' ) : $row->active( '0' );
            $ns and $row->ns($ns);
            $p->{ bl } and $row->bl( $p->{ bl } );
            $row->update;
        }
        $c->stash->{ json } = { success => \1, msg => _loc( "Calendar '%1' modified", $p->{ name } ) };
    } catch {
        my $err = shift;
        _error $err;
        $c->stash->{ json } = { success => \0, msg => ( _loc( "Error modifying the calendar: " ) . $err ) };
    };
    $c->forward( 'View::JSON' );
}

sub calendar_slot_edit : Path( '/job/calendar_slot_edit' ) {
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
    $c->stash->{ template } = '/comp/job_calendar_slot_edit.js';
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

    try {
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
                    $cierra = 1;
                }
                else {
                    _fail( "<H5>Error: id '$id' de ventana no encontrado.</H5>" );
                }
            }
            elsif ( $cmd eq "A" or $cmd eq "AD" ) {
                my $active = ( $cmd eq "A" );

                unless ( $id ) {    #new row
                    my $r = $c->model( 'Baseliner::BaliCalendarWindow' )->create({
                        id_cal     => $id_cal,
                        day        => $ven_dia,
                        type       => $ven_tipo,
                        active     => $active,
                        start_time => $ven_ini,
                        end_time   => $ven_fin,
                        start_date => $self->parseDateTimeToDbix( $currentDate ),
                        end_date   => $self->parseDateTimeToDbix( $currentDate )
                    });
                }
                else {    #existing
                    my $row = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id => $id } )->first;
                    $row->delete;
                    # we need to recreate the id so this gets precedence in db_to_slots()
                    my $r = $c->model( 'Baseliner::BaliCalendarWindow' )->create({
                        id_cal     => $id_cal,
                        day        => $ven_dia,
                        type       => $ven_tipo,
                        active     => $row->active,
                        start_time => $ven_ini,
                        end_time   => $ven_fin,
                        start_date => $row->start_date,
                        end_date   => $row->end_date,
                    });
                }
                $self->db_merge_slots( $id_cal ) if defined $id_cal;
                $cierra = 1;
            }
            elsif ( $cmd eq "C1" || $cmd eq "C0" ) {

                #Activar
                my $row = $c->model( 'Baseliner::BaliCalendarWindow' )->search( { id => $id } )->first;
                $row->active( substr( $cmd, 1 ) );
                $row->update;
                $cierra = 1;
            }
            else {
                _fail( "<h5>Error: Comando desconocido o incompleto.</h5>" );
            }

            last unless ( $cierra );
        }
        $c->stash->{ json } = { success => \1, msg => _loc( "Calendar modified." ) };
    } catch {
        my $err = shift;
        _error $err;
        $c->stash->{ json } = { success => \0, msg => _loc( "Error modifying the calendar: %1", $err ) };
    };
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

=head2 db_merge_slots ( id_cal )

Cleans up bali_calendar_window for a given calendar id. 
Should be called anytime slot data is changed.

=cut
sub db_merge_slots {
    my ( $self, $id_cal ) = @_;

    # load slots from DB
    my $slots = $self->db_to_slots( $id_cal, no_base=>1 );

    # delete all cal rows
    my $rs = DB->BaliCalendarWindow->search({ id_cal=>$id_cal });
    return unless $rs->count;
    $rs->delete;

    my $to_time = sub { substr( $_[0], 0, 2 ) . ':' . substr( $_[0], 2, 2 ) };

    for ( $slots->sorted ) {
        my $date = join '-', ( $_->when =~ /^(\d{4})(\d{2})(\d{2})/ ) 
            if $_->type eq 'date';
        DB->BaliCalendarWindow->create(
            {  
                start_time => $to_time->( $_->{start} ),
                end_time   => $to_time->( $_->{end} ),
                start_date => $date,
                end_date   => $date,
                day        => ( $_->weekday - 1 ),
                type       => $_->data->{type},
                active     => $_->data->{active} // 1,
                id_cal     => $id_cal,
            }
        );
    }
}

=head2 build_job_window

Called by the New Job component. Merges all slots
that apply to a list of NS. 

=cut
sub build_job_window : Path('/job/build_job_window') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    try {
        my $date = $p->{job_date};
        my $date_format = $p->{date_format} or _fail "Missing date format";
        
        my $bl = $p->{bl};
        my $contents = _decode_json $p->{job_contents};
        $contents = $c->model('Jobs')->container_expand( $contents );
        my $month_days = 31;	

        # get calendar range list
        $date =  $date
            ? parse_dt( $date_format, $date )
            : _dt();  # _dt = now with timezone

        my @ns;
        # $contents = $c->model('Jobs')->container_expand( $contents );
        for my $item ( @{ $contents || [] } ) {
            my $namespace = $c->model('Namespaces')->get($item->{ns});
            my @ns_list = _array $item->{ns}, _array $namespace->nature, $namespace->application;

            #agrupamos el contenido del pase para filtrar luego los calendarios
            my @app_job = grep (/application/, @ns_list);
            my @nat_job = grep (/nature/, @ns_list);

            my $r = $c->model('Baseliner::BaliCalendar')->search({bl=>{ -in => ['*',$bl]}, active=>'1' });#todos los calendarios por entorno o generales
            while (my $rec = $r->next)
            {
                my @cal = split(/(?<=]),/,$rec->ns);
                my $aplica = 0;
                foreach (@cal){
                    my $app = @{ _from_json($_) }[0];
                    my @natus = split(",", @{ _from_json($_) }[1]);
                    if ($app~~@app_job || $app eq '/') #si coincide la aplicacion o es global miramos las naturalezas
                    {
                        if(scalar @nat_job >= scalar @natus){
                            my $nat_in_cal=0;
                            foreach my $nat(@nat_job)
                            {          
                                foreach (@natus) {
                                    if($nat =~ /harvest/) { #tecnologias FICH, ORA ...
                                        $nat_in_cal++ if ($_ =~ m/$nat/ ); 
                                    } else { #naturalezas ZOS
                                        $nat_in_cal++ if ($_ =~ m/^$nat$/);
                                    }
                                }
                            }
                            $aplica = 1 if $nat_in_cal == scalar @natus; #si aplican todas las naturalezas del calendario
                        }
                        $aplica =1 unless (scalar @natus); #si no hay naturalezas, aplica
                    }
                }
                push @ns, $rec->ns if $aplica;
            }
            push @ns, '["/",""]';#global

        }
        _debug "NS with Calendar: " . join ',',@ns;
        my %tmp_hash   = map { $_ => 1 } @ns;
        @ns = keys %tmp_hash;    
        _debug "------Checking dates for namespaces: " . _dump \@ns;

        my $hours = $self->merge_calendars( ns=>\@ns, bl=>$bl, date=>$date );

        # remove X
        while( my ($k,$v) = each %$hours ) {
            delete $hours->{$k} if $v->{type} eq 'X'; 
        }
        # get it ready for a combo simplestore
        my $hour_store = [ map {
           [ $hours->{$_}{hour}, $hours->{$_}{name}, $hours->{$_}{type} ]
        } sort keys %$hours ];

        $c->stash->{json} = {success=>\1, data => $hour_store };
    } catch {
        my $error = shift;
        _error $error;
        $c->stash->{json} = {success=>\0, msg=>$error, data => $error };
    };
    $c->forward('View::JSON');
}

sub begin : Private {
    my ($self,$c) = @_;
    if( $c->req->path =~ /build_job_window_direct/ ) {
        $c->stash->{auth_skip} = 1;
    }
}

sub build_job_window_direct : Path('/job/build_job_window_direct') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    try {
        my $date = $p->{job_date};
        my $date_format = $p->{date_format};
        _fail "Missing date format" if length $date && ! $date_format ;
        
        my $bl = $p->{bl};
        my $month_days = 31;	

        # get calendar range list
        $date =  $date
            ? parse_dt( $date_format, $date )
            : _dt();  # _dt = now with timezone

        if( $p->{day_add} ) {
            $date->add( days=>$p->{day_add} );
        }

        my @ns;
        #traduccion de los NS del pase o paquete a los NS de los Calendarios
        _log "NS: " . _dump $p->{ns};

        #agrupamos el contenido del pase para filtrar luego los calendarios
        my @app_job = grep (/application/, _array $p->{ns});
        my @nat_job = grep (/nature/, _array $p->{ns});

        my $r = $c->model('Baseliner::BaliCalendar')->search({bl=>{ -in => ['*',$bl]}, active=>'1' });#todos los calendarios por entorno o generales
        while (my $rec = $r->next)
        {
            my @cal = split(/(?<=]),/,$rec->ns);
            my $aplica = 0;
            foreach (@cal){
                my $app = @{ _from_json($_) }[0];
                my @natus = split(",", @{ _from_json($_) }[1]);
                if ($app~~@app_job || $app eq '/') #si coincide la aplicacion o es global miramos las naturalezas
                {
                    if(scalar @nat_job >= scalar @natus){
                        my $nat_in_cal=0;
                        foreach my $nat(@nat_job)
                        {
                            foreach (@natus) {
                                if($nat =~ /harvest/) { #tecnologias FICH, ORA ...
                                    $nat_in_cal++ if ($_ =~ m/$nat/ );
                                } else { #naturalezas ZOS
                                    $nat_in_cal++ if ($_ =~ m/^$nat$/);
                                }
                            }
                        }
                        $aplica = 1 if $nat_in_cal == scalar @natus; #si aplican todas las naturalezas del calendario
                    }
                    $aplica =1 unless (scalar @natus); #si no hay naturalezas, aplica
                }
            }
            push @ns, $rec->ns if $aplica;
        }
        push @ns, '["/",""]';#global

        _debug "NS with Calendar: " . join ',',@ns;
        my %tmp_hash   = map { $_ => 1 } @ns;
        @ns = keys %tmp_hash;    
        _debug "------Checking dates for namespaces ($date): " . _dump \@ns;

        my $hours = $self->merge_calendars( ns=>\@ns, bl=>$bl, date=>$date );

        # remove X
        while( my ($k,$v) = each %$hours ) {
            delete $hours->{$k} if $v->{type} eq 'X'; 
        }
        # get it ready for a combo simplestore
        my $hour_store = [ map {
            my $st = substr($hours->{$_}{start}, 0,2 ) . ':' . substr($hours->{$_}{start}, 2,2);
            my $et = substr($hours->{$_}{end}, 0,2 ) . ':' . substr($hours->{$_}{end}, 2,2 );
            [ $hours->{$_}{hour}, $hours->{$_}{name}, $hours->{$_}{type}, $st, $et ]
        } sort keys %$hours ];

        $c->stash->{json} = {success=>\1, data => $hour_store };
    } catch {
        my $error = shift;
        _error $error;
        $c->stash->{json} = {success=>\0, msg=>$error, data => $error };
    };
    $c->forward('View::JSON');
}


### Private Methods

sub init_date {
    my ( $self, $c ) = @_;
    my $date_str = $c->req->params->{ date } || $c->stash->{ preview_date };
    my $dt = ( $date_str ) ? $self->parseDateTime( $date_str ) : $c->session->{ currentDate } || DateTime->now();

    $c->stash->{ fecha_date }              = $dt;
    $c->stash->{ fecha_dia }               = $dt->day();
    $c->stash->{ fecha_mes }               = $dt->month();
    $c->stash->{ fecha_anyo }              = $dt->year();
    $c->stash->{ monday } = $self->getFirstDateTimeOfWeek( $dt );

    $c->session->{ currentDate }           = $dt;
    $c->session->{ currentFirstDayOfWeek } = $self->getFirstDateTimeOfWeek( $dt );

}

### Private Functions

=head2 db_to_slots ( id_cal, %opts )

Convert a given id_cal Calendar from the bali_calendar_window
table into a Calendar::Slots structure. 

Options:

    base => 1  # empty slots will be created with a 'B' type

=cut
sub db_to_slots {
    my ($self, $id_cal, %opts ) = @_;
    my @cals = DB->BaliCalendar->search(
        { 'me.id' => $id_cal },
        {
          prefetch=>'windows',
          order_by=>[
              { -asc =>'seq' },
              { -asc =>'windows.id' }, # last creation/edit is most important
              { -asc =>'windows.day' },
              { -asc =>'windows.start_time' }
          ]
        }
    )->hashref->all;
    my $slots = Calendar::Slots->new();
    # create base (undefined) calendar
    if( $opts{ base } ) {
        $slots->slot( weekday=>$_, start=>'00:00', end=>'24:00', name=>'B', data=>{ type=>'B' } )
            for 1 .. 7;
    }
    if ( my $cal = shift @cals ) {
        for my $win ( _array( $cal->{windows} ) ) {
            my $name = $win->{type};
            my $when;
            if ( $win->{start_date} ) {
                my $d = Class::Date->new( $win->{start_date} );
                $when = substr( $d->string, 0, 10 );
                $slots->slot(
                    date  => $when,
                    start => $win->{start_time},
                    end   => $win->{end_time},
                    name  => $name,
                    data  => $win
                );
            }
            else {
                $when = $win->{day} + 1;
                $slots->slot(
                    weekday => $when,
                    start   => $win->{start_time},
                    end     => $win->{end_time},
                    name    => $name,
                    data    => $win
                );
            }
        }
    }
    _debug $slots;
    return $slots;
}

sub week_of {
    my ($self, $id_cal, $week ) = @_;
    my $slots = $self->db_to_slots( $id_cal, base=>1 );
    $slots = $slots->week_of( substr( "$week", 0, 10 ) );
    return $slots;
}

sub merge_calendars {
    my ($self,%p) = @_;

    my $bl = $p{bl};
    my $now = Class::Date->new( _dt() );
    my $date = $p{date} || $now; 
    $date = Class::Date->new( $date ) if ref $date ne 'Class::Date' ;

    # if today, start hours at now
    my $start_hour = $now->ymd eq $date->ymd ? sprintf("%02d%02d", $now->hour , $now->minute) : '';

    my $where = {
        'me.active'=>'1',
        'windows.active'=>1,
    };

    $where->{bl} = ['*'];
    push @{ $where->{bl} }, $p{bl} if $p{bl};
    $where->{ns} = [ _unique _array $p{ns} ]; # Ambito global ya incluido como JSON '["/",""]'
    _debug "Calendar search: " . _dump $where;

    
    my @cals = DB->BaliCalendar->search(
        $where,
        {
          prefetch=>'windows',
          order_by=>[
              { -asc=>'seq' },
              { -asc=>'windows.day' },
              { -asc=>'windows.start_time' }
          ]
        }
    )->hashref->all;

    my @slots_cal;
    for my $cal (@cals) {
        my $slots = Calendar::Slots->new();
        for my $win ( _array $cal->{windows} ) {
            my $name = "$cal->{name} ($win->{type})==>" . ( $win->{day} + 1 );
            if ( $win->{start_date} ) {
                my $d = Class::Date->new( $win->{start_date} );
                $slots->slot(
                    date  => substr( $d->string, 0, 10 ),
                    start => $win->{start_time},
                    end   => $win->{end_time},
                    name  => $name,
                    data => { cal => $cal->{name}, type => $win->{type}, seq => $cal->{seq} }
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

    # prepare the date and weekday filters
    my $date_w = $date->wday -1;
    $date_w < 0  and $date_w += 7;
    my $date_s = $date->strftime('%Y%m%d');
    my %list;
    _debug "TOD=$date, W=$date_w, S=$date_s, START=$start_hour";
    _debug [ grep { ($_->type eq 'date' && $_->when eq $date_s) || ($_->type eq 'weekday' && $_->when eq $date_w) } map { $_->sorted } @slots_cal ];

    # loop all slots in all calendars - calendars are sorted by the SEQ field
    for my $s ( map { $_->sorted } @slots_cal ) {
       next if $s->type eq 'date' && $s->when ne $date_s;   # skip if does not apply to this date
       next if $s->type eq 'weekday' && $s->when ne $date_w; # skip if not apply to this weekday

       # loop minute-by-minute
       for( $s->start .. $s->end-1 ) {
         my $time = sprintf('%04d',$_);
         next if $start_hour && $time < $start_hour;  # don't show today time if it's passed already
         next if substr( $time, 2,2) > 59 ; # skip if >= 60 
         next if $time == 2400;  # no 24:00 in returned list
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
    \%list;
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

1;

