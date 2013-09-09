package BaselinerX::Service::FileManagement;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;
with 'Baseliner::Role::Service';

register 'service.fileman.tar' => {
    name => 'Tar Local Files',
    handler => \&run_tar,
};

register 'service.fileman.ship' => {
    name => 'Ship a File Remotely',
    handler => \&run_ship,
};

register 'service.fileman.store' => {
    name => 'Store Local File',
    handler => \&run_store,
};

sub run_tar {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    
    $log->info( _loc('Tar of directory `%1` into file `%2`', $config->{source_dir}, $config->{tarfile}), 
            \%config );
    tar_dir( %$config ); 
}
    
sub run_store {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    
    my $job_dir = $job->job_dir;
    my $file = $config->{file} // _fail _loc 'Missing parameter file';
    my $filename = $config->{filename} // _fail _loc 'Missing parameter filename';
    
    my $f = _file( $job_dir, $file );
    $log->info( _loc( $filename ), data=>$f->slurp, data_name=>$filename, milestone=>1 );
}

sub run_ship {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;

}

1;
