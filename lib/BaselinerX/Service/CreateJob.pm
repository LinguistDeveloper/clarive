package BaselinerX::Service::CreateJob;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use Path::Class;
use Baseliner::Sugar;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.create' => { 
    name => 'Create a Job', 
    job_service  => 1,
    form => '/forms/create_job.js',
    handler => \&run_create, };

sub run_create {
    my ($self,$c, $config)=@_;

    my $stash = $c->stash;
    my @changesets = Util->_array_or_commas($config->{changesets});
    my $bl = $config->{bl};

    try {
        # create job CI
        my $job_type = $config->{job_type} || 'static';
        my $job_data = {
            bl         => $bl,
            job_type   => $job_type,
            username   => $config->{username} || 'clarive',
            comments   => $config->{comments},
            changesets => \@changesets,
        };
        my $job;
        event_new 'event.job.new' => { username => $job_data->{username}, bl => $job_data->{bl}  } => sub {

            $job = ci->job->new( $job_data );
            $job->save;  # after save, CHECK and INIT run
            # $job->job_stash({   # job stash autosaves into the stash table
            #     status_from    => $config->{status_from},
            #     status_to      => $config->{status_to},
            #     id_status_from => $config->{id_status_from},
            # }, 'merge');
            my $job_name = $job->{name};
            my $subject = _loc("The user %1 has created job %2 for %3 bl", $job_data->{username}, $job_name, $job_data->{bl});
            my @projects = map {$_->{mid} } _array($job->{projects});
            my $notify = {
                project => \@projects,
                baseline => $job_data->{bl}
            };
            { jobname => $job_name, mid=>$job->{mid}, id_job=>$job->{jobid}, subject => $subject, notify => $notify };

        };
        _log(_loc( "Job %1 created ok", $job->{name} ));
        return 1;
    } catch {
        my $err = shift;
        $err =~ s({UNKNOWN})()g;
        $err =~ s{DBIx.*\(\):}{}g;
        $err =~ s{ at./.*line.*}{}g;
        _fail(_loc( "Error creating job: %1", "$err" ));
    };    
}

1;
