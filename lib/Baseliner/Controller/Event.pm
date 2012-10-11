package Baseliner::Controller::Event;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

register 'menu.admin.events' => {
    label    => 'Events',
    title    => _loc ('Events'),
    action   => 'action.event.admin',
    url_comp => '/comp/events.js',
    icon     => '/static/images/icons/event.png',
    tab_icon => '/static/images/icons/event.png'
};

register 'action.event.admin' => { name=>'Admin Events' };

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
    $query and $where = query_sql_build( query=>$query, fields=>[qw(event_key)] );
    my $rs = DB->BaliEvent->search($where, 
        { page => $page, rows => $limit,
          prefetch => [{ 'rules' => 'rule' }],
          order_by => { "-$dir" => $sort }, 
        }
    );
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;
    my @rows = $rs->hashref->all;
    @rows = map {
        # event_key event_status event_data 
        my $e  = $_;
        my $ev = $c->registry->get( $_->{event_key} );
        $e->{description} = $ev->description;
        $e->{_id} = $e->{id};
        $e->{_parent} = undef;
        $e->{type} = 'event';
        #_error "EV=$e->{event_data}";
        $e->{data} = _damn( _load( $e->{event_data} ) ) if length $e->{event_data};
        my $rules = delete $e->{rules};
        my $k = 1;
        my @rules = map {
            #_error $_->{stash_data};
            +{
                %$_, 
                _parent       => $e->{_id},
                _id           => $e->{_id} . '-' . $k++,  # $_->{id} useless and may repeat
                event_status  => $_->{return_code} ? 'ko' : 'ok',
                type          => 'rule',
                event_key     => _loc('rule: %1', $_->{rule}{id} . ': ' . $_->{rule}{rule_name} ),
                data          => ( $_->{stash_data} ?  _load( $_->{stash_data} ) : {} ),
                dsl           => $_->{dsl},
                output        => $_->{log_output},
                _is_leaf      => \1,
            }
        } @$rules;
        $e->{_is_leaf} = @rules ? \0 : \1;
        ($e, @rules );
    } @rows;
    #_error \@rows;
    $c->stash->{json} = { data => \@rows, totalCount=>$cnt };
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

1;
