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
    form => '/forms/tar_local.js',
    handler => \&run_tar,
};

register 'service.fileman.ship' => {
    name => 'Ship a File Remotely',
    form => '/forms/ship_remote.js',
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
    my $stash = $c->stash;
    
    $log->info( _loc('Tar of directory `%1` into file `%2`', $config->{source_dir}, $config->{tarfile}), 
            $config );
    Util->tar_dir( %$config ); 
}
    
sub run_store {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
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
    my $stash = $c->stash;
    my $stmt  = $stash->{current_statement_name};

    my $remote = $config->{remote_path} // _fail 'Missing parameter remote_file';
    my $local  = $config->{local_path} // _fail 'Missing parameter local_file';
    my $user   = $config->{user};
    my $chmod  = $config->{'chmod'};
    my $chown  = $config->{'chown'};

    for my $server ( split /,/, $config->{server} ) {
        $server = _ci( $server ) unless ref $server;
        _debug $stmt . " - Connecting to server " . $server->name;
        my $agent = $server->connect( user=>$user );
        $log->info( _loc( '*%1* Sending file `%2` to `%3`', $stmt, $local, $remote ) );
        $agent->put_file({ 
            local  => $local,
            remote => $remote,
        });
        if( length $chown ) {
            _debug "chown $chown $remote";
            $agent->chown( $chmod, $remote );
            $log->error( _loc('*%1* Error doing a chown `%2` to file `%3`: %4', $stmt, $chown,$remote, $agent->output ), $agent->tuple ) if $agent->rc && $agent->rc!=512;
        }
        if( length $chmod ) {
            _debug "chmod $chmod $remote";
            $agent->chmod( $chmod, $remote );
            $log->error( _loc('*%1* Error doing a chmod `%2` to file `%3`: %4', $stmt, $chmod,$remote, $agent->output ), $agent->tuple ) if $agent->rc && $agent->rc!=512;
        }
    }

    return 1;
}

sub run_rm {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;

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
    my $stash = $c->stash;

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
