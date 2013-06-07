package Baseliner::Controller::Semaphore;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use Try::Tiny;

=head1 NAME

Baseliner::Controller::Semaphore

=head1 DESCRIPTION

Main Sempahore controller for the admin user interface.

=head1 METHODS

=cut

BEGIN { extends 'Catalyst::Controller' }

register 'action.admin.semaphore' => { label => 'Semaphore Administration' };
register 'menu.admin.semaphore' => {
    label => 'Semaphores', url_comp=>'/semaphore/grid', title=>'Semaphores', icon=>'/static/images/semaphore.gif',
    action=>'action.admin.semaphore'
};

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/sem.js';
}

=head2 change_status

Change the status for a semaphore request.

=cut
sub change_status : Local {
    my ( $self, $c ) = @_;
    my $params = $c->req->params;
    try {
        my $id = $params->{id};
        my $status = $params->{status} or _throw 'Missing status parameter';
        my $q   = $c->model('Baseliner::BaliSemQueue')->find( $id );
        my $sem = $q->sem;
        my $who = $q->who || $q->caller;
        $q->status( $status );
        $q->update;
        $c->stash->{json} = { message=>_loc("Granted semaphore %1 to %2", $sem, $who) };
    } catch {
        $c->stash->{json} = { message=>shift };
    };
    $c->forward('View::JSON');
}

=head2 sems

Returns all existing semaphores JSON.

=cut
sub sems : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort ) = @{$p}{qw/start limit query dir sort/};
    my $cnt;
    $sort||='sem';
    my $where = {};
    $query and $where = query_sql_build( query=>$query, fields=>{
        sem      =>'me.sem',
        bl       =>'me.bl',
    });
    my @rows;
    my $rs = $c->model('Baseliner::BaliSem')->search(
        $where,
        { order_by=>"$sort $dir" }
    );
    #rs_hashref( $rs );
    while( my $r = $rs->next ) {
        push @rows, {
            $r->get_columns, 
            occupied => $r->occupied,
            waiting  => $r->waiting,
        } if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    #@rows = sort { $a->{ $sort } cmp $b->{ $sort } } @rows if $sort;
    $c->stash->{json} = {
        totalCount=>scalar @rows,
        data=>\@rows
    };
    $c->forward('View::JSON');
}

=head2 queue

Return the semaphore queue JSON.

=cut
sub queue : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort ) = @{$p}{qw/start limit query dir sort/};
    my $cnt;
    $sort||='id';
    my $where = {};
    $query and $where = query_sql_build( query=>$query, fields=>{
        sem      =>'me.sem',
        bl       =>'me.bl',
        who      =>'me.who',
        pid      =>'me.pid',
        status   =>'me.status',
    });
    my @rows;
    my $rs = $c->model('Baseliner::BaliSemQueue')->search(
        $where,
        { order_by=>"sem, seq desc, id asc" }
    );
    rs_hashref( $rs );
    while( my $r = $rs->next ) {
        $r->{who} ||= $r->{caller};
        $r->{sem_bl} = $r->{sem} . '-' . $r->{bl};
        push @rows, $r if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    #@rows = sort { $a->{ $sort } cmp $b->{ $sort } } @rows if $sort;
    $c->stash->{json} = {
        totalCount=>scalar @rows,
        data=>\@rows
    };
    $c->forward('View::JSON');
}

=head1 change_slot

Changes the slot size of a semaphore, up, down or by number.

Parameters:

    - bl
    - sem

    And one of the two:

    - action: add (+1), del (-1)
    - slots: the slot number

=cut
sub change_slot  : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    try { 
        my $bl = $p->{bl} || '*';
        my $sem = $c->model('Baseliner::BaliSem')->search({ sem=>$p->{sem}, bl=>$bl })->first; 
        _throw _loc("Semaphore '%1' not found", $p->{sem} ) unless ref $sem;
        if( $p->{action} eq 'add' ) {
            $sem->slots( $sem->slots + 1 );
        }
        elsif( $p->{action} eq 'del' ) {
            $sem->slots( $sem->slots - 1 );
        }
        else {
            $sem->slots( $p->{slots} ) if defined $p->{slots};
        }
        $sem->update;
        $c->stash->{json} = { message=>_loc("Semaphore %1 slots changed to %2", $sem->sem, $sem->slots) };
    } catch {
        $c->stash->{json} = { message=>shift };
    };
    $c->forward('View::JSON');
}

=head2 queue_move

Change the place of a request in the queue, by adding or subtracting 
from the sequence.

=cut
sub queue_move  : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    try { 
        my $id = $p->{id} or _throw _loc("Missing parameter id");
        my $que = $c->model('Baseliner::BaliSemQueue')->find( $id );
        _throw _loc("Semaphore request '%1' not found", $id ) unless ref $que;
        if( $p->{action} eq 'up' ) {
            $que->seq( $que->seq + 1 );
        }
        elsif( $p->{action} eq 'down' ) {
            $que->seq( $que->seq - 1 );
        }
        else {
            _throw _loc("Action %1 not found", $p->{action} );
        }
        $que->update;
        $c->stash->{json} = { message=>_loc("Semaphore %1 precedence changed to %2", $que->sem, $que->seq ) };
    } catch {
        $c->stash->{json} = { message=>shift };
    };
    $c->forward('View::JSON');
}

sub purge : Local {
    my ( $self, $c ) = @_;
    try {
        Baseliner->model('Semaphores')->purge;
        $c->stash->{json} = { message=>_loc("Requests purged") };
    } catch {
        $c->stash->{json} = { message=>shift };
    };
    $c->forward('View::JSON');
}

sub activate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    try {
        defined $p->{id} or _throw _loc "Missing parameter id";
        defined $p->{active} or _throw _loc "Missing parameter active";
        my $q = Baseliner->model('Baseliner::BaliSemQueue')->find( $p->{id} );
        _throw _loc "Error: Semaphore is already busy." if $q->status !~ m/waiting|idle/;
        $q->active( $p->{active} );
        $q->update;
        my $msg = $p->{active} ? _loc('Semaphore request active') : _loc('Semaphore request inactive');
        $c->stash->{json} = { message=>$msg };
    } catch {
        $c->stash->{json} = { message=>shift };
    };
    $c->forward('View::JSON');
}

1;


