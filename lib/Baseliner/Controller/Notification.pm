package Baseliner::Controller::Notification;
use Mouse;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

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
        fields  => [qw( id event_key action data is_active username
                    template_path digest_time digest_date digest_freq)]
    );
    
    my $rs = DB->BaliNotification->search($where, 
        { page => $page, rows => $limit,
          order_by => { "-$dir" => $sort }, 
        }
    );
    
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;
    
    my @rows;
    while( my $r = $rs->next ) {
        push @rows, {
            id              => $r->id,
            event_key       => $r->event_key,
            data            => _load($r->data),
            action          => $r->action,
            is_active       => $r->is_active,
            template_path   => $r->template_path
        };        
    }
    
    $c->stash->{json} = { data => \@rows, totalCount=>$cnt };
    $c->forward("View::JSON");
}

sub list_events : Local {
    my ( $self, $c ) = @_;
    my @events = map { +{key => $_}} sort Baseliner->registry->starts_with('event.');
    
    $c->stash->{json} = \@events;
    $c->forward('View::JSON');
}

sub list_actions : Local {
    my ( $self, $c ) = @_;
    my @actions = map {+{action => $_,  checked => $_ eq 'SEND' ? \1: \0}} $c->model('Notification')->get_actions;
    
    $c->stash->{json} = \@actions;
    $c->forward('View::JSON');
}

sub list_carriers : Local {
    my ( $self, $c ) = @_;
    my @carriers = map {+{carrier => $_}} $c->model('Notification')->get_carriers;
    
    $c->stash->{json} = \@carriers;
    $c->forward('View::JSON');
}

sub list_type_recipients : Local {
    my ( $self, $c ) = @_;
    my @recipients = map {+{type_recipient => $_}} $c->model('Notification')->get_type_recipients;
    
    $c->stash->{json} = \@recipients;
    $c->forward('View::JSON');
}

sub get_type_obj_recipients{
    my ( $self, $type ) = @_;
    my $obj;

    given ($type) {
        when ('Default')    { $obj = 'none'; }
        when ('Emails')     { $obj = 'textfield'; }
        when ('Fields')     { $obj = 'textfield'; }
        default             { $obj = 'combo'; }            
    };
    return $obj;
}

sub get_recipients : Local {
    my ( $self, $c, $type ) = @_;
    
    try{
        my $recipients = $c->model('Notification')->get_recipients($type);
        my $obj = $self->get_type_obj_recipients($type);
        $c->stash->{json} = { data => $recipients, obj => $obj ,success => \1 };
    }catch{
        $c->stash->{json} = { msg => _loc('Se ha producido un error'), success => \0 };
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

sub save_notification : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my %scope;
    my $recipient;
    my $data;
    
    try{
        if($p->{event}){
            if (Baseliner->registry->get( $p->{event} )->notify){
                my $scope = Baseliner->registry->get( $p->{event} )->notify->{scope};
        
                map {  $scope{$_} = $p->{$_} ? $p->{$_} eq 'on' ? {'*' => _loc('All')} : _decode_json($p->{$_ . '_names'}) : undef } grep {$p->{$_} ne ''} _array $scope;
            }
        }
        $data->{scopes} = \%scope;
        $data->{recipients} = _decode_json($p->{recipients});
        
        my $notification = Baseliner->model('Baseliner::BaliNotification')->update_or_create(
            {
                id              => $p->{id},
                event_key       => $p->{event},
                action          => $p->{action},
                data            => _dump ($data),
                template_path   => $p->{template}
            }
        );
        
        $c->stash->{json} = { success => \1, msg => 'Notification added', notification_id => $notification->id }; 
    }catch{
        $c->stash->{json} = { success => \0, msg => 'Error adding notification: ' }; 
        _error shift;
    };
    
    $c->forward('View::JSON');
}

sub remove_notifications : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $ids_notification = $p->{ids_notification};

    try{
        my @ids_notification;
        foreach my $id_notification (_array $ids_notification){
            push @ids_notification, $id_notification;
        }
          
        my $rs = Baseliner->model('Baseliner::BaliNotification')->search({ id => \@ids_notification });
        $rs->delete;
        
        $c->stash->{json} = { success => \1, msg=>_loc('Notifications deleted') };
    }
    catch{
        $c->stash->{json} = { success => \0, msg=>_loc('Error deleting notifications') };
    };
    $c->forward('View::JSON');
}

sub change_active : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my @ids_notifications = _array $p->{ids_notification};
    my $action = $p->{action};
    my $msg_active = $action eq 'active' ? 'activated' : 'deactivated';
    
    try{
        my $notification = Baseliner->model('Baseliner::BaliNotification')->search( {id => \@ids_notifications} );
        if( ref $notification ) {
            #$notification->is_active( $action eq 'active' ? 1 : 0 );
            $notification->update({is_active => $action eq 'active' ? 1 : 0 });
            $c->stash->{json} = { success => \1, msg => "Notifications $msg_active" };
        }
        else{
            $c->stash->{json} = { success => \0, msg => 'Error modifying the notification' };
        }
    }
    catch{
        $c->stash->{json} = { success => \0, msg => 'Error modifying the notification' };
    };
    
    $c->forward('View::JSON');
}


sub get_templates : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    
    try{

        # my @templates_dirs; # = map { $_->root . '/email/*.html' } Baseliner->features->list;
        # push @templates_dirs, $c->path_to( 'root/email' ) . '/*.html';

        my $path = $c->path_to;
        my @templates = map { (_file $_)->basename } <$path/root/email/* $path/features/*/root/email/*>;

        @templates = map { +{name => $_, path => "/email/$_" }}  @templates;

        $c->stash->{json} = { data => \@templates, success=>\1 }; 
    }catch{
        $c->stash->{json} = { data => {}, msg=> _loc('Se ha producido un error'), success=>\0 };
    };
    
     $c->forward('View::JSON');
}


1;
