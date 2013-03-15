package Baseliner::Controller::Notification;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

register 'menu.admin.notifications' => {
    label    => 'Notifications',
    title    => _loc ('Notifications'),
    action   => 'action.notification.admin',
    url_comp => '/comp/notifications.js',
    icon     => '/static/images/log_w.gif',
    tab_icon => '/static/images/log_w.gif'
};

register 'action.notification.admin' => { name=>'Admin Notifications' };

sub list_notifications : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'me.id';
    $dir ||= 'desc';
    $start||= 0;
    $limit ||= 30;
    
    my $page = to_pages( start=>$start, limit=>$limit );
    
    my $where={};
    $query and $where = query_sql_build(
        query   => $query,
        fields  => [qw( id id_event action dest_to dest_cc dest_bcc event_scope is_active
                        username, template_path, digest_time, digest_date, digest_freq)]
    );
    
    my $rs = DB->BaliNotification->search($where, 
        { page => $page, rows => $limit,
          order_by => { "-$dir" => $sort }, 
        }
    );
    
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;
    my @rows = $rs->hashref->all;
    
    $c->stash->{json} = { data => \@rows, totalCount=>$cnt };
    $c->forward("View::JSON");
}

sub list_events : Local {
    my ( $self, $c ) = @_;
    my @events = map { +{key => $_}} Baseliner->registry->starts_with('event.');
    #my @events = Baseliner->registry->starts_with('event.');
    
    $c->stash->{json} = \@events;
    $c->forward('View::JSON');
}

sub list_actions : Local {
    my ( $self, $c ) = @_;
    my @actions = map {+{action => $_,  checked => $_ eq 'SEND' ? \1: \0}} ('SEND','EXCLUDE');
    
    $c->stash->{json} = \@actions;
    $c->forward('View::JSON');
}

sub list_carriers : Local {
    my ( $self, $c ) = @_;
    my @carriers = map {+{carrier => $_}} ('TO','CC','BCC');
    
    $c->stash->{json} = \@carriers;
    $c->forward('View::JSON');
}

sub list_type_recipients : Local {
    my ( $self, $c ) = @_;
    my @recipients = map {+{type_recipient => $_}} ('Default','Users','Roles','Groups','Emails','Actions');
    
    $c->stash->{json} = \@recipients;
    $c->forward('View::JSON');
}

sub get_recipients : Local {
    my ( $self, $c, $type ) = @_;
    
    try{
        my @recipients;
        my $obj;
        given ($type) {
            when ('Users') {
                $obj = 'combo';
                @recipients = map {+{id => $_->{username}, name => $_->{username}, description => $_->{realname} ? $_->{realname}:''  }}
                            Baseliner->model('Baseliner::BaliUser')->search(undef,{select=>['username','realname'], order_by=>{-asc=>['realname']}})->hashref->all;
                
            }
            when ('Roles') {
                $obj = 'combo';
                @recipients = map {+{id => $_->{id}, name => $_->{role}, description => $_->{description} ? $_->{description}:''  }} 
                            Baseliner->model('Baseliner::BaliRole')->search(undef,{select=>['id','role','description'], order_by=>{-asc=>['role']}})->hashref->all;
            }
            when ('Emails') {
                $obj = 'textfield';
                @recipients = ({id => 'Emails', name => 'Emails'});
            }            
        }
        $c->stash->{json} = { data=> \@recipients, obj=> $obj ,success=>\1 };
    }catch{
        $c->stash->{json} = { msg=> _loc('Se ha producido un error'), success=>\0 };
    };
    $c->forward('View::JSON');
}

sub get_scope : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    
    try{
        my $scope;
        if (Baseliner->registry->get( $p->{key} )->notify){
            $scope =  Baseliner->registry->get( $p->{key} )->notify->{scope};
        }
        $c->stash->{json} = { data => $scope, success=>\1 }; 
    }catch{
        $c->stash->{json} = { msg=> _loc('Se ha producido un error'), success=>\0 };
    };
    
    $c->forward('View::JSON');
}

1;
