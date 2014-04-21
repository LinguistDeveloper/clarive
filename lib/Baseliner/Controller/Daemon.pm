package Baseliner::Controller::Daemon;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use DateTime;
use Carp;
use Try::Tiny;
use Proc::Exists qw(pexists);
use v5.10;
BEGIN { extends 'Catalyst::Controller' }

register 'action.admin.daemon' => { name => 'Administer daemons'};
register 'menu.admin.daemon' => { label => 'Daemons', url_comp=>'/daemon/grid', title=>'Daemons', icon=>'/static/images/daemon.gif', action => 'action.admin.daemon'};

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/daemon_grid.js';
}

sub list : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $start ||= 0;
    $limit ||= 100;
    $sort||='service';
    $dir||='asc';

    if($dir =~ /asc/i){
        $dir = 1;
    }else{
        $dir = -1;
    }
    
    my @rows;
    my $where = $query ? mdb->query_build(query => $query, fields=>[qw(service hostname)]) : {};
    my $rs = mdb->daemon->find($where);
    $rs->sort($sort ? { $sort => $dir } : {service => 1});
    $rs->limit($limit);
    $rs->skip($start);
    $cnt = mdb->daemon->count($where);
    while( my $r = $rs->next ) {
        $r->{exists} = pexists( $r->{pid} ) if $r->{pid} > 0;
        $r->{exists} = -1 if $r->{pid} == -1 ;
        $r->{exists} = 1 if $r->{pid} > 0 ;
        $r->{id} = $r->{_id}.'';
        delete $r->{_id};
        push @rows, $r
    }
    $c->stash->{json} = { totalCount=>$cnt, data=>\@rows };
    $c->forward('View::JSON');
}

sub start : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    $c->model('Daemons')->request_start_stop( action=>'start', id=>$p->{id} );
    $c->stash->{json} = { success => \1, msg => _loc('Daemon started') };
    $c->forward('View::JSON');
}

sub stop : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    $c->model('Daemons')->request_start_stop( action=>'stop', id=>$p->{id} );
    $c->stash->{json} = { success => \1, msg => _loc('Daemon stopped') };
    $c->forward('View::JSON');
}


sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    #my $id_daemon = $p->{id};

    given ($action) {
    when ('add') {
        try{
            my $daemon = mdb->daemon->insert({
                    service => $p->{service},
                    hostname => $p->{hostname},
                    active  => $p->{state},
                    last_ping => mdb->ts,
                });
            
            $c->stash->{json} = { msg=>_loc('Daemon added'), success=>\1, daemon_id=> $daemon.'' };
        }
        catch{
            $c->stash->{json} = { msg=>_loc('Error adding Daemon: %1', shift()), failure=>\1 }
        }
    }
    when ('update') {
        try{
            my $id_daemon = $p->{id};
            my $daemon = mdb->daemon->update(
                {_id => mdb->oid($id_daemon)},
                {   '$set' => { 
                        hostname => $p->{hostname},
                        active => $p->{state},
                        last_ping => mdb->ts,
                    }
                });
            $c->stash->{json} = { msg=>_loc('Daemon modified'), success=>\1, daemon_id=> $id_daemon.'' };
        }
        catch{
            $c->stash->{json} = { msg=>_loc('Error modifying Daemon: %1', shift()), failure=>\1 };
        }
    }
    when ('delete') {
        my $id_daemon = $p->{id};
        
        try{
            my $row = mdb->daemon->remove({_id => mdb->oid($id_daemon)});
    
            $c->stash->{json} = { success => \1, msg=>_loc('Daemon deleted') };
        }
        catch{
            $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Daemon') };
        }
    }
    }
    
    $c->forward('View::JSON');
}

sub dispatcher : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    #TODO control the dispatcher
}

1;



