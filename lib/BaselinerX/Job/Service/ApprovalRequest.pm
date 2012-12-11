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
    my $start=parse_dt( '%Y-%m-%d %H:%M',$job->job_data->{starttime} );
    
    #unless( ref $job_approve ) {
    unless( defined $job_approve and defined $job_approve->{reason} ) {  ## evitamos que salte la aprobacion si no estÃ¡ informado reason, se estÃ¡ creando la clave vacia.
        $log->info( _loc("No hay aprobaciones programadas para este pase.") );
        return;
    }



    $reason = $job_approve->{reason};
    $log->debug( 'Approval required by job stash', data=>_dump( $job_approve ) );

    # check the config : this has precedence
       # my $config_approve = Baseliner->model('ConfigStore')->get('config.job.approve', bl=>$bl);
    # unless( $config_approve->{enable} ) {
        # $log->info( _loc('No hay aprobaciones para esta linea base %1', $bl ) );
        # return;
    # }

    my %cam;
    for (_array $job->job_stash->{contents}) {
       $cam{(ns_split($_->{application}))[1]}=1 if ( $_->{provider} );
    }


    $approval_items ||= $job->job_stash->{contents}; 
    $reason ||= _loc("Promote to %1",$bl);
    
    my $apps = join ( ', ', _unique map {my ($a,$b)=ns_split($_->{application}); $b } _array $job->job_stash->{contents} );
    my $comment = $job->job_data->{comments};
    my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d", _notify_address(), $job->jobid );
    my $message = _loc("Scheduled at %1 of %2",$start->hms(':'),$start->dmy('/'));

    my @users = Baseliner->model('Permissions')->list(action => 'action.job.approve', ns => '/', bl => '*');
    my $to = [ _unique(@users) ];

    #my $item_ns = 'endevor.package/' . $item->{item};   #TODO get real ns names
    $log->info( _loc('Requesting approval for job %1, baseline %2: %3', $job->name, $bl, _loc($reason) ) );
    my $subject = scalar keys %cam == 1 
        ? _loc('Application: %1. Requesting approval for job %2, baseline %3: %4', join(', ',keys %cam), $job->name, $bl, _loc($reason) )
        : _loc('Applications: %1. Requesting approval for job %2, baseline %3: %4', join(', ',keys %cam), $job->name, $bl, _loc($reason) );
    my $name = scalar keys %cam == 1 
        ? _loc('Application: %1. Requesting approval for job %2', join(', ',keys %cam), $job->name )
        : _loc('Applications: %1. Requesting approval for job %2', join(', ',keys %cam), $job->name );
    try {
        Baseliner->model('Request')->request(
           # name   => _loc("Approval for job %1", $job->name),
            name  => $name,
            action => 'action.job.approve',
            item   => $job->name,
            template_engine => 'mason',
            template => '/email/approval_job.html',
            username     => $job->job_data->{username},
            comments_job => $job->job_data->{comments},
            ns           => 'job/' . $job->name,
            bl           => $bl, 
            id_job       => $job->jobid,
            vars         => {
                jobname  => $job->name,
                reason   => _loc($reason),
                message  => $message,
                comments => $job->job_data->{comments},
                to       => $to,
                url_log  => $url_log,
                url      => _notify_address(),
                subject  => $subject,
            },
            data         => {
                project  => $apps,
                app      => $apps,
                comment  => $comment,
                ts       => _now()
            }
        );
        my $job_row = $c->model('Baseliner::BaliJob')->find({ id=>$job->jobid });
        $log->debug( 'Cambiando status a APPROVAL' );
        $job->status('APPROVAL');
    } catch {
        my $e = shift;
        $log->info( _loc("El pase '%1' no necesita aprobaciÃ³n (no hay usuarios para aprobarlo)", $job->name ) );
    };
}

1;
