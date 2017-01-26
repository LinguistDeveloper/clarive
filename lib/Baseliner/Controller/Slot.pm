package Baseliner::Controller::Slot;
use Moose;
use Baseliner::Core::Registry ':dsl';
BEGIN { extends 'Catalyst::Controller' };
use Baseliner::Core::Baseline;
use Baseliner::Model::Calendar;
use Baseliner::Utils;
use Calendar::Slots 0.15;
use DateTime;
use Try::Tiny;
use Baseliner::Sugar;
use experimental 'autoderef';

our $DEFAULT_SEQ = 100;

register 'menu.job.calendar' => {
    label    => _locl('Calendaring'),
    url_comp => '/job/calendar_grid',
    title    => _locl('Calendaring'),
    actions  => ['action.calendar.%'],
    icon     => '/static/images/icons/slot.svg'
};
register 'action.calendar.view' => { name => _locl('View Job Calendar') };
register 'action.calendar.edit' => { name => _locl('Edit Job Calendar'), extends => ['action.calendar.view'] };
register 'action.calendar.admin' => { name => _locl('Admin Job Calendar'), extends => ['action.calendar.view', 'action.calendar.edit']};

register 'config.job.calendar' => {
    metadata=> [
        { id=>'name', label => _locl('Calendar'), type=>'text', width=>200 },
        { id=>'ns', label => _locl('Namespace'), type=>'text', width=>300 },
        { id=>'ns_desc', label => _locl('Namespace Description'), type=>'text', width=>300 },
    ],
};

# main editor window

