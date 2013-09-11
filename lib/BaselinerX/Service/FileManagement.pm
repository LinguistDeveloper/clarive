package BaselinerX::Service::FileManagement;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;
use utf8::all;
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
    form => '/forms/store_file.js',
    handler => \&run_store,
};

register 'service.fileman.rm' => {
    name => 'Delete Local File',
    handler => \&run_rm,
};

register 'service.fileman.rmtree' => {
    name => 'Delete Local Directory',
    handler => \&run_rmtree,
};

sub run_tar {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    
    $log->info( _loc('Tar of directory `%1` into file `%2`', $config->{source_dir}, $config->{tarfile}), 
            $config );
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
    _fail _loc 'Could not find file `%1`', $f
        unless -e $f;
    $log->info(
        _loc($config->{message}//'%1', $filename),
        data      => scalar $f->slurp,
        data_name => $filename,
        milestone => $config->{milestone} // 1,
        more      => $config->{more} // 'file',
    );
}

sub run_ship {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;

}

sub run_rm {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;

    my $file = $config->{file} // _fail _loc 'Missing parameter file';
    
    my $f = _file( $job->job_dir, $file );
    _fail _loc 'Could not find file `%1`', $f
        unless -e $f;
    if( unlink "$f" ) {
        $log->info( _loc('Successfully delete file `%1`', $f) ); 
    } else {
        _fail( _loc('Error deleting file `%1`: %2', $f, $!) ); 
    }
}

sub run_rmtree {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;

    my $dir = $config->{dir} // _fail _loc 'Missing parameter dir';
    
    my $f = _dir( $job->job_dir, $dir );
    _fail _loc 'Could not find dir `%1`', $f
        unless -d $f;
    if( $f->rmtree ) {
        $log->info( _loc('Successfully deleted directory `%1`', $f) ); 
    } else {
        _fail( _loc('Error deleting directory `%1`: %2', $f, $!) ); 
    }
}

1;
