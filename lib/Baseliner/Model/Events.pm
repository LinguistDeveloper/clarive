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
        for( 1..1000 ) {
            $self->run_once( $c, $config );
            sleep( $config->{frequency} );
        } 
        # purge old events
        my $dt = _dt->subtract( days => ( $config->{purge_days} || 30 ) );
        $dt =  $dt->strftime('%Y-%m-%d %T');
        DB->BaliEvent->search({ ts => { '<' => $dt }})->delete;
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
    my $rs = DB->BaliEvent->search({ event_status => 'new' }, { order_by =>{ -asc => 'id' } });
    while( my $ev = $rs->next ) {
        my $event_status = '??';
        _debug _loc 'Running event %1 (id %2)', $ev->event_key, $ev->id;
        try {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm $data->{timeout} if $data->{timeout};  # 0 turns off timeout
            my $stash = $ev->event_data ? _load( $ev->event_data ) : {};
            # run rules for this event
            my $ret = $rules->run_rules( event=>$ev->event_key, rule_type=>'event', when=>'post-offline', stash=>$stash, onerror=>1 );
            alarm 0 if $data->{timeout};
            my $rc=0;
            # save log
            for my $rule ( _array( $ret->{rule_log} ) ) {
                my $rulerow = DB->BaliEventRules->create({
                    id_event=> $ev->id, id_rule=> $rule->{id}, stash_data=> _dump( $rule->{ret} ), return_code=>$rule->{rc}, 
                });
                $rc += $rule->{rc} if $rule->{rc};
                $rulerow->dsl( $rule->{dsl} );
                $rulerow->update;
                $rulerow->log_output( $rule->{output} );
                $rulerow->update;
            }
            
            my $event_key = $ev->event_key;
            my $notify_scope = $stash->{notify};
            
            my @notifications = Baseliner->model('Notification')->get_notifications({ event_key => $event_key, notify_scope => $notify_scope });
            
            foreach  my $notification ( @notifications ){
                if ($notification){
                    foreach  my $template (  keys $notification ){
                        my $model_messaging = {
                            subject         => $stash->{subject},
                            sender          => $data->{from},
                            carrier         => 'email',
                            template        => $template,
                            template_engine => 'mason',
                        };
                        $model_messaging->{to} = { users => $notification->{$template}->{TO} } if (exists $notification->{$template}->{TO}) ;
                        $model_messaging->{cc} = { users => $notification->{$template}->{CC} } if (exists $notification->{$template}->{CC}) ;
                        $model_messaging->{bcc} = { users => $notification->{$template}->{BCC} } if (exists $notification->{$template}->{BCC}) ;
                        
                        $model_messaging->{vars} = $stash;
                        $model_messaging->{vars}->{to} = { users => $notification->{$template}->{TO} } if (exists $notification->{$template}->{TO}) ;
                        $model_messaging->{vars}->{cc} = { users => $notification->{$template}->{CC} } if (exists $notification->{$template}->{CC}) ;
                        $model_messaging->{vars}->{bcc} = { users => $notification->{$template}->{BCC} } if (exists $notification->{$template}->{BCC}) ;
                        
                        Baseliner->model( 'Messaging' )->notify(%{$model_messaging});
                        
                        my $rulerow = DB->BaliEventRules->create({
                            id_event=> $ev->id, stash_data=> _dump( $model_messaging ), return_code=>0, 
                        });
                    }
                }
            }

            $event_status= $rc ? 'ko' : 'ok';
            $ev->update({ event_status=>$event_status });
        } catch {
            my $err = shift;
            # TODO global error or a rule by rule (errors go into rule, but event needs a global) 
            _error _loc 'event %1 failed (id=%2): %3', $ev->event_key, $ev->id, $err;
            if( $err =~ m/^alarm/s ) {
                alarm 0;
                $event_status = 'timeout';
            } else {
                $event_status = 'ko';
            }
            $ev->update({ event_status=>$event_status });
        };
        _debug _loc 'Finished event %1 (id %2), status: %3', $ev->event_key, $ev->id, $event_status;
    }
}

1;