sub calendar : Path( '/job/calendar' ) {
    my ( $self, $c ) = @_;

    my $p      = $c->req->params;
    my $id_cal = delete $p->{id_cal};
    my $row;
    if ( $id_cal > 0 ) {
        $row = mdb->calendar->find_one( { id => '' . $id_cal } );
    }
    elsif ( $id_cal < 0 && $p->{ns} ) {
        if ( $row = mdb->calendar->find_one( { ns => $p->{ns} } ) ) {
            $id_cal = $row->{id};
        }
    }
    $c->stash->{ns_query}
        = { does => [ 'Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };

    #$c->forward( '/namespace/load_namespaces' );
    $c->forward('/baseline/load_baselines');

    # load the calendar row data
    $self->init_date($c);
    $c->stash->{calendar} = $row
        ? $row    # ci calendar
        : ( !$id_cal || $id_cal < 0 ) ? $p    # new calendar, from ci editor
        :                               +{ mdb->calendar->find_one( { id => $id_cal } ) };   # regular existing calendar

    $self->permissions_calendar($c);

    $c->stash->{id_cal}   = $id_cal;
    $c->stash->{template} = '/comp/job_calendar_editor.js';
}

# slot editor
sub calendar_slots : Path( '/job/calendar_slots' ) {
    my ( $self, $c ) = @_;
    my $id_cal = $c->stash->{ id_cal } = $c->req->params->{ id_cal };
    # get the panel id to be able to refresh it
    $c->stash->{ panel } = $c->req->params->{ panel };
    # load the calendar row data
    $self->init_date( $c );

    my $slots = $self->week_of( $id_cal, $c->stash->{ monday } );
    $c->stash->{ slots } = $slots;

    $c->stash->{ template } = '/comp/job_calendar_slots.js';
}

# used by the grid
sub calendar_grid_json : Path('/job/calendar_grid_json') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ( $start, $limit, $query, $dir, $sort ) = @{ $p }{ qw/start limit query dir sort/ };
    $dir = $dir ? ( lc($dir) eq 'desc' ? -1 : 1 ) : 1;
    $start //= 0;

    my $where = {};
    if ($query){
       $where = mdb->query_build(query=>$query, fields=>[qw(bl description name)]);
    }
    my $rs = mdb->calendar->find($where);
    if ($limit && $limit != -1) {
        $rs->limit($limit)->skip($start);
    }

    $rs->sort({ $sort => $dir }) if $sort;

    my @rows;
    while ( my $r = $rs->next ) {
        next if $query && !Util->query_grep( query=>$query, all_fields=>1, rows=>[ $r ] );
        push @rows,
            {
            id          => $r->{id},
            name        => $r->{name},
            description => $r->{description},
            seq         => $r->{seq},
            bl          => $r->{bl},
            bl_desc     => Baseliner::Core::Baseline->name( $r->{bl} ),
            ns          => $r->{ns},
            ns_desc     => $r->{ns},
            }
    }
    my %mids;
    my @infrastructure_cis = map { $_->{ns} } grep { $_->{ns} && $_->{ns} ne '/' } grep { length } @rows;
    foreach my $infrastructure_mid (@infrastructure_cis){
        try{
            $mids{$infrastructure_mid} = ci->new($infrastructure_mid);
        } catch {}
    }
    foreach my $row (@rows) {
        if ( $row->{ns} && $mids{ $row->{ns} } ) {
            $row->{ns} = $mids{ $row->{ns} }->{name};
        }
    }

    $c->stash->{ json } = { data => \@rows, totalCount => $rs->count };
    $c->forward( 'View::JSON' );
}

sub calendar_grid : Path('/job/calendar_grid') {
    my ( $self, $c ) = @_;

 #$c->stash->{ns_query} = { does=>['Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };

    $self->permissions_calendar($c);

    $c->stash->{ns_query}
        = { does => [ 'Baseliner::Role::Namespace::Nature', 'Baseliner::Role::Namespace::Application', ] };

    $c->stash->{namespaces} = [];

    #$c->forward( '/namespace/load_namespaces' );
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/job_calendar_grid.js';
}

sub calendar_update : Path( '/job/calendar_update' ) {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $new_id;

    my @msgs = ();

    try {
        # may be a CI calendar, search for its id_cal if we don't have one
        if( !length $p->{id_cal} || $p->{id_cal} == -1 ) {
            _fail 'Missing ns parameter' unless defined $p->{ns};
            my $cal = mdb->calendar->find_one({ ns => $p->{ns} });
            if( ref $cal ) {
                $p->{id_cal} = $cal->{id};
                $p->{action} = 'update';
            }
            else {
                $p->{action} = 'create';
            }
        }

        if( ($p->{action} && $p->{action} eq 'create') || ($p->{newAction} && $p->{newAction} eq 'create') )  {
            @msgs = ( _loc('created'), _loc('creating') );

            $p->{ns} = '/' unless length $p->{ns};
            my $r1 = mdb->calendar->find({ ns => $p->{ ns }, bl => $p->{ bl } });
            if ( my $r = $r1->next ) {
                _fail _loc( "A calendar (%1) already exists for namespace %2 and baseline %3", $r->{name}, $p->{ ns }, $p->{ bl } );
            } else {
                my $new_id_cal = mdb->seq('calendar');
                my $_id = mdb->calendar->insert({
                    id          => $new_id_cal,
                    name        => $p->{ name },
                    description => $p->{ description },
                    seq         => $p->{ seq } // $DEFAULT_SEQ,
                    active      => '1',
                    ns          => $p->{ ns },
                    bl          => $p->{ bl }
                });
                $new_id = $new_id_cal;
                if ( $p->{ copyof } ) {
                    #my $copyOf = int( $p->{ copyof } );
                    my $copyOf = $p->{ copyof };
                    $_id = mdb->calendar->find_one( { ns=>$p->{ns}, bl=>$p->{ bl } } );
                    my @rs = mdb->calendar_window->find({ id_cal => $copyOf })->all;
                    for my $r (@rs) {
                        mdb->calendar_window->insert({
                            id         => mdb->seq('calendar_window'),
                            start_time => $r->{start_time},
                            end_time   => $r->{end_time},
                            start_date => $r->{start_date},
                            end_date   => $r->{end_date},
                            day        => $r->{day},
                            type       => $r->{type},
                            active     => $r->{active},
                            id_cal     => $new_id
                        });
                    }
                }
            }
        }
        else { # update
            @msgs = ( _loc('modified'), _loc('modifying') );
            my $row = mdb->calendar->find_one({ id => ''.$p->{ id_cal } });
            $row->{name} = $p->{ name };
            $row->{description} = $p->{ description };
            length $p->{ seq } and $row->{seq} = $p->{ seq };
            $row->{ns} = length $p->{ns} ? $p->{ns} : '/';
            $p->{bl} and $row->{bl} = $p->{bl};

            mdb->calendar->update({ id => ''.$p->{ id_cal } }, $row);
        }
        $c->stash->{ json } = { success => \1, msg => _loc( "Calendar with id '%1' %2", $p->{ name }, $msgs[0] ), id_cal=>$new_id // $p->{id_cal} };
    } catch {
        my $err = shift;
        _error $err;
        $c->stash->{ json } = { success => \0, msg => ( _loc( "Error %1 the calendar: ", $msgs[1] ) . $err ) };
    };
    $c->forward( 'View::JSON' );
}

sub calendar_delete : Path( '/job/calendar_delete' ) : Does('ACL') : ACL('action.calendar.admin') {
    my ( $self, $c ) = @_;

    my $params = $c->req->params;

    my $ids = $params->{ids};

    try {
        Baseliner::Model::Calendar->new->delete_multi( ids => $ids );

        $c->stash->{json} = { success => \1, msg => _loc('Calendar(s) deleted') };
    }
    catch {
        my $err = shift;

        _error $err;

        $c->stash->{json} = { success => \0, msg => _loc('Error deleting calendar(s)') };
    };

    $c->forward('View::JSON');

    return;
}

sub calendar_slot_edit : Path( '/job/calendar_slot_edit' ) {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{ panel } = $p->{ panel };
    my $id     = $p->{ id };
    my $id_cal = $p->{ id_cal };
    my $win;
    $win = mdb->calendar_window->find_one( { id => ''.$id } ) if ($id);
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
            $inicio = $win->{start_time};
            $fin    = $win->{end_time};
            $dia    = $win->{day};
            $tipo   = $win->{type};
            $activa = $win->{active};
            $date   = $win->{start_date};
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

    my $p = $c->req->params;

    my $id_cal     = $p->{id_cal};
    my $id         = $p->{id};
    my $cmd        = $p->{cmd};
    my $day        = $p->{ven_dia} // '';
    my $start_time = $p->{ven_ini};
    my $end_time   = $p->{ven_fin};
    my $type       = $p->{ven_tipo};
    my $date_str   = $p->{date};
    my $new_id;
    my $current_date = $self->parseDateTime($date_str) if ($date_str);

    try {
        my @days;
        if ( $day eq "L-V" ) {
            @days = ( 0 .. 4 );
        }
        elsif ( $day eq "L-D" ) {
            @days = ( 0 .. 6 );
        }
        else {
            push @days, $day;
        }
        foreach my $day (@days) {
            if ( $cmd eq "B" ) {
                #delete row
                if ($id) {
                    mdb->calendar_window->update( { id => $id }, { '$set' => { type => 'B' } } );
                    $self->db_merge_slots($id_cal) if defined $id_cal;
                }
                else {
                    _fail( "<H5>" . _loc("Error: Window with id not found.") . "</H5>" );
                }
            }
            elsif ( $cmd eq "A" or $cmd eq "AD" ) {
                my $active = ( $cmd eq "A" );
                $new_id = '' . mdb->seq('calendar_window');
                if ( $cmd eq "A" and $id ) {
                    mdb->calendar_window->remove( { id => $id } );
                }
                mdb->calendar_window->insert(
                    {   id         => $new_id,
                        id_cal     => "$id_cal",
                        day        => $day,
                        type       => $type,
                        active     => $active,
                        start_time => $start_time,
                        end_time   => $end_time,
                        start_date => $self->parseDateTimeToDbix($current_date),
                        end_date   => $self->parseDateTimeToDbix($current_date)
                    }
                );
                $self->db_merge_slots($id_cal) if defined $id_cal;
            }
            elsif ( $cmd eq "C1" || $cmd eq "C0" ) {

                #Activar
                mdb->calendar_window->update( { id => $id }, { '$set' => { active => substr( $cmd, 1 ) } } );
            }
            else {
                _fail( '<h5>' . _loc("Error: Unknown or incomplete command.") . '</h5>' );
            }
        }
        $c->stash->{json} = { success => \1, msg => _loc("Calendar modified."), cal_window => $id // $new_id };
    }
    catch {
        my $err = shift;
        _error $err;
        $c->stash->{json} = { success => \0, msg => _loc( "Error modifying the calendar: %1", $err ) };
    };
    $c->forward('View::JSON');
}

=head2 db_merge_slots ( id_cal )

Cleans up bali_calendar_window for a given calendar id.
Should be called anytime slot data is changed.

=cut
sub db_merge_slots {
    my ( $self, $id_cal ) = @_;

    # load slots from DB
    my $slots = $self->db_to_slots( $id_cal, base=>1 );
    # delete all cal rows
    my $rs = mdb->calendar_window->find({ id_cal=>$id_cal });
    return unless $rs->count;
    mdb->calendar_window->remove({ id_cal=>$id_cal },{ multiple=>1 });

    my $to_time = sub { substr( $_[0], 0, 2 ) . ':' . substr( $_[0], 2, 2 ) };

    for ( $slots->sorted ) {
        my $date = join '-', ( $_->when =~ /^(\d{4})(\d{2})(\d{2})/ )
            if $_->type eq 'date';
        my $new_id = ''.mdb->seq('calendar_window');
        mdb->calendar_window->insert({
            id         => $new_id,
            start_time => $to_time->( $_->{start} ),
            end_time   => $to_time->( $_->{end} ),
            start_date => $date,
            end_date   => $date,
            day        => ( $_->weekday - 1 ),
            type       => $_->data->{type},
            active     => $_->data->{active} // 1,
            id_cal     => $id_cal,
        });
    }
}

=head2 build_job_window

Called by the New Job component. Merges all slots
that apply to a list of NS.

=cut
sub build_job_window : Path('/job/build_job_window') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    $Baseliner::CI::_edge = 1;
    try {
        my $date = $p->{job_date};
        my $date_format = $p->{date_format} or _fail "Missing date format";

        my $bl = $p->{bl};
        my $contents = _decode_json $p->{job_contents};
        #$contents = $c->model('Jobs')->container_expand( $contents );
        my $month_days = 31;

        # get calendar range list
        $date =  $date
            ? parse_dt( $date_format, $date )
            : _dt();  # _dt = now with timezone

        my @ns;
        my @all_projects;
        my %cis;  # keep track of all ci relations found
        my $depth_default = 4;
        # $contents = $c->model('Jobs')->container_expand( $contents );
        my @collections = map { /BaselinerX::CI::(.*)/ } packages_that_do( 'Baseliner::Role::CI::Revision' );
        push @collections, map { /BaselinerX::CI::(.*)/ } packages_that_do( 'Baseliner::Role::CI::Infrastructure' );
        for my $item ( _array( $contents ) ) {
            my $mid = $item->{mid};
            my $ci = _ci( $mid );
            # recurse into ci relations up to depth
            my @related;
            push @related, $ci->children( depth => $depth_default, where => { collection => mdb->in(@collections) }, docs_only => 1 ) ;
            my @projects = $ci->children( depth => 1, where => { collection => 'project'} ) ;

            for my $project ( @projects ) {
                push @related, $project->parents( depth => 1, where => { collection => 'group'}, docs_only => 1 ) ;
            }

            push @all_projects, @projects;
            push @related, @projects;

            # ask for nature from revisions TODO this is a placeholder still, revisions need to support nature
            my @natures = grep { defined } map { $_->{natures} if $_->{natures} } $ci, @related;
            _debug "Natures for $mid: ", @natures;
            # save for later
            $cis{ $mid } = { ci=>$ci, related=>\@related, natures=>\@natures };
            # keep the ids
            my @rel_ids = map { $_->{mid} } @related;
            push @ns, ( $mid, @rel_ids );
        }
        @ns = _unique @ns;

        my ($hour_store, @rel_cals) = Baseliner::Model::Calendar->new->check_dates($date, $bl, @ns);

        # build statistics
        my %stats;
        my $prj_list = mdb->in( map { $_->{mid} } @all_projects );
        # TODO loop by project here so we get 1000 from one, 1000 from another...
        my $rs = ci->job->find({ projects=>$prj_list, bl=>$bl })->sort({ starttime=>-1 })->limit(1000);
        while( my $job = $rs->next ) {
            next unless $job->{endtime} && $job->{starttime};
            my $bl = $job->{bl};
            my @prjs = _array( $job->{projects} );
            # TODO use only last months or last 10; -- success rate based on last 10, etc.
            map {
                my $k = $_ . "-" . $bl;
                # duration
                push @{ $stats{$k}{dur} }, ((Class::Date->new( $job->{endtime} ) - Class::Date->new($job->{starttime}))/@prjs)
                    if $job->{status} eq 'FINISHED';
                # success rate
                $job->{status} eq 'FINISHED' ? $stats{$k}{ok}++ : $stats{$k}{ko}++;
            } @prjs;
        }

        my @res; my @durs; my $succ=1;
        my $any_succ = 0;
        for my $pb ( keys %stats ) {
            my $v = $stats{$pb};
            my @dur = @{ $$v{dur} // [] };
            push @durs, (Util->stat_mode(@dur)) if @dur;   # TODO weighted avg by project?
            my ($ok,$ko) = @{$v}{qw(ok ko)};
            $succ = $succ * ( !$ok ? 0 : $ok/($ok+$ko) );
            $any_succ = 1 if $ok || $ko;
            #map { _warn("DUR=========================$_"); $durs+=$_ } @dur;
        }
        my $avg = '?';
        if( @durs ) {
            $avg = Util->to_dur(List::Util::sum(@durs));
        }

        #my $cis2 = Util->_clone( \%cis );
        #Util->_unbless( $cis2 );

        $c->stash->{json} = {
            success=>\1,
            data=>$hour_store,
            cis=>\%cis,
            cals=>\@rel_cals,
            stats=>{ eta=>$avg, p_success=>$any_succ?int($succ*100).'%':'?' }
        };
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

        my @ns = _array $p->{ns};
        my ($hour_store, @rel_cals) =Baseliner::Model::Calendar->new->check_dates($date, $bl, @ns);

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
    my @cals = mdb->joins(
            calendar => { id=>$id_cal },
            id => id_cal =>
            calendar_window => {} );
    my $slots = Calendar::Slots->new();
    # create base (undefined) calendar
    if( $opts{ base } ) {
        $slots->slot( weekday=>$_, start=>'00:00', end=>'24:00', name=>'B', data=>{ type=>'B' } )
            for 1 .. 7;
    }
    if ( my $cal =  $cals[0] ) {
        for my $win ( _array( @cals ) ) {
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
    return $slots;
}

sub week_of {
    my ($self, $id_cal, $week ) = @_;
    my $slots = $self->db_to_slots( $id_cal, base=>1 );
    $slots = $slots->week_of( substr( "$week", 0, 10 ) );
    return $slots;
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

sub permissions_calendar {
    my ( $self, $c ) = @_;

    $c->stash->{can_admin} = $c->model('Permissions')->user_has_action( $c->username, 'action.calendar.admin' );
    $c->stash->{can_edit}  = $c->model('Permissions')->user_has_action( $c->username, 'action.calendar.edit' );
    $c->stash->{can_view}  = $c->model('Permissions')->user_has_action( $c->username, 'action.calendar.view' );

    if ( !$c->stash->{can_view} ) {
        $c->stash->{json} = { success => \0, msg => _loc("You do not have permissions to open this calendar") };
        $c->forward('View::JSON');
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
