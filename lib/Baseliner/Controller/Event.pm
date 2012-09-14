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
    $limit ||= 100;

    my $page = to_pages( start=>$start, limit=>$limit );
    
    my $where={};
    $query and $where = query_sql_build( query=>$query, fields=>[qw(event_key)] );
    my $rs = DB->BaliEvent->search($where, 
        { page => $page, rows => $limit,
          prefetch => ['rules'],
          order_by => { "-$dir" => $sort }, 
        }
    );
    my $pager = $rs->pager;
    my $cnt = $pager->total_entries;
    my @rows = $rs->hashref->all;
    @rows = map {
        # event_key event_status event_data 
        my $e  = $_;
        my $ev = $c->registry->get( $_->{event_key} );
        $e->{description} = $ev->description;
        $e->{_is_leaf} = \0;
        $e->{_id} = $e->{id};
        $e->{_parent} = undef;
        my $rules = delete $e->{rules};
        my @rules = map {
            +{
                %$_, 
                _parent  => $e->{_id},
                _id      => $_->{id},
                event_key => $_->{rule_name},
                _is_leaf => \1,
            }
        } @$rules;
        ($e, @rules );
    } @rows;
    _error \@rows;
    $c->stash->{json} = { data => \@rows, totalCount=>$cnt };
    $c->forward("View::JSON");
}


1;
