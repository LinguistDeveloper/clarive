package Baseliner::Controller::Event;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;
use experimental 'switch';

BEGIN {  extends 'Catalyst::Controller' }

register 'action.admin.event' => { name=>'Admin Events' };

register 'menu.admin.events' => {
    label    => 'Events',
    title    => _loc ('Events'),
    action   => 'action.admin.event',
    url_comp => '/comp/events.js',
    icon     => '/static/images/icons/event.png',
    tab_icon => '/static/images/icons/event.png'
};


sub list : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my @rows;
    foreach my $key ( $c->registry->starts_with( 'event' ) ) {
        my $ev = Baseliner::Core::Registry->get( $key );
        push @rows, {
            name        => $ev->name // $key,
            key         => $key,
            description => $ev->description,
            type        => $ev->type // 'none',
        };
    }
    $c->stash->{json} = { data => [ sort { uc $a->{ev_name} cmp uc $b->{ev_name} } @rows ], totalCount=>scalar @rows };
    $c->forward("View::JSON");
}

sub log : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= '_id';
    $dir ||= 'desc';
    $start||= 0;
    $limit ||= 30;
    my $where={};
    $query and $where = mdb->query_build( query=>$query, fields=>[qw(id event_key )] );
    my $rs = mdb->event->find($where)->fields({event_data => 0});
    $cnt = $rs->count;
    $rs->skip($start)->sort({ $sort=>$dir =~ /desc/i ? -1 : 1 });
    $rs->limit($limit) unless $limit eq '-1';
    my @rows = $rs->all;
    my @eventids = map { $_->{id} } @rows;
    my %rule_log;
    for( mdb->event_log->find({ id_event => mdb->in(@eventids) })->all ) {
        push @{ $rule_log{$_->{id_event}} }, $_;
    }
    my $all_rules = +{ map{ $_->{id} => $_ } mdb->rule->find->fields({ id=>1, rule_name=>1 })->all }; 
    my @final;
    EVENT: for my $e ( @rows ) {
        # event_key event_status event_data 
        delete $e->{event_data};
        my $desc = cache->get('event:'.$e->{event_key});
        if ( !$desc ) {
            try {
                my $ev = $c->registry->get( $e->{event_key} );
                $desc = $ev->description;
                cache->set( 'event:' . $e->{event_key}, $ev->description );
            }
            catch {
                 _error( shift() ); 
                next EVENT; };
        } ## end if ( !$ev )
        $e->{description} = _loc($desc);
        $e->{_id}         = $e->{id};
        $e->{_parent}     = undef;
        $e->{type}        = 'event';
        $e->{id_event}    = $e->{id};
        # now get the log (event_log)
        my $k = 1;
        my $log_entries = $rule_log{ $e->{id} } // [];
        my @rules = map {
            my $log = $_;
            my $rule = $all_rules->{$log->{id_rule}} if exists $log->{id_rule};
            +{
                %$log, 
                _parent       => $e->{_id},
                _id           => $e->{_id} . '-' . $k++,  # $rule->{id} useless and may repeat
                _is_leaf      => \1,
                id_rule_log   => $log->{id},
                event_status  => $log->{return_code} ? 'ko' : 'ok',
                type          => 'rule',
                event_key     => $rule 
                    ? _loc('rule: [%1] %2', $rule->{id}, $rule->{rule_name} )
                    : _loc("Notifications"),
            }
        } @$log_entries;
        $e->{_is_leaf} = @rules ? \0 : \1;
        push @final, ($e, @rules );
    }
    #_error \@rows;
    $c->stash->{json} = { data => \@final, totalCount=>$cnt };
    $c->forward("View::JSON");
}

sub del : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $rows = defined $p->{id}
        ? [ mdb->event->find_one({ id=>$p->{id} },{ id=>1 }) ]
        : [ mdb->event->find({ id=>mdb->in($p->{ids}) })->fields({ _id=>1 })->all ];
    if( @$rows ) {
        mdb->event->remove($_) for @$rows;
        $c->stash->{json} = { success=>\1, msg => _loc('Event(s) deleted ok') };
    } else {
        $c->stash->{json} = { success=>\1, msg => _loc('Event not found') };
    }
    $c->forward("View::JSON");
}

sub status : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $rows = defined $p->{id}
        ? [ mdb->event->find_one({ id=>$p->{id} }) ]
        : [ mdb->event->find({ id=>mdb->in($p->{ids}) })->all ];
    if( @$rows ) {
        $p->{event_status} or _fail 'Missing status';
        for( @$rows ) {
            $_->{event_status} = $p->{event_status};
            mdb->event->save( $_ );
        }
        $c->stash->{json} = { success=>\1, msg => _loc('Event status changed to: %1', $p->{event_status} ) };
    } else {
        $c->stash->{json} = { success=>\1, msg => ''.shift() };
    }
    $c->forward("View::JSON");
}

sub event_data : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $type = $p->{type};
    my $data='';
    my $id = $p->{id_rule_log} || $p->{id_event};
    given( $type ) {
        when( 'stash' ) {
            my $row = $p->{id_rule_log} 
                ? mdb->event_log->find_one({ id=>$id },{ stash_data=>1 })
                : mdb->event->find_one({ id=>$id }, { event_data=>1 });
            $data = $p->{id_rule_log} ? $row->{stash_data} : $row->{event_data} if $row;
        }
        when( 'dsl' ) {
            my $row = mdb->event_log->find_one({ id=>$id }, { dsl=>1 });
            $data = $row->{dsl} if $row;
        }
        when( 'output' ) {
            my $row = mdb->event_log->find_one({ id=>$id }, { log_output=>1 });
            $data = $row->{log_output} if $row;
        }
    }
    $c->stash->{json} = { success=>\1, data=>$data };
    $c->forward("View::JSON");
}
no Moose;
__PACKAGE__->meta->make_immutable;

1;
