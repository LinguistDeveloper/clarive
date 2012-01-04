package Baseliner::Controller::Daemon;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use Carp;
use Try::Tiny;
use Switch;
use Proc::Exists qw(pexists);

BEGIN { extends 'Catalyst::Controller' }

register 'menu.admin.daemon' => { label => 'Daemons', url_comp=>'/daemon/grid', title=>'Daemons', icon=>'/static/images/daemon.gif' };

sub grid : Local {
    my ( $self, $c ) = @_;
	$c->stash->{template} = '/comp/daemon_grid.js';
}

sub list : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
    $sort||='service';
    $dir||='';
    my @rows;
    my $rs = $c->model('Baseliner::BaliDaemon')->search( undef, { order_by=>"$sort $dir" } );
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    while( my $r = $rs->next ) {
    next if( $query && !query_array($query, $r->id, $r->service, $r->hostname ));
    $r->{exists} = pexists( $r->{pid} ) if $r->{pid} > 0;
    $r->{exists} = -1 if $r->{pid} == -1 ;
    $r->{exists} = 1 if $r->{pid} > 0 ;
	    push @rows, $r
	if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    #@rows = sort { $a->{ $sort } cmp $b->{ $sort } } @rows if $sort;
    $c->stash->{json} = {
	    totalCount=>scalar @rows,
	    data=>\@rows
    };
    $c->forward('View::JSON');
}

sub start : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    $c->model('Daemons')->request_start_stop( action=>'start', id=>$p->{id} );
    $c->stash->{json} = { success => \1, msg => _loc("Service started") };
    $c->forward('View::JSON');
}

sub stop : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    $c->model('Daemons')->request_start_stop( action=>'stop', id=>$p->{id} );
    $c->stash->{json} = { success => \1, msg => _loc("Service stopped") };
    $c->forward('View::JSON');
}

sub delete : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $id_daemon = $p->{id};
    
    try{
	##Paramos el servicio antes de borrar en tabla.            ##########################                   
	##En principio no hace nada, solo modifica el campo de la tabla ACTIVE            ###
	##$c->model('Daemons')->request_start_stop( action=>'stop', id=>$p->{id} );       ###
	#####################################################################################
	my $row = $c->model('Baseliner::BaliDaemon')->find( $id_daemon );
	$row->delete;

	$c->stash->{json} = {  success => 1, msg=>_loc('Daemon deleted')};
    }
    catch{
	$c->stash->{json} = {  success => 0, msg=>_loc('Error deleting Daemon') };
    }
    $c->forward('View::JSON');
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    #my $id_daemon = $p->{id};
    
    switch ($action) {
	case 'add' {
	    try{
	        my $daemon = $c->model('Baseliner::BaliDaemon')->create(
						    {
							service	=> $p->{service},
							active 	=> $p->{rb_state} - 1,
						    });
		    
		$c->stash->{json} = { msg=>_loc('Daemon added'), success=>\1, daemon_id=> $daemon->id };

	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error adding Daemon: %1', shift()), failure=>\1 }
	    }
	}
	case 'update' {
	    try{
		#my $project = $c->model('Baseliner::BaliProject')->find( $id_project );
		#$project->name( $p->{name} );
		#$project->id_parent( $p->{id_parent} eq '/'?'':$p->{id_parent} );
		#$project->nature( $p->{nature} );
		#$project->description( $p->{description} );
		#$project->update();
		#$c->stash->{json} = { msg=>_loc('Project modified'), success=>\1, project_id=> $id_project };
	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error modifying Project: %1', shift()), failure=>\1 };
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



