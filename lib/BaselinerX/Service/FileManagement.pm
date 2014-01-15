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
    job_service  => 1,
    handler => \&run_tar,
};

register 'service.fileman.tar_nature' => {
    name => 'Tar Nature Files',
    form => '/forms/tar_local_nature.js',
    job_service  => 1,
    handler => \&run_tar_nature,
};

register 'service.fileman.ship' => {
    name => 'Ship a File Remotely',
    form => '/forms/ship_remote.js',
    icon => '/static/images/icons/ship.gif',
    job_service  => 1,
    handler => \&run_ship,
};

register 'service.fileman.retrieve' => {
    name => 'Retrieve a Remote File',
    icon => '/static/images/icons/retrieve.gif',
    form => '/forms/retrieve_remote.js',
    job_service  => 1,
    handler => \&run_retrieve,
};

register 'service.fileman.store' => {
    name => 'Store Local File',
    form => '/forms/store_file.js',
    icon => '/static/images/icons/drive_disk.png',
    job_service  => 1,
    handler => \&run_store,
};

register 'service.fileman.write' => {
    name => 'Write Local File',
    form => '/forms/write_file.js',
    icon => '/static/images/icons/drive_edit.png',
    job_service  => 1,
    handler => \&run_write,
};

register 'service.fileman.rm' => {
    name => 'Delete Local File',
    icon => '/static/images/icons/drive_delete.png',
    job_service  => 1,
    handler => \&run_rm,
};

register 'service.fileman.rmtree' => {
    name => 'Delete Local Directory',
    icon => '/static/images/icons/drive_delete.png',
    job_service  => 1,
    handler => \&run_rmtree,
};

