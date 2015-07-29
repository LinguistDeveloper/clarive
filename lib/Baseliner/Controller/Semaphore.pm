package Baseliner::Controller::Semaphore;
use Moose;
use Baseliner::Core::Registry ':dsl';
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

register 'action.admin.semaphore' => { name => 'Semaphore Administration' };
register 'menu.admin.semaphore' => {
    label => 'Semaphores', url_comp=>'/semaphore/grid', title=>'Semaphores', icon=>'/static/images/icons/semaphore.gif',
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
        my $id = $params->{id} or _throw 'Missing id';
        my $status = $params->{status} or _throw 'Missing status parameter';
        my $from_status = { granted=>'waiting', cancelled=>'waiting' };
        my $sem = $params->{sem};
        my $who = $params->{who};
        my $res = mdb->sem->update({ 'queue._id'=>mdb->oid($id), 'queue.status'=>mdb->in($from_status->{$status}) },{  '$set'=>{ 'queue.$.status'=>$status } });
        _fail _loc 'Semaphore not found or status changed from %1', $status unless $res->{updateExisting};
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
    $start||=0;
    $sort||='key';
    $dir = $dir && uc $dir eq 'DESC' ? -1 : 1;
    my $where = { internal=>mdb->nin(1,'1',undef) };
    $query and $where = mdb->query_build(
        query  => $query,
        fields => {
            key => 'key',
        }
    );
    my @rows;
    my $rs = mdb->sem->find( $where )->sort({ $sort => $dir })->limit(100);
    while( my $r = $rs->next ) {
        if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) ) {
            $r->{waiting} = mdb->sem_queue->find({ key=>$r->{key}, status=>'waiting' })->all;
            $r->{busy} = mdb->sem_queue->find({ key=>$r->{key}, status=>'busy' })->all;
            $r->{id} = '' . delete $r->{_id};
            push @rows, $r;
            
        }
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
    $sort||='key';
    $limit ||= 50;
    my $where = {};
    $query and $where = mdb->query_build( query=>$query, fields=>{
        key      =>'key',
        who      =>'who',
        pid      =>'pid',
        status   =>'status',
    });
    my @rows;
    $where = {};
    $where->{'$and'}= [{ queue=>{'$exists'=>1} },{ queue=>{'$ne'=>[]} } ];
    
    my $rs = mdb->sem->find( $where )->sort(mdb->ixhash( key=>1 ));
    $rs->skip( $start ) if length $start;
    $rs->limit( $limit ) if length $limit;
    while( my $doc = $rs->next ) {
        for my $r ( sort { $$a{seq}<=>$$b{seq} } _array( $doc->{queue} ) ) {
            $r->{who} ||= $r->{caller};
            $r->{id} = '' . delete $r->{_id};
            $r->{wait_time} = $$r{ts_grant} && $$r{ts_request} ? (Class::Date->new($r->{ts_grant}) - Class::Date->new($r->{ts_request}))->second . 's': '';
            $r->{run_time} = $$r{ts_release} && $$r{ts_grant} ? (Class::Date->new($r->{ts_release}) - Class::Date->new($r->{ts_grant}))->second . 's' : '';
            push @rows, $r;
        }
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

    - key

    And one of the two:

    - action: add (+1), del (-1)
    - slots: the slot number

=cut
sub change_slot  : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $sem;
    try { 
        if( $p->{action} eq 'add' ) {
            $sem = mdb->sem->find_and_modify({ query=>{ key=>$p->{key} }, update=>{ '$inc'=>{ maxslots=>1 } }, new=>1 });
        }
        elsif( $p->{action} eq 'del' ) {
            $sem = mdb->sem->find_and_modify({ query=>{ key=>$p->{key} }, update=>{ '$inc'=>{ maxslots=>-1 } }, new=>1 });
        }
        $sem or _fail _loc 'Semaphore not found %1', $p->{key};
        $c->stash->{json} = { message=>_loc("Semaphore %1 slots changed to %2", $p->{key}, $sem->{maxslots}) };
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
    my ($to,$to_queue);
    my $id_from = $p->{id_from} or _throw _loc("Missing parameter id from");
    my $id_to  = $p->{id_to} or _throw _loc("Missing parameter id to");
    try { 
        # switch sequences
        $to = mdb->sem->find_and_modify({ 
                query=>{ queue=>{'$elemMatch'=>{_id=>mdb->oid($id_to), status=>'waiting'}}}, 
                update=>{ '$set'=>{'queue.$.seq'=>-1} } });
        _fail _loc 'Destination semaphore does not exist. Please, refresh' unless $to;
        ($to_queue) = grep { "$$_{_id}" eq $id_to } _array( $to->{queue} );
        _fail _loc 'Destination semaphore does not exist. Please, refresh' unless $to_queue;
        
        my $from = mdb->sem->find_and_modify({ 
                query=>{ queue=>{ '$elemMatch'=>{ _id=>mdb->oid($id_from), status=>'waiting' }}}, 
                update=>{ '$set'=>{'queue.$.seq'=>$to_queue->{seq}} } });
        _fail _loc 'Source semaphore does not exist. Please, refresh' unless $from;
        my ($from_queue) = grep { "$$_{_id}" eq $id_from } _array( $from->{queue} );

        mdb->sem->update({ 'queue._id'=>mdb->oid($id_to) },{ '$set'=>{'queue.$.seq'=>$from_queue->{seq} } });
        $c->stash->{json} = { message=>_loc("Semaphore queue precedence changed to %2", $p->{action} ) };
    } catch {
        my $err = shift;
        # if we updated to -1, let's reset back
        mdb->sem->update({ 'queue._id'=>mdb->oid($id_to) },{ '$set'=>{'queue.$.seq'=>$to_queue->{seq} } }) if $to_queue;
        $c->stash->{json} = { message=>$err };
    };
    $c->forward('View::JSON');
}

sub purge : Local {
    my ( $self, $c ) = @_;
    try {
        # Baseliner::Sem->purge_all;
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
        my $q = mdb->sem_queue->find_one({ _id=>mdb->oid($p->{id}) });
        _throw _loc "Error: Semaphore is already busy." if $q->{status} !~ m/waiting|idle/;
        $q->{active} = 0+$p->{active} ;
        mdb->sem_queue->save( $q );
        my $msg = $p->{active} ? _loc('Semaphore request active') : _loc('Semaphore request inactive');
        $c->stash->{json} = { message=>$msg };
    } catch {
        $c->stash->{json} = { message=>shift };
    };
    $c->forward('View::JSON');
}

1;


