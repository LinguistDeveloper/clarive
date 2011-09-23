package Baseliner::Controller::Daemon;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use Carp;
use Try::Tiny;
use Proc::Exists qw(pexists);

BEGIN { extends 'Catalyst::Controller' }

register 'menu.admin.daemon' => { label => 'Daemons', url_comp=>'/daemon/grid', title=>'Daemons', icon=>'/static/images/daemon.gif' };

sub grid : Local {
    my ( $self, $c ) = @_;
	$c->stash->{template} = '/comp/daemon_grid.mas';
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

sub dispatcher : Local {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
    my $action = $p->{action};
    #TODO control the dispatcher
}

1;



