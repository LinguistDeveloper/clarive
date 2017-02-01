package Baseliner::Model::Events;
use Moose;

use Try::Tiny;
use POSIX ':sys_wait_h';
use Baseliner::Core::Registry ':dsl';
use Baseliner::Sugar;
use Baseliner::Core::Event;
use Baseliner::Sem;
use Baseliner::Utils;

our $STOP_EVENT_LOOP = 0;

with 'Baseliner::Role::Service';

with 'Baseliner::Role::CacheProxy' => {
    cache_key_cb => sub {
        shift;
        my ( $mid, %p ) = @_;

        { mid => "$mid", d => 'events', opts => \%p };    # [ "events:$mid:", \%p ];
    },
    methods => [qw/find_by_mid/]
};

register 'config.events' => {
    name => _locl('Event daemon configuration'),
    metadata => [
        { id=>'frequency', label=>'event daemon frequency (secs)', default=>10 },
        { id=>'timeout', label=>'event daemon event rule runner timeout (secs)', default=>30 },
        { id=>'iterations', label=>'event daemon loop iterations, default=1000', default=>1000 },
        { id=>'boost', label=>'how many events to treat at once, default=1', default=>1 },
    ]
};

register 'service.event.daemon' => {
    daemon => 1,
    icon => '/static/images/icons/service-event-daemon.svg',
    config => 'config.events',
    show_in_palette => 0,
    handler => sub {
        my ($self, $c, $config ) = @_;

        $config->{frequency} ||= 15 ;
        $config->{boost} ||= 1 ;

        $SIG{CHLD} = sub {
            while ( ( my $child = waitpid( -1, WNOHANG ) ) > 0 ) {
                _debug sprintf 'Reaped %s (%s)', $child, $?;
            }
        };

        _log _loc( "Event daemon starting with frequency %1, timeout %2, iterations %3, boost %4",
            $config->{frequency}, $config->{timeout}, $config->{iterations}, $config->{boost}
        );

        local $SIG{HUP} = sub {
            _warn( "Gracefully shutting down event loop pid=$$" );
            $STOP_EVENT_LOOP = 1;
        };

        for( 1..$config->{iterations} ) {
            $self->run_once( $c, $config );
            last if $STOP_EVENT_LOOP;
            sleep( $config->{frequency} );
        }

        # purge old events
        my $dt = _dt->subtract( days => ( $config->{purge_time} || 30 ) );
        $dt =  $dt->strftime('%Y-%m-%d %T');
        mdb->event_log->remove({ ts=>{ '$lt'=>$dt } });
        return 0;
    }
};

register 'service.event.run_once' => {
    handler=> \&run_once,
    icon => '/static/images/icons/service-event-run-once.svg',
    show_in_palette => 0,
};

sub run_once {
    my ($self, $c, $data ) = @_;

    my $rule_runner = Baseliner::RuleRunner->new(tidy_up => 0);
    my $boost = $data->{boost} || 1;
    my $events_processed = 0;

    EVENT_LOOP: while( 1 ) {

        my $sem = Baseliner::Sem->new( key=>'event_daemon', who=>"event_daemon", internal=>1 );
        $sem->take;

        my $rs = mdb->event->find({ event_status => 'new' })->sort({ '_id'=>1 })->limit($boost);

        if ( $rs->count ) {
            while( my $ev = $rs->next ) {
                $self->process_event( $ev, $data, $rule_runner );

                $events_processed++;

                if( $STOP_EVENT_LOOP ) {
                    last EVENT_LOOP;
                }
            }
        }
        else {
            last EVENT_LOOP;
        }

        if ( $sem ) {
            $sem->release;
        }
    }
    _debug( "End of event loop pid=$$, events processed=$events_processed, boost=$boost" );
}

sub find_by_key {
    my $self = shift;
    my ( $key, $args ) = @_;

    my $evs_rs = mdb->event->find( { event_key => $key } )->sort( { ts => -1 } );

    return [
        map {
            { %$_, %{ _load( $_->{event_data} ) || {} } }
        } $evs_rs->all
    ];
}

