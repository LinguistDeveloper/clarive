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

register 'service.fileman.tar_nature' => {
    name => 'Tar Nature Files',
    form => '/forms/tar_local_nature.js',
    handler => \&run_tar_nature,
};

register 'service.fileman.ship' => {
    name => 'Ship a File Remotely',
    form => '/forms/ship_remote.js',
    icon => '/static/images/icons/ship.gif',
    handler => \&run_ship,
};

register 'service.fileman.retrieve' => {
    name => 'Retrieve a Remote File',
    icon => '/static/images/icons/retrieve.gif',
    form => '/forms/retrieve_remote.js',
    handler => \&run_retrieve,
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
    
sub run_tar_nature {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    my @files = _array( $stash->{nature_item_paths} );
    $log->info( _loc('Tar of directory `%1` into file `%2`', $config->{source_dir}, $config->{tarfile}), 
            $config );
    Util->tar_dir( %$config, files=>\@files ); 
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
    $f = _file( $file ) unless -e $f;
    _fail _loc 'Could not find file `%1` nor `%2` to store', $f, _file($job_dir, $file)
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
    my $job_dir = $stash->{job_dir};
    my $stmt  = $stash->{current_statement_name};

    my $remote_path = $config->{remote_path} // _fail 'Missing parameter remote_file';
    my $local_path  = $config->{local_path}  // _fail 'Missing parameter local_file';
    my $user        = $config->{user};
    my $chmod       = $config->{'chmod'};
    my $chown       = $config->{'chown'};
    my $local_mode  = $config->{local_mode} // 'local_files';  # local_files, nature_items
    my $rel_path    = $config->{rel_path} // 'file_only'; # file_only, rel_path_job, rel_path_anchor 
    my $anchor_path = $config->{anchor_path} // ''; 

    for my $server ( split /,/, $config->{server} ) {
        $server = ci->new( $server ) unless ref $server;
        $remote_path = $server->parse_vars( $remote_path );
        my $server_str = "$user\@".$server->name;
        _debug $stmt . " - Connecting to server " . $server_str;
        my $agent = $server->connect( user=>$user );
        my $cnt = 0;

        my @locals;
        my $is_wildcard = 0;
        if( $local_mode eq 'nature_items' ) {
            @locals = map { _file($job_dir,$_) } _array( $stash->{nature_item_paths} ); 
        } else {
            # local_files (with or without wildcard)
            $local_path = $server->parse_vars( $local_path );
            $is_wildcard = $local_path =~ /\*/;
            @locals = grep { -f } glob $local_path;
        }
        $log->debug( _loc('local_mode=%1, local list', $local_mode), \@locals );
        
        for my $local ( @locals ) {
            $cnt++;
            # local path relative or pure filename?
            my $local_path = 
                $rel_path eq 'file_only' ? _file( $local )->basename : 
                $rel_path eq 'rel_path_job' ? _file( $local )->relative( $job_dir ) 
                : _file($local)->relative( $anchor_path );
            $local_path = $server->parse_vars($local_path);
            $log->debug( _loc('rel path mode `%1`, local_path=%2', $rel_path, $local_path ) );
            # set remote to remote + local_path, except on local_files w/ wildcard
            #my $remote = $is_wildcard ? _file( $remote_path, $local_path ) : $remote_path;
            my $remote = _file( $remote_path, $local_path );
            $log->info( _loc( '*%1* Sending file `%2` to `%3`', $stmt, $local, $server_str.':'.$remote ) );
            $agent->put_file(
                local  => "$local",
                remote => "$remote",
            );
            if( length $chown ) {
                _debug "chown $chown $remote";
                $agent->chown( $chmod, "$remote" );
                $log->warn( _loc('*%1* Error doing a chown `%2` to file `%3`: %4', $stmt, $chown,$remote, $agent->output ), $agent->tuple_str ) if $agent->rc && $agent->rc!=512;
            }
            if( length $chmod ) {
                _debug "chmod $chmod $remote";
                $agent->chmod( $chmod, "$remote" );
                $log->warn( _loc('*%1* Error doing a chmod `%2` to file `%3`: %4', $stmt, $chmod,$remote, $agent->output ), $agent->tuple_str ) if $agent->rc && $agent->rc!=512;
            }
        }
        $log->warn( _loc( 'Could not find any file locally to ship to `%1`', $server_str ), $config )
            unless $cnt > 0;
    }

    return 1;
}

sub run_retrieve {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $stmt  = $stash->{current_statement_name};

    my $remote = $config->{remote_path} // _fail 'Missing parameter remote_file';
    my $local  = $config->{local_path} // _fail 'Missing parameter local_file';
    my $user   = $config->{user};

    for my $server ( split /,/, $config->{server} ) {
        $server = ci->new( $server ) unless ref $server;
        my $server_str = "$user\@".$server->name;
        _debug $stmt . " - Connecting to server " . $server_str;
        my $agent = $server->connect( user=>$user );
        $log->info( _loc( '*%1* Retrieving file `%2` to `%3`', $stmt, $local, $server_str.':'.$remote ) );
        $agent->get_file(
            local  => $local,
            remote => $remote,
        );
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