register 'service.fileman.parse_config' => {
    name => 'Parse a Config File',
    icon => '/static/images/icons/drive_go.png',
    job_service  => 1,
    handler => \&run_parse_config,
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
    
sub run_write {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $filepath = $config->{filepath};
    my $file_encoding = $config->{file_encoding};
    my $body_encoding = $config->{body_encoding};
    my $body = $config->{body};
    my $log_body = $config->{log_body};
    
    require Encode;
    Encode::from_to( $body, $body_encoding, $file_encoding )
        if $body_encoding && ( $file_encoding ne $body_encoding );
    
    my $open_str = $file_encoding ? ">:encoding($file_encoding)" : '>';
    open my $ff, $open_str, $filepath
        or _fail _loc 'Could not open file for writing (%1): %2', $!;
    print $ff $body;
    close $ff;
    $log->info( _loc('File content written: `%1`', $filepath), $log_body eq 'yes' ? ( data=>$body ) : () ); 
    return $filepath;
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
    my $job_mode = $stash->{job_mode};
    my $task  = $stash->{current_task_name};
    my $job_exec = $job->exec;

    my $remote_path_orig = $config->{remote_path} // _fail 'Missing parameter remote_file';
    my $local_path  = $config->{local_path}  // _fail 'Missing parameter local_file';
    my $user        = $config->{user};
    my $chmod       = $config->{'chmod'};
    my $chown       = $config->{'chown'};
    my $local_mode  = $config->{local_mode} // 'local_files';  # local_files, nature_items
    my $rel_mode    = $config->{rel_path} // 'file_only'; # file_only, rel_path_job, rel_path_anchor 
    my $anchor_path = $config->{anchor_path} // ''; 
    my $create_dir  = $config->{create_dir} // 'create'; 
    my $backup_mode = $config->{backup_mode} // 'backup'; 
    my $rollback_mode = $config->{rollback_mode} // 'rollback'; 
    my $needs_rollback_mode = $config->{needs_rollback_mode} // 'nb_after'; 
    my $needs_rollback_key = $config->{needs_rollback_key} // $task;
    my $exist_mode = $config->{exist_mode} // 'skip'; # skip files already shipped by default
    $stash->{needs_rollback}{ $needs_rollback_key } = 1 if $needs_rollback_mode eq 'nb_always';
    my ($include_path,$exclude_path) = @{ $config }{qw(include_path exclude_path)};
    
    _fail _loc "Server not configured" unless length $config->{server};
    
    my $sent_files = $stash->{sent_files} // {};

    my $servers = $config->{server};
    for my $server ( Util->_array_or_commas($servers) ) {
        $server = ci->new( $server ) unless ref $server;
        my $remote_path = $server->parse_vars( "$remote_path_orig" );
        my $server_str = "$user\@".$server->name;
        _debug "Connecting to server " . $server_str;
        my $agent = $server->connect( user=>$user );
        my $cnt = 0;

        my ( @locals, @backup_files );
        my $is_wildcard = 0;
        if( $local_mode eq 'nature_items' ) {
            @locals = map { _file($job_dir,$_) } _array( $stash->{nature_item_paths} ); 
        } else {
            # local_files (with or without wildcard)
            $local_path = $server->parse_vars( "$local_path" );
            $is_wildcard = $local_path =~ /\*/;
            @locals = grep { -f } glob $local_path;
        }
        $log->debug( _loc('local_mode=%1, local list', $local_mode), \@locals );
        
        ITEM: for my $local ( @locals ) {
            $cnt++;

            # local path relative or pure filename?
            $log->debug( _loc('rel path mode `%1`, local=`%2`, anchor=`%3`', $rel_mode, $local, $anchor_path ) );
            my $local_path = 
                $rel_mode eq 'file_only' ? _file( $local )->basename : 
                $rel_mode eq 'rel_path_job' ? _file( $local )->relative( $job_dir ) 
                : _file($local)->relative( $anchor_path );
            $local_path = $server->parse_vars("$local_path");
            $log->debug( _loc('rel path mode `%1`, local_path=%2', $rel_mode, $local_path ) );
            
            # filters?
            my $flag;
            IN: for my $in ( _array( $include_path ) ) {
                $flag //= 0;
                if( $local_path =~ _regex($in) ) {
                    $flag =$in;
                    last IN;
                }
            }
            if( defined $flag && !$flag ) {
                _debug "File not included path `$local_path` due to rule `$flag`";
                next ITEM;
            }
            for my $ex ( _array( $exclude_path ) ) {
                if( $local_path =~ _regex($ex) ) {
                    _debug "File excluded path `$local_path` due to rule `$ex`";
                    next ITEM;
                }
            }
            
            # set remote to remote + local_path, except on local_files w/ wildcard
            my $remote = _file( "$remote_path", "$local_path" );
            my $bkp_local = _file( $job->backup_dir, $server_str, $remote );

            # make a backup?
            if( $job_mode eq 'forward' && $backup_mode eq 'backup' ) {
                if( ! -e $bkp_local ) {
                    $log->debug( _loc('Getting backup file from remote `%1` to `%2`', $remote, $bkp_local) );
                    push @backup_files, "$bkp_local";
                    my $bkp_dir = _file( $bkp_local )->dir->mkpath;
                    if( !$agent->file_exists( "$remote" ) ) {
                        $log->debug( _loc('No existing file detected to backup: `%1`', $remote) );
                    } else {
                        try {
                            $agent->get_file( local=>"$bkp_local", remote=>"$remote" );
                        } catch {
                            my $err = shift;
                            if( $backup_mode eq 'backup_fail' ) {
                                $log->error( _loc('Error reading backup file from remote. Ignored: `%1`', $remote), "$err" );
                                _fail _loc 'Error during file backup';
                            } else {
                                $log->warn( _loc('Error reading backup file from remote. Ignored: `%1`', $remote), "$err" );
                            }
                        };
                    }
                }
            }

            # rollback ?
            if( $job_mode eq 'rollback' && $rollback_mode =~ /^rollback/ ) {
                if( -e $bkp_local ) {
                    $log->debug( _loc( 'Rollback switch to local file `%1`', $bkp_local ) );
                    $local = $bkp_local;
                } elsif( $rollback_mode eq 'rollback_force' ) {
                    _fail _loc 'Could not find rollback file %1', $bkp_local;
                }
            }
            
            # ship done here
            my $local_stat   = join(",",@{ _file($local)->stat || [] }); # create a stat string
            my $local_chksum = Digest::MD5::md5_base64( scalar _file($local)->slurp );   # maybe slow for very large files, but faster than _md5
            my $local_key = "$job_exec|$local|$local_stat|$local_chksum";  # job exec included, forces reship on every exec
            my $local_key_md5 = Util->_md5( $local_key );
            my $hostname = $agent->server->hostname;
            my $sent = $sent_files->{$hostname}{$local_key_md5}{"$remote"}; 
            if( $sent && $exist_mode ne 'reship' ) {
                $log->info( _loc('File `%1` already in machine `%2` (%3). Ship skipped.', "$local", "*$hostname*".':'.$remote, $server_str ), data=>$local_key );
            } else {
                $log->info( _loc( 'Sending file `%1` to `%2`', $local, "*$server_str*".':'.$remote ) );
                # create dir if not exists?
                my $remote_dir = _file($remote)->dir;
                if( $create_dir eq 'create' && !$agent->file_exists("$remote_dir") ) {
                    $agent->mkpath( "$remote_dir" );
                }
                $stash->{needs_rollback}{ $needs_rollback_key } = 1 if $needs_rollback_mode eq 'nb_before';
                # send file remotely
                $agent->put_file(
                    local  => "$local",
                    remote => "$remote",
                );
                $sent_files->{$hostname}{$local_key_md5}{"$remote"} = _now();
            }
            $stash->{needs_rollback}{ $needs_rollback_key } = 1 if $needs_rollback_mode eq 'nb_after';
            
            if( length $chown ) {
                _debug "chown $chown $remote";
                $agent->chown( $chmod, "$remote" );
                $log->warn( _loc('Error doing a chown `%1` to file `%2`: %3', $chown,$remote, $agent->output ), $agent->tuple_str ) if $agent->rc && $agent->rc!=512;
            }
            if( length $chmod ) {
                _debug "chmod $chmod $remote";
                $agent->chmod( $chmod, "$remote" );
                $log->warn( _loc('Error doing a chmod `%1` to file `%2`: %3', $chmod,$remote, $agent->output ), $agent->tuple_str ) if $agent->rc && $agent->rc!=512;
            }
        }
        $log->warn( _loc( 'Could not find any file locally to ship to `%1`', $server_str ), $config )
            unless $cnt > 0;
    }
    
    $stash->{sent_files} //= $sent_files;

    return 1;
}

sub run_retrieve {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;

    my $remote = $config->{remote_path} // _fail 'Missing parameter remote_file';
    my $local  = $config->{local_path} // _fail 'Missing parameter local_file';
    my $user   = $config->{user};

    my $servers = $config->{server};
    for my $server ( Util->_array_or_commas($servers) ) {
        $server = ci->new( $server ) unless ref $server;
        my $server_str = "$user\@".$server->name;
        _debug "Connecting to server " . $server_str;
        my $agent = $server->connect( user=>$user );
        $log->info( _loc( 'Retrieving file `%1` to `%2`', $local, "*$server_str".'*:'.$remote ) );
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

sub run_parse_config {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $config_file = $config->{config_file};
    my $root_key    = $config->{root_key};
    my $fail_if_not_found  = $config->{fail_if_not_found};
    
    if( !-e $config_file ) {
        my $msg = _loc( 'Config file not found in `%1`', $config_file );
        if( $fail_if_not_found ) {
            _fail $msg; 
        } else {
            _warn $msg;
        }
    }
    
    my $body = _file($config_file)->slurp;
    if( !length $body ) {
        _fail _loc('Config file is empty: `%1`', $config_file);
        return;
    }
    my $vars = _load( $body );
    return $vars;
}

1;