sub find_by_mid {
    my $self = shift;
    my ($mid, %p ) = @_;

    my $min_level = $p{min_level} // 0;

    my @events = mdb->event->find( { mid => "$mid" } )->sort( { ts => -1 } )->all;

    my @filtered_events =
      grep { ( defined $_->{ev_level} && $_->{ev_level} == 0 ) || ( $_->{level} // 0 ) >= $min_level } @events;

    my @elems;
    foreach my $event (@filtered_events) {
        my $ev = Baseliner::Core::Registry->get( $event->{event_key} );

        if ( !$ev || !%$ev ) {
            _error( _loc('Error in event text generator: event not found') );
            next;
        }

        my $event_data = _load( _to_utf8( $event->{event_data} ) );

        my %res = map { $_ => $event_data->{$_} } @{$ev->vars};

        $res{ts}       = $event->{ts};
        $res{username} = $event->{username};

        my %merged = ( %$event, %{ $event_data || {} } );
        $res{text} = $ev->event_text( \%merged );

        push @elems, \%res;
    }

    return \@elems;
}

sub process_event {
    my $self = shift;
    my ( $ev, $data, $rule_runner ) = @_;

    my $event_status = '??';

    _debug _loc( 'Running event %1 (id %2)', $ev->{event_key}, $ev->{id} );

    try {
        local $SIG{ALRM} = sub { die "timeout running event rules for post-offline\n" };
        alarm $data->{timeout} if $data->{timeout};  # 0 turns off timeout

        my $stash = $ev->{event_data} ? _load( $ev->{event_data} ) : {};

        # run rules for this event
        my $ret = $rule_runner->run_rules(
            event      => $ev->{event_key},
            rule_type  => 'event',
            when       => 'post-offline',
            stash      => $stash,
            no_capture => 1,
            onerror    => 1
        );
        alarm 0 if $data->{timeout};
        my $rc=0;

        # save log
        for my $rule ( _array( $ret->{rule_log} ) ) {
            mdb->event_log->insert( {
                    id          => mdb->seq('event_log'),
                    id_event    => $ev->{id},
                    id_rule     => $rule->{id},
                    stash_data  => _dump( $rule->{ret} ),
                    return_code => $rule->{rc},
                    dsl         => $rule->{dsl},
                    ts          => mdb->ts,
                    log_output  => $rule->{output},
                }
            );
            $rc += $rule->{rc} if $rule->{rc};
        }

        # run notifications for event
        $self->notify_event( $ev, $stash );

        $event_status= $rc ? 'ko' : 'ok';
        mdb->event->update( {id => $ev->{id}}, {'$set'=>{event_status=>$event_status}});
    }
    catch {
        my $err = shift;
        # TODO global error or a rule by rule (errors go into rule, but event needs a global)
        _error _loc( 'event %1 failed (id=%2): %3', $ev->{event_key}, $ev->{id}, $err );
        if( $err =~ m/^alarm/s ) {
            alarm 0;
            $event_status = 'timeout';
        } else {
            $event_status = 'ko';
        }
        mdb->event->update( {id => $ev->{id}}, {'$set'=>{event_status=>$event_status}});
    };
    _debug _loc( 'Finished event %1 (id %2), status: %3', $ev->{event_key}, $ev->{id}, $event_status );
}

sub notify_event {
    my $self = shift;
    my ( $ev, $stash ) = @_;

    my $rc = 0;

    my $event_key = $ev->{event_key};
    my $notify_scope = $stash->{notify};
    my @notify_default;

    my $ev_reg  = Baseliner::Core::Registry->get($event_key);

    my $topic;
    if($stash->{mid}){
        $topic = mdb->topic->find_one({ mid => "$stash->{mid}"}, { _txt=>0 })
    }
    $topic = $topic ? $topic : {};

    my $config = config_get('config.notifications');

    if (!$config->{exclude_default}){
        push @notify_default, _array $stash->{notify_default} if $stash->{notify_default};
        push @notify_default, $stash->{created_by} if $stash->{created_by};
    }

    require Baseliner::Model::Notification;
    my $notification = Baseliner::Model::Notification->new->get_notifications(
        {
            event_key      => $event_key,
            notify_default => \@notify_default,
            notify_scope   => $notify_scope,
            mid            => $stash->{mid}
        }
    );
    my $config_email = BaselinerX::Type::Model::ConfigStore->new->get( 'config.comm.email' )->{from};

    if ($notification){
        foreach  my $template (  keys %$notification ){

            my $subject_parse = $notification->{$template}->{subject} // $stash->{subject};

            my $subject = parse_vars( $subject_parse, { %$stash, %$topic } ) || try {
                my $msg = Util->_strip_html( $ev_reg->event_text($stash) );
                substr( $msg, 0, 120 ) . ( length($msg) > 120 ? '...' : '' );
            } || $event_key;

            my $model_messaging = {
                subject         => $subject,
                sender          => $config_email || 'clarive@clarive.com',
                carrier         => 'email',
                template        => $notification->{$template}->{template_path},
                template_engine => 'mason',
                _fail_on_error  => 1,   # so that it fails on template errors
            };

            $model_messaging->{to} = { users => $notification->{$template}->{carrier}->{TO} }
              if ( exists $notification->{$template}->{carrier}->{TO} );
            $model_messaging->{cc} = { users => $notification->{$template}->{carrier}->{CC} }
              if ( exists $notification->{$template}->{carrier}->{CC} );
            $model_messaging->{bcc} = { users => $notification->{$template}->{carrier}->{BCC} }
              if ( exists $notification->{$template}->{carrier}->{BCC} );

            $model_messaging->{vars} = { %$topic, %$stash };
            $model_messaging->{vars}->{subject} = $subject;
            $model_messaging->{vars}->{to} = { users => $notification->{$template}->{carrier}->{TO} }
              if ( exists $notification->{$template}->{carrier}->{TO} );
            $model_messaging->{vars}->{cc} = { users => $notification->{$template}->{carrier}->{CC} }
              if ( exists $notification->{$template}->{carrier}->{CC} );
            $model_messaging->{vars}->{bcc} = { users => $notification->{$template}->{carrier}->{BCC} }
              if ( exists $notification->{$template}->{carrier}->{BCC} );

            my $rc_notify = 0;
            my $err = '';
            try {
                Baseliner->model( 'Messaging' )->notify(%{$model_messaging});
            } catch {
                $err = shift;
                $rc_notify = 1;
                $rc += $rc_notify;
            };

            mdb->event_log->insert( {
                    id          => mdb->seq('event_log'),
                    id_event    => $ev->{id},
                    stash_data  => _dump($model_messaging),
                    return_code => $rc_notify,
                    ts          => mdb->ts,
                    log_output  => $err,
                    dsl         => '',
                }
            );
        }
    }

    return $rc;
}

sub new_event {
    my $self = shift;
    my ( $key, $data, $code, $catch, $caller ) = @_;

    my $module = $caller || caller;

    if ( ref $data eq 'CODE' ) {
        $code = $data;
        $data = {};
    }
    $data ||= {};

    my $ev = Baseliner::Core::Registry->get($key);
    _throw "Event '$key' not found in registry" unless $ev && %$ev;

    return try {
        $self->_new_event( $ev, $key, $data, $module, $code );
    }
    catch {
        my $err = shift;
        if ( ref $catch eq 'CODE' ) {
            $catch->($err);
            _error "*** event_new: caught $key: $err";
        }
        else {
            _error "*** event_new: untrapped $key: $err";
            _fail $err;
        }
    };
}

sub _new_event {
    my $self = shift;
    my ( $ev, $key, $data, $module, $code ) = @_;
    my $ts       = mdb->ts;
    my $ts_hires = mdb->ts_hires;

    my $steps = delete $data->{_steps} || [qw/PRE RUN POST/];

    try {
        if ( length $data->{mid} ) {
            my $ci = $data->{ci} // ci->new( $data->{mid} );
            my $ci_data = $data->{ci_data} // $ci->load;
            $data = { %$ci_data, ci => $ci, %$data };
        }
        else {
            $data = {%$data};
        }
    }
    catch {
        _error _loc( "Error: Could not instantiate ci data for event: %1", shift() );
    };

    my @rule_log;

    my $obj = Baseliner::Core::Event->new( data => $data );

    # PRE
    if (grep { $_ eq 'PRE' } @$steps) {
        my $rules_pre = $ev->rules_pre_online($data);

        $data->{return_options}{reload} = 1 if $rules_pre->{stash}{rules_exec}{$ev->key}{'pre-online'};

        push @rule_log, _array( $rules_pre->{rule_log} );

        # PRE hooks
        for my $hk ( $ev->before_hooks ) {
            my $hk_data = $hk->($obj);
            $data = { %$data, %$hk_data } if ref $hk_data eq 'HASH';
            $obj->data($data);
        }
    }

    # RUN
    if (grep { $_ eq 'RUN' } @$steps) {
        if ( ref $code eq 'CODE' ) {
            my $rundata = $code->($data);

            if (ref $rundata eq 'HASH') {
                $data = { %$data, %$rundata };
            }
        }
    }

    #if( !length $data->{mid} ) {
    #    _debug 'event_new is missing mid parameter' ;
    #_throw 'event_new is missing mid parameter' ;
    #} else {
    #}

    # POST hooks
    if (grep { $_ eq 'POST' } @$steps) {
        $obj->data($data);
        for my $hk ( $ev->after_hooks ) {
            my $hk_data = $hk->($obj);
            $data = { %$data, %$hk_data } if ref $hk_data eq 'HASH';
            $obj->data($data);
        }

        # POST rules
        my $rules_post = $ev->rules_post_online($data);
        push @rule_log, _array( $rules_post->{rule_log} );

        $self->_create_event_and_friends(
            event    => $ev,
            key      => $key,
            module   => $module,
            data     => $data,
            ts       => $ts,
            ts_hires => $ts_hires,
            rule_log => \@rule_log
        );
    }

    return $data;
}

sub _create_event_and_friends {
    my $self = shift;
    my ( %params ) = @_;

    my $ev       = $params{event};
    my $key      = $params{key};
    my $module   = $params{module};
    my $ed       = $params{data};
    my $ts       = $params{ts};
    my $ts_hires = $params{ts_hires};
    my $rule_log = $params{rule_log};

    my $ev_id = mdb->seq('event');

    # rgo: remember, top mongo doc size is 16MB. #11905
    # TODO large data should be in the Grid instead
    my $event_data = substr( _dump($ed), 0, 4_096_000 );    # 4MB
    mdb->event->insert(
        {
            id           => $ev_id,
            ts           => $ts,
            t            => $ts_hires,
            event_key    => $key,
            event_data   => $event_data,
            event_status => 'new',
            module       => $module,
            mid          => $ed->{mid},
            username     => $ed->{username}
        }
    );
    if (( $key =~ /event.topic|event.file|event.post|event.ci/ ) && _array( $ev->{vars} ) > 0 ) {
        my $ed_reduced = {};
        # fix "unhandled" Mongo errors due to unblessed structures
        my $ed_cloned = Util->_clone($ed);
        Util->_unbless($ed_cloned);
        foreach ( _array $ev->{vars} ) {
            $ed_reduced->{$_} = $ed_cloned->{$_};
        }
        $ed_reduced->{ts} = mdb->ts;

        mdb->activity->insert(
            {
                vars      => $ed_reduced,
                event_key => $key,
                event_id  => $ev_id,
                mid       => $ed->{mid},
                module    => $module,
                ts        => $ts,
                username  => $ed->{username},
                text      => $ev->{text},
                ev_level  => $ev->{ev_level},
                level     => $ev->{level}
            }
        );
    }

    for my $log (@$rule_log) {
        my $stash_data = substr( _dump( $log->{ret} ),    0, 1_024_000 );    # 1MB
        my $log_output = substr( _dump( $log->{output} ), 0, 4_096_000 );    # 4MB
        my $dsl        = substr( $log->{dsl},             0, 1_024_000 );

        my $log        = {
            id         => mdb->seq('event_log'),
            id_event   => $ev_id,
            id_rule    => $log->{id},
            ts         => $ts,
            t          => $ts_hires,
            stash_data => $stash_data,
            dsl        => $log->{dsl},
            log_output => $log_output,
        };
        mdb->event_log->insert($log);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
