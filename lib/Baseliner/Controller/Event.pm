package Baseliner::Controller::Event;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

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
    $sort ||= 'me.id';
    $dir ||= 'desc';
    $start||= 0;
    $limit ||= 30;

    my $page = to_pages( start=>$start, limit=>$limit );
    
    my $where={};
    $query and $where = query_sql_build( query=>$query, fields=>[qw(id event_key )] );
    my $rs = DB->BaliEvent->search($where, 
        { page => $page, rows => $limit,
            #prefetch => [{ 'rules' => 'rule' }],
          select => [qw(id mid event_key event_status ts username)], # everything but event_data
          order_by => { "-$dir" => $sort }, 
        }
    );
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;
    my $k = 1;
    my @rows = $rs->hashref->all;
    my @eventids = map { $_->{id} } @rows;
    my @rule_data =
        DB->BaliEventRules->search( { id_event => \@eventids }, { prefetch=>'rule', select => [qw(id id_event id_rule return_code ts)] } )
        ->hashref->all;
    my @final;
    EVENT: for my $e ( @rows ) {
        # event_key event_status event_data 
        delete $e->{event_data};
        my $ev = try { $c->registry->get( $e->{event_key} ) } catch { next EVENT; };
        $e->{description} = $ev->description;
        $e->{_id}         = $e->{id};
        $e->{_parent}     = undef;
        $e->{type}        = 'event';
        $e->{id_event}    = $e->{id};
        my $rules = [ grep { $_->{id_event} == $e->{id} } @rule_data ];
        my @rules = map {
            my $rule = $_;
            +{
                %$rule, 
                _parent       => $e->{_id},
                _id           => $e->{_id} . '-' . $k++,  # $rule->{id} useless and may repeat
                _is_leaf      => \1,
                id_rule_log   => $rule->{id},
                event_status  => $rule->{return_code} ? 'ko' : 'ok',
                type          => 'rule',
                event_key     => $rule->{rule} && $rule->{rule}{id}
                    ? _loc('rule: %1', $rule->{rule}{id} . ': ' . $rule->{rule}{rule_name} )
                    : _loc("Notifications"),
            }
        } @$rules;
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
    my $rs = defined $p->{id}
        ? DB->BaliEvent->find( $p->{id} )
        : DB->BaliEvent->search({ id=>$p->{ids} });
    if( $rs ) {
        $rs->delete;
        $c->stash->{json} = { success=>\1, msg => _loc('Event deleted ok') };
    } else {
        $c->stash->{json} = { success=>\1, msg => _loc('Event not found') };
    }
    $c->forward("View::JSON");
}

sub status : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $rs = defined $p->{id}
        ? DB->BaliEvent->find( $p->{id} )
        : DB->BaliEvent->search({ id=>$p->{ids} });
    if( $rs ) {
        $p->{event_status} or _fail 'Missing status';
        $rs->update({ event_status => $p->{event_status} });
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
                ? DB->BaliEventRules->search({ id=>$id },{ select=>'stash_data' })->hashref->first 
                : DB->BaliEvent->search({ id=>$id }, { select=>'event_data' })->hashref->first; 
            $data = $p->{id_rule_log} ? $row->{stash_data} : $row->{event_data} if $row;
        }
        when( 'dsl' ) {
            my $row = DB->BaliEventRules->search({ id=>$id }, { select=>'dsl' })->hashref->first;
            $data = $row->{dsl} if $row;
        }
        when( 'output' ) {
            my $row = DB->BaliEventRules->search({ id=>$id }, { select=>'log_output' })->hashref->first;
            $data = $row->{log_output} if $row;
        }
    }
    $c->stash->{json} = { success=>\1, data=>$data };
    $c->forward("View::JSON");
}
1;
