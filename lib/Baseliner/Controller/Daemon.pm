package Baseliner::Controller::Daemon;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use Carp;
use Try::Tiny;
use Proc::Exists qw(pexists);
use v5.10;

BEGIN { extends 'Catalyst::Controller' }

register 'menu.admin.daemon' => { label => 'Daemons', url_comp=>'/daemon/grid', title=>'Daemons', icon=>'/static/images/daemon.gif' };

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
    
    my $page = to_pages( start=>$start, limit=>$limit );
    my @rows;
    my $where = $query
    ? { 'lower(service||hostname)' => { -like => "%".lc($query)."%" } }
    : undef;
    
    my $rs = $c->model('Baseliner::BaliDaemon')->search(  $where,
							{ page => $page,
							  rows => $limit,
							  order_by => $sort ? { "-$dir" => "$sort" } : undef
							}
							);
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    while( my $r = $rs->next ) {
	$r->{exists} = pexists( $r->{pid} ) if $r->{pid} > 0;
	$r->{exists} = -1 if $r->{pid} == -1 ;
	$r->{exists} = 1 if $r->{pid} > 0 ;
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
	        my $daemon = $c->model('Baseliner::BaliDaemon')->create(
						    {
							service	=> $p->{service},
							hostname => $p->{hostname},
							active 	=> $p->{state},
						    });
		    
		$c->stash->{json} = { msg=>_loc('Daemon added'), success=>\1, daemon_id=> $daemon->id };

	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error adding Daemon: %1', shift()), failure=>\1 }
	    }
	}
	when ('update') {
	    try{
		my $id_daemon = $p->{id};
		my $daemon = $c->model('Baseliner::BaliDaemon')->find( $id_daemon );
		$daemon->hostname( $p->{hostname} );
		$daemon->active( $p->{state} );
		$daemon->update();
		$c->stash->{json} = { msg=>_loc('Daemon modified'), success=>\1, daemon_id=> $id_daemon };
	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error modifying Daemon: %1', shift()), failure=>\1 };
	    }
	}
	when ('delete') {
	    my $id_daemon = $p->{id};
	    
	    try{
		my $row = $c->model('Baseliner::BaliDaemon')->find( $id_daemon );
		$row->delete;
	
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



