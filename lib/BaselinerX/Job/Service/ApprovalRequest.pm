package BaselinerX::Job::Service::ApprovalRequest;
=head1 DESCRIPTION

This is a service designed to be chained in PRE, that checks if a job needs approval before running in RUN.

If it does, sends the request to users with action.job.approve permissions. 

A parallel daemon job, ::ApprovalCheck, takes cares of putting the job in motion again after it's approved.

=cut 

use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'action.job.approve' => { name=>_loc('Approve jobs') };

register 'service.job.approval.request' => { name => 'Job Approval Request', config => 'config.job.runner', handler => \&run, };

register 'config.job.approve' => {
    metadata=>[
        { id=>'enabled', label=>'Active for Baseline', type=>'bool', default=>1 },
    ]
};

sub run {
    my ( $self, $c, $config ) = @_;
   
    my $job = $c->stash->{job};
    my $log = $job->logger;

    my $bl = $job->job_data->{bl};
    $log->debug( _loc('Checking if job approval needed in %1', $bl) );
    
    my $reason;
    my $approval_items;

    # check the job stash
    my $job_approve = $job->job_stash->{approval_needed};
    
    unless( ref $job_approve ) {
        $log->info( _loc("No hay aprobaciones programadas para este pase.") );
        return;
    }

    $reason = $job_approve->{reason};
    $log->debug( 'Aprobación requerida en stash de pase', data=>_dump( $job_approve ) );

    # check the config : this has precedence
       # my $config_approve = Baseliner->model('ConfigStore')->get('config.job.approve', bl=>$bl);
    # unless( $config_approve->{enable} ) {
        # $log->info( _loc('No hay aprobaciones para esta linea base %1', $bl ) );
        # return;
    # }
    
    $approval_items ||= $job->job_stash->{contents}; 
    $reason ||= "Promoción a $bl";
    
    my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d&annotate_now=1", _notify_address(), $job->jobid );

    #my $item_ns = 'endevor.package/' . $item->{item};   #TODO get real ns names
    $log->info( _loc('Requesting approval for job %1, baseline %2: %3', $job->name, $bl, $reason ) );
    try {
        Baseliner->model('Request')->request(
            name   => _loc("Aprobación del Pase %1", $job->name),
            action => 'action.job.approve',
            template_engine => 'mason',
            template => '/email/approval_job.html',
            username     => $job->job_data->{username},
            comments_job => $job->job_data->{comments},
            ns           => 'job/' . $job->name,
            bl           => $bl, 
            id_job       => $job->jobid,
            vars         => {
                jobname  => $job->name,
                reason   => $reason,
                comments => $job->job_data->{comments},
                url_log  => $url_log,
            },
        );
        my $job_row = $c->model('Baseliner::BaliJob')->find({ id=>$job->jobid });
        $log->debug( 'Cambiando status a APPROVAL' );
        $job->status('APPROVAL');
    } catch {
        my $e = shift;
        $log->info( _loc("El pase '%1' no necesita aprobación (no hay usuarios para aprobarlo)", $job->name ) );
    };
}

1;
