package BaselinerX::Job::Service::Contents;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.contents' => { name => 'Job Runner Contents Loader', config => 'config.job.runner', handler => \&run, };

sub run {
	my ($self,$c,$config)=@_;
	
	my $job = $c->stash->{job};
	my $log = $job->logger;

	# prepare the elements object
    $job->job_stash->{elements} = BaselinerX::Job::Elements->new;

	# load the contents array
	$log->debug( 'Job Contents cargando, path=' . $job->job_stash->{path} );

	# fetch contents
    $job->job_stash->{contents} = $self->contents($job->jobid);

    $log->debug( 'Job stash contents', data_name=>'Job Stash', data=>_dump( $job->job_stash ) );
}

sub contents {
	my ($self,$jobid)=@_;
	my $rs =Baseliner->model('Baseliner::BaliJobItems')->search({ id_job=> $jobid }); 
	my @contents;
	while( my $r = $rs->next ) {
		# load vars with contents
        my %job_items = $r->get_columns;
        $job_items{data} = YAML::Syck::Load( $job_items{data} ); # deserialize this baby
		push @contents, \%job_items;
	}
	return wantarray ? @contents : \@contents;
}

1;
