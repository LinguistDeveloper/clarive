package BaselinerX::Service::CreateJob;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use Path::Class;
use Baseliner::Sugar;
use Class::Date;

with 'Baseliner::Role::Service';

register 'service.job.create' => {
    name => _locl('Create a Job'),
    job_service  => 1,
    form => '/forms/create_job.js',
    icon => '/static/images/icons/service-job-create.svg',
    handler => \&run_create, };

sub run_create {
    my ($self,$c, $config)=@_;

    my $stash = $c->stash;
    my @changesets = Util->_array_or_commas($config->{changesets});
    my $bl = $config->{bl};
    my $job_stash = $config->{job_stash};

    try {
        # create job CI
        my $job_type = $config->{job_type} || 'static';
        my $job_data = {
            bl         => $bl,
            job_type   => $job_type,
            username   => $config->{username} || 'clarive',
            comments   => $config->{comments},
            changesets => \@changesets
        };
        $job_data->{id_rule} = $config->{id_rule} if $config->{id_rule};
        my $expiry_time = "1D";

        if ( $config->{expiry_time} ) {
            $expiry_time = $config->{expiry_time};
        }

        if ($config->{schedtime})  {
            $job_data->{schedtime} = $config->{schedtime};
        }

        $job_data->{maxstarttime} = Class::Date->new($job_data->{schedtime}) + $expiry_time;

        my $job;
        event_new 'event.job.new' => { username => $job_data->{username}, bl => $job_data->{bl} } => sub {
            $job = ci->job->new($job_data);
            $job->save;
            $job->job_stash( $job_stash, 'merge' ) if ref $job_stash;
            my $job_name = $job->{name};
            my $bl       = ci->bl->find_one( { name => $job_data->{bl} } );
            my $bl_mid   = $bl->{mid};
            my $subject =
              _loc( "The user %1 has created job %2 for %3 bl", $job_data->{username}, $job_name, $job_data->{bl} );
            my @projects = map { $_->{mid} } _array( $job->{projects} );
            my $notify = {
                project => \@projects,
                bl      => $bl_mid
            };
            {
                jobname => $job_name,
                mid     => $job->{mid},
                id_job  => $job->{jobid},
                subject => $subject,
                notify  => $notify
            };

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

no Moose;
__PACKAGE__->meta->make_immutable;

1;
