package BaselinerX::Job::Service::ApprovalCheck;
=head1 DESCRIPTION

Daemon that checks the approval status of a job. 

If approved, job goes READY to start. 

If rejected, job is CANCELled and reason reported. 

=cut

use Baseliner::Plug;
use Baseliner::Utils;
use utf8;
use Baseliner::Core::DBI;
use BaselinerX::Job::Log;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.job.approval.check' => { name => 'Job Approval Check Daemon', config => 'config.job.approval.check', handler => \&run, };
register 'service.job.approval.check_once' => { name => 'Job Approval Check', config => 'config.job.approval.check', handler => \&run_once, };

register 'config.job.approval.check' => {
    name => 'Job Approval Check Daemon Configuration',
    metadata => [
        { id=>'frequency', name=>'Job Approval Check Frequency', default=>20 },
        { id=>'actions', name=>'Job Approval Check Actions', type=>'array', default=>'action.manualdeploy.role,action.job' },
    ]
};

sub run {
    my ( $self, $c, $config ) = @_;
    my $frequency = $config->{frequency};
    _log 'Job approval check starting.';
    for( 1..1000 ) {
        $self->run_once( $c, $config );
        sleep $frequency;
    }
    _log 'Job approval check stopping.';
}

sub run_once {
    my ( $self, $c, $config ) = @_;

    # jobs awaiting approval
    my $rs = Baseliner->model('Baseliner::BaliJob')->search({ status=>'APPROVAL' }, { order_by=>{ -asc => 'starttime' } });
    my $final_status;
    my ($job_status, $job_req_status, $job_req_who );
    
    # check job by job
    while( my $job = $rs->next ) {
        my $final_status = 'init';
        my $comment=undef;
        _debug "Checking job ". $job->name;
        my @items = map { $_->item } $job->bali_job_items->all;
        my %approvers;
        my $logger = new BaselinerX::Job::Log({ jobid=>$job->id });
        my @log_me; # deferred logging

        # check job approval
        my $ns = 'job/'. $job->name;
        my $job_req_status = $job->request_status;
        
        foreach my $action (_array $config->{actions}) {
            _log "Checking action: " . $action;
            my $rs = Baseliner->model('Baseliner::BaliRequest')->search(
				{ 
				action=>{-like=>"$action.%" }, 
				status=>{ '<>' => 'cancelled' }, 
				ns=>$ns
				}, { 
				prefetch=>['my_comment'],
				order_by => { -desc => 'me.id' }
				}
			);
            while ( my $req=$rs->next ) {
                # get the last approval status for the job
                # my $req = $reqs->first;
                if( ref $req ) {
                    try { $comment .= $req->finished_by.": ".$req->my_comment->text."\n"; } catch {_log ("no comment for " . $req->id)};
                    my $status = $req->status;
                    $job_status = $req->status;
                    my $job_req_who = $req->finished_by;
                    if( $status eq 'pending' ) {
                        $final_status = 'pending';
                    } elsif( $status eq 'approved' ) {
                        $final_status = $final_status =~ m{init|approved}?'approved':$final_status;
                    } elsif( $status eq 'rejected' ) {
                        $final_status = 'rejected';
                        # Cancelamos las request pending del pase rejected
                        my $rs=Baseliner->model('Baseliner::BaliRequest')->search({ ns=>$ns, status=>'pending' });
                        while (my $rec=$rs->next) {
                            $rec->cancel;
                        }   
                        last;
                    } elsif( $status eq 'cancelled' ) {
                        $final_status = 'cancelled';
                        # Cancelamos las request pending del pase rejected
                        my $rs=Baseliner->model('Baseliner::BaliRequest')->search({ ns=>$ns, status=>'pending' });
                        while (my $rec=$rs->next) {
                            $rec->cancel;
                        }   
                        last;
                    } else {
                        $final_status = $status;
                    }
                } else {
                    _log _loc("No $action requests for job %1", $job->name );
                    $final_status = $final_status eq 'no request'?'no requests':$final_status;
                }
                _log _loc("Job %1 status after action %2: '%3'", $job->name, $action, $final_status );
            }
            last if $final_status =~ m{rejected|cancelled};
        }
        _log _loc("Job %1 status: '%3'", $job->name, $final_status );
        
        # for each job item 
        if( $final_status eq 'no requests' || $final_status eq 'approved' ) {
            foreach my $item ( @items ) {
                # get the item job status
                my $rs = Baseliner->model('Baseliner::BaliRequest')->search(
					{ 
					ns=>$item, 
					status=>{ '<>' => 'cancelled' } 
					}, { 
					prefetch=>['my_comment'],
					order_by => { -desc => 'me.id' }
					}
				);
                $final_status = 'no requests';
                while (my $req=$rs->next) {
                    try { $comment .= $req->finished_by.": ".$req->my_comment->text."\n"; } catch {_log ("no comment for " . $req->id)};
                    $approvers{$item} = { 
                        _loc('result') => _loc($req->status),
                        _loc('who')    => $req->finished_by,
                    };
                    if( $req->status eq 'pending' ) {
                        $final_status = $req->status;
                        push @log_me, [ 'warn' => _loc('Pase tiene elementos no aprobados: %1', $item ), data=>_dump(\%approvers) ]; 
                        last;
                    } elsif( $req->status eq 'rejected' ) {
                        $final_status = $req->status;
                        
                        push @log_me, [ 'error' =>  _loc('Pase tiene elementos rechazados: %1', $item ), data=>_dump(\%approvers) ]; 
                        last;
                    } elsif( $req->status eq 'approved' ) {
                        $final_status = $req->status;
                    }
                }
            }
        }

        _debug ">>> FINAL_STATUS: $final_status";
        # avoid message repetition
        if( defined $job_req_status && ( $job_status eq $job_req_status || $final_status eq $job_req_status ) ) {
            _debug _loc("Job %1 status '%2' is the same as last '%3'. Approval checking skipped.", $job->name, $job_status, $job_req_status );
            next;   
        }
        # used by the next iteration, to avoid repeated log messages
        $job->request_status( $final_status ); 
        $job->update;
        # deferred logging
        foreach my $logm ( @log_me ) {
            my $lev = shift @$logm;
            $logger->$lev( @$logm );
        }

        $logger->info(_loc('Status de aprobación de Pase: %1', _loc($job_status) ) );

        if( $final_status eq 'approved' ) {
            $logger->info('Pase aprobado. Se reactiva el pase.<br> Ver anexo para más información', $comment );
            $job->status('READY');
            $job->update;
        }
        elsif( $final_status =~ m/rejected|cancelled/i ) {
            $logger->warn('Pase rechazado/cancelado. Se cancela el pase.<br> Ver anexo para más información', $comment );
            Baseliner->model('Jobs')->reject( id=>$job->id );
        }
        elsif( $final_status eq 'no requests' ) {
            $logger->info('No hay peticiones pendientes. Se reanuda el pase.<br> Ver anexo para más información', $comment );
            $job->status('READY');
            $job->update;
        }
    }
}

1;
