package Baseliner::Model::Events;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

with 'Baseliner::Role::Service';

register 'config.events' => {
    name => 'Event daemon configuration',
    metadata => [
        { id=>'frequency', label=>'event daemon frequency (secs)', default=>15 },    
        { id=>'timeout', label=>'event daemon event rule runner timeout (secs)', default=>30 },    
    ]
};

register 'service.event.daemon' => {
    daemon => 1,
    config => 'config.events',
    handler => sub {
        my ($self, $c, $config ) = @_;
        $config->{frequency} ||= 15 ;
        _log _loc "Event daemon starting with frequency %1, timeout %2", $config->{frequency}, $config->{timeout};
        require Baseliner::Sem;
        my $sem = Baseliner::Sem->new( key=>'event_daemon', who=>"event_daemon", internal=>1 );
        for( 1..1000 ) {
            $sem->take;
            $self->run_once( $c, $config );
            if ( $sem ) {
                $sem->release;
            }
            sleep( $config->{frequency} );
        } 
        # purge old events
        my $dt = _dt->subtract( days => ( $config->{purge_days} || 30 ) );
        $dt =  $dt->strftime('%Y-%m-%d %T');
        return 0;
    }
};

register 'service.event.run_once' => {
    handler=> \&run_once,
};

sub run_once {
    my ($self, $c, $data ) = @_;
    my $rules = Baseliner->model('Rules')->new;
    $rules->tidy_up( 0 );  # turn off perl_tidy
    my $rs = mdb->event->find({ event_status => 'new' })->sort({ '_id'=>1 });
    while( my $ev = $rs->next ) {
        my $event_status = '??';
        _debug _loc 'Running event %1 (id %2)', $ev->{event_key}, $ev->{id};
        try {
            local $SIG{ALRM} = sub { die "timeout running event rules for post-offline\n" };
            alarm $data->{timeout} if $data->{timeout};  # 0 turns off timeout
            my $stash = $ev->{event_data} ? _load( $ev->{event_data} ) : {};
            # run rules for this event
            my $ret = $rules->run_rules( event=>$ev->{event_key}, rule_type=>'event', when=>'post-offline', stash=>$stash, onerror=>1 );
            alarm 0 if $data->{timeout};
            my $rc=0;
            # save log
            for my $rule ( _array( $ret->{rule_log} ) ) {
                mdb->event_log->insert({
                    id=>mdb->seq('event_log'), 
                    id_event=> $ev->{id}, 
                    id_rule=> $rule->{id}, 
                    stash_data=> _dump( $rule->{ret} ), 
                    return_code=>$rule->{rc}, 
                    dsl => $rule->{dsl},
                    log_output => $rule->{output},
                });
                $rc += $rule->{rc} if $rule->{rc};
            }
            
            my $event_key = $ev->{event_key};
            my $notify_scope = $stash->{notify};
            my @notify_default;
            
            
            my $config = config_get('config.notifications');
            if (!$config->{exclude_default}){
                push @notify_default, _array $stash->{notify_default} if $stash->{notify_default};
                push @notify_default, $stash->{created_by} if $stash->{created_by};
            }
            
            my $notification = Baseliner->model('Notification')->get_notifications({ event_key => $event_key, notify_default => \@notify_default, notify_scope => $notify_scope, mid => $stash->{mid} });
            my $config_email = Baseliner->model( 'ConfigStore' )->get( 'config.comm.email' )->{from};
            if ($notification){
                foreach  my $template (  keys $notification ){
                    my $topic = {};
                    $topic = mdb->topic->find_one({ mid => "$stash->{mid}"}) if $stash->{mid};
                    my $subject = parse_vars($stash->{subject},{%$stash,%$topic} ) || try{ 
                            my $ev = Baseliner->registry->get( $event_key );
                            my $msg = Util->_strip_html($ev->event_text( $stash ));
                            substr( $msg, 0, 120 ) . ( length($msg)>120 ? '...' : '' );
                        } || $event_key;
                    my $model_messaging = {
                        subject         => $subject,
                        sender          => $config_email || 'clarive@clarive.com',
                        carrier         => 'email',
                        template        => $notification->{$template}->{template_path},
                        template_engine => 'mason',
                        _fail_on_error  => 1,   # so that it fails on template errors
                    };
                    
                    $model_messaging->{to} = { users => $notification->{$template}->{TO} } if (exists $notification->{$template}->{TO}) ;
                    $model_messaging->{cc} = { users => $notification->{$template}->{CC} } if (exists $notification->{$template}->{CC}) ;
                    $model_messaging->{bcc} = { users => $notification->{$template}->{BCC} } if (exists $notification->{$template}->{BCC}) ;
                    
                    $model_messaging->{vars} = {%$topic,%$stash};
                    $model_messaging->{vars}->{subject} = $subject;
                    $model_messaging->{vars}->{to} = { users => $notification->{$template}->{TO} } if (exists $notification->{$template}->{TO}) ;
                    $model_messaging->{vars}->{cc} = { users => $notification->{$template}->{CC} } if (exists $notification->{$template}->{CC}) ;
                    $model_messaging->{vars}->{bcc} = { users => $notification->{$template}->{BCC} } if (exists $notification->{$template}->{BCC}) ;
                        
                    my $rc_notify = 0;
                    my $err = '';
                    try {
                        Baseliner->model( 'Messaging' )->notify(%{$model_messaging});
                    } catch {
                        $err = shift;   
                        $rc_notify = 1;
                        $rc += $rc_notify;
                    };
                    
                    mdb->event_log->insert({
                        id=>mdb->seq('event_log'), id_event=> $ev->{id}, stash_data=> _dump( $model_messaging ), return_code=>$rc_notify, 
                        log_output => $err, dsl=>'',
                    });
                }
            }

            $event_status= $rc ? 'ko' : 'ok';
            mdb->event->update( {id => $ev->{id}}, {'$set'=>{event_status=>$event_status}});
        } catch {
            my $err = shift;
            # TODO global error or a rule by rule (errors go into rule, but event needs a global) 
            _error _loc 'event %1 failed (id=%2): %3', $ev->{event_key}, $ev->{id}, $err;
            if( $err =~ m/^alarm/s ) {
                alarm 0;
                $event_status = 'timeout';
            } else {
                $event_status = 'ko';
            }
            mdb->event->update( {id => $ev->{id}}, {'$set'=>{event_status=>$event_status}});
        };
        _debug _loc 'Finished event %1 (id %2), status: %3', $ev->{event_key}, $ev->{id}, $event_status;
    }
}

1;
