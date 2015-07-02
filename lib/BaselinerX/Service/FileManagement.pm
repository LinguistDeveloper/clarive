package BaselinerX::Service::FileManagement;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;
use utf8::all;
use experimental 'autoderef';
with 'Baseliner::Role::Service';

register 'service.fileman.foreach' => {
    name => 'Load files/items into stash',
    form => '/forms/file_foreach.js',
    job_service  => 1,
    handler => \&run_load_files,
};

register 'statement.fileman.foreach' => {
    text => 'FOREACH file/item',
    type => 'loop',
    form => '/forms/file_foreach.js',
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            my $config = parse_vars %s, $stash;
            foreach ( _array( BaselinerX::Service::FileManagement->file_foreach($stash,$config) ) ) {
                local $stash->{'%s'} = $_;
                %s
            }
        }, Data::Dumper::Dumper($n->{data}), $n->{varname}//'file', $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'service.fileman.tar' => {
    name => 'Tar Local Files',
    form => '/forms/tar_local.js',
    job_service  => 1,
    handler => \&run_tar,
};

register 'service.fileman.zip' => {
    name => 'Zip Local Files',
    form => '/forms/zip_local.js',
    icon => '/static/images/icons/package_add.png',
    job_service  => 1,
    handler => \&run_zip,
};

register 'service.fileman.tar_nature' => {
    name => 'Tar Nature Files',
    form => '/forms/tar_local_nature.js',
    job_service  => 1,
    handler => \&run_tar_nature,
};

register 'service.fileman.zip_nature' => {
    name => 'Zip Nature Files',
    form => '/forms/zip_local_nature.js',
    icon => '/static/images/icons/package_add.png',
    job_service  => 1,
    handler => \&run_zip_nature,
};

register 'service.fileman.zip' => {
    name => 'Zip Files',
    form => '/forms/zip_files.js',
    job_service  => 1,
    handler => \&run_zip,
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
    form => '/forms/parse_config.js',
    icon => '/static/images/icons/drive_go.png',
    job_service  => 1,
    handler => \&run_parse_config,
};

register 'service.fileman.write_config' => {
    name => 'Write a Config File',
    form => '/forms/write_config.js',
    icon => '/static/images/icons/drive_go.png',
    job_service  => 1,
    handler => \&run_write_config,
};

sub run_load_files {
    my ($self, $c, $config ) = @_;
    return $self->file_foreach( $c->stash, $config );
}

sub file_foreach {
    my ($self, $stash, $config ) = @_;
    my $job   = $stash->{job};
    #my $log   = $job->logger;
    my $fail_on_error = $config->{fail_on_error} // 1;
    my $path = $config->{path};
    my $path_mode = $config->{path_mode} // 'files_flat';
    my $dir_mode = $config->{dir_mode} // 'file_only';
   
    _fail _loc 'Root path not configured' if $path_mode ne 'nature_items' && !length $path;
    _fail _loc 'Path does not exist or is not readable: `%1`', $path if length $path && $path!~/\*|\?/ && !-e $path;
    my $job_dir = $stash->{job_dir};

    my @files;
    if( $path_mode eq 'files_flat' ){
        my $gpath = -d $path ? ''._dir($path,'*') : $path;
        @files = grep { $dir_mode eq 'file_only' ? -f : -e } glob $gpath;
    }
    elsif( $path_mode eq 'files_recursive' ){
        _dir( $path )->recurse( callback=>sub{
            my $f = shift;
            my $is_dir = $f->is_dir;
            return if $dir_mode eq 'file_only' && $is_dir;
            return if $dir_mode eq 'dir_only' && !$is_dir;
            push @files, "$f";
        });
    }
    elsif( $path_mode eq 'nature_items' ){
        @files = 
            map { length $path ? $_->relative($path)->stringify : "$_" }
            grep { 
                my $is_dir = -d $_; # is_dir does not check if it exists and is a dir
                ($dir_mode eq 'file_only' && !$is_dir)
                || ($dir_mode eq 'dir_only' && $is_dir)
                || $dir_mode eq 'file_and_dir';
            }
            grep {
               -e $_  # gets rid of deletions
            }
            map { _file($job_dir,$_) } _array( $stash->{nature_item_paths} ); 
    }
   
    my ($include_path,$exclude_path) = @{ $config }{qw(include_path exclude_path)};
    @files = $self->filter_paths( $include_path, $exclude_path, @files );
    return \@files;
}

sub filter_paths {
    my ($self,$include_path,$exclude_path,@paths) = @_;
    my @filtered;
    my @debugs;
    PATH: for my $path ( @paths ) {
        # filters?
        my $flag;
        IN: for my $in ( _array( $include_path ) ) {
            $flag //= 0;
            if( $path =~ _regex($in) ) {
                $flag =$in;
                last IN;
            }
        }
        if( defined $flag && !$flag ) {
            push @debugs, "File not included path `$path` due to rule `$flag`";
            next PATH;
        }
        for my $ex ( _array( $exclude_path ) ) {
            if( $path =~ _regex($ex) ) {
                push @debugs, "File excluded path `$path` due to rule `$ex`";
                next PATH;
            }
        }
        push @filtered, $path;
    }
    _debug( _loc("Filter paths, include, excludes"), 
            "Includes:\n".join("\n",_array($include_path))
            ."\nExcludes:\n".join("\n",_array($exclude_path))
            ."\nMessages:\n".join("\n",@debugs) ) if @debugs;

    return @filtered;
}

sub run_tar {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    $log->info( _loc("Tar of directory '%1' into file '%2'", $config->{source_dir}, $config->{tarfile}), 
            $config );
    Util->tar_dir( %$config ); 
}
    
#sub run_zip {
#    my ($self, $c, $config ) = @_;
#
#    my $job   = $c->stash->{job};
#    my $log   = $job->logger;
#    my $stash = $c->stash;
#    
#    $log->info( _loc("Zip of directory '%1' into file '%2'", $config->{source_dir}, $config->{zipfile}), 
#            $config );
#    Util->zip_dir( %$config ); 
#}
    
sub run_tar_nature {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $clean_path_mode = $config->{clean_path_mode} // 'none';
    
    my @files = _array( $stash->{nature_item_paths} );
    # check if there are absolute nature file paths (starting with /)
    #    maybe caused by missing IF NATURE op "cut path"
    for my $f( @files ) {
        next unless $f =~ /^\//; 
        if( $clean_path_mode eq 'force' ) {
            $f =~ s{^/}{}g; 
        } else {
            _warn _loc 'Nature path not relative for file `%1`. This file will not be included in the tar. Check your IF NATURE `Cut Path` has at least a slash `/`', $f;
        }
    }
    $log->info( _loc("Tar of directory '%1' into file '%2'", $config->{source_dir}, $config->{tarfile}), 
            $config );
    Util->tar_dir( %$config, files=>\@files ); 
}

sub run_zip {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    $log->info( _loc("Zip source '%1' into file '%2'", $config->{source}, $config->{to}), 
            $config );
    Util->zip_tree( %$config ); 
}

    
sub run_zip_nature {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    my @files = _array( $stash->{nature_item_paths} );
    $log->info( _loc("Zip of directory '%1' into file '%2'", $config->{source_dir}, $config->{zipfile}), 
            $config );
    Util->zip_dir( %$config, files=>\@files ); 
}
    
sub run_write {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $filepath = $config->{filepath};
    my $file_encoding = $config->{file_encoding};
    my $body_encoding = $config->{body_encoding};
    my $templating    = $config->{templating} // 'none';
    my $template_var  = $config->{template_var} // '';
    my $body = $config->{body};
    my $log_body = $config->{log_body};
    
    require Encode;
    Encode::from_to( $body, $body_encoding, $file_encoding )
        if $body_encoding && ( $file_encoding ne $body_encoding );
        
    if( $templating eq 'tt' ) {
        my $output = BaselinerX::Service::Templating->process_tt( $stash, $template_var, $body );
        $body = $output;
    }
    
    my $dir = _file( $filepath )->dir;
    $dir->mkpath;
    my $open_str = $file_encoding ? ">:encoding($file_encoding)" : '>';
    open my $ff, $open_str, $filepath
        or _fail _loc 'Could not open file for writing (%1): %2', $!;
    print $ff $body;
    close $ff;
    $log->info( _loc("File content written: '%1'", $filepath), $log_body eq 'yes' ? ( data=>$body ) : () ); 
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

    my $remote_path_orig = $config->{remote_path} // _fail 'Missing parameter remote_path';
    my $local_path  = $config->{local_path}  // _fail 'Missing parameter local_path';
    my $user        = $config->{user};
    my $copy_attrs  = $config->{copy_attrs} // 0;
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
    my $recursive = $config->{recursive} // 0;
    $stash->{needs_rollback}{ $needs_rollback_key } = 1 if $needs_rollback_mode eq 'nb_always';
    my ($include_path,$exclude_path) = @{ $config }{qw(include_path exclude_path)};
    
    _fail _loc "Server not configured" unless length $config->{server};
    
    my $sent_files = $stash->{sent_files} // {};

    my $servers = $config->{server};
    for my $server ( Util->_array_or_commas($servers) ) {
        $server = ci->new( $server ) unless ref $server;
        Util->is_ci_or_fail( $server, 'server' );
        if( !$server->active ) {
            $log->warn( _loc('Server %1 is inactive. Skipped', $server->name) );
            next;
        }
        _fail _loc "Could not instanciate CI for server `%1`", $server unless ref $server;
        my $remote_path = $server->parse_vars( "$remote_path_orig" );
        my $server_str = "$user\@".$server->name;
        _debug "Connecting to server " . $server_str;
        my $agent = $server->connect( user=>$user );
        # $agent -> throw_errors(1);  # TODO needed, but may fail sometimes...
        my $cnt = 0;

        my ( @locals, @backup_files );
        my $is_wildcard = 0;
        if( $local_mode eq 'nature_items' ) {
            @locals = map { _file($job_dir,$_) } _array( $stash->{nature_item_paths} ); 
        } else {
            # local_files (with or without wildcard)
            $local_path = $server->parse_vars( "$local_path" );
            $is_wildcard = $local_path =~ /\*/;
            if ( !$recursive ) {
                @locals = grep { -f } glob $local_path;
            } else {
                use File::Find qw(finddepth);
                my @files;
                finddepth(
                    sub {
                        return if ( $_ eq '.' || $_ eq '..' );
                        push @files, $File::Find::name;
                        _log $File::Find::name;
                    },
                    $local_path
                );
                @locals = grep {-f} @files;
            }
        }
        $log->debug( _loc('local_mode=%1, local list', $local_mode), \@locals );
        
        ITEM: for my $local ( @locals ) {
            $cnt++;

            # local path relative or pure filename?
            $log->debug( _loc("rel path mode '%1', local='%2', anchor='%3'", $rel_mode, $local, $anchor_path ) );
            my $local_path = 
                $rel_mode eq 'file_only' ? _file( $local )->basename : 
                $rel_mode eq 'rel_path_job' ? _file( $local )->relative( $job_dir ) 
                : _file($local)->relative( $anchor_path );
            $local_path = $server->parse_vars("$local_path");
            $log->debug( _loc("rel path mode '%1', local_path=%2", $rel_mode, $local_path ) );
            
            # filters?   TODO use $self->filter_paths
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
                    $log->debug( _loc("Getting backup file from remote '%1' to '%2'", $remote, $bkp_local) );
                    push @backup_files, "$bkp_local";
                    my $bkp_dir = _file( $bkp_local )->dir->mkpath;
                    if( !$agent->file_exists( "$remote" ) ) {
                        $log->debug( _loc("No existing file detected to backup: '%1'", $remote) );
                    } else {
                        try {
                            $agent->get_file( local=>"$bkp_local", remote=>"$remote" );
                        } catch {
                            my $err = shift;
                            if( $backup_mode eq 'backup_fail' ) {
                                $log->error( _loc("Error reading backup file from remote. Ignored: '%1'", $remote), "$err" );
                                _fail _loc 'Error during file backup';
                            } else {
                                $log->warn( _loc("Error reading backup file from remote. Ignored: '%1'", $remote), "$err" );
                            }
                        };
                    }
                }
            }

            # rollback ?
            my $is_rollback_no_backup = 0;
            if( $job_mode eq 'rollback' && $rollback_mode =~ /^rollback/ ) {
                if( -e $bkp_local ) {
                    $log->debug( _loc( "Rollback switch to local file '%1'", $bkp_local ) );
                    $local = $bkp_local;
                } elsif( $rollback_mode eq 'rollback_force' ) {
                    _fail _loc 'Could not find rollback file %1', $bkp_local;
                } else {
                    $is_rollback_no_backup = 1;
                    $log->debug( _loc( "Rollback switch to local file '%1', but no for the file '%2'", $bkp_local, $remote ) );
                }
            }
            
            # ship done here
            my $local_stat   = join(",",@{ _file($local)->stat || [] }); # create a stat string
            my $local_chksum = Digest::MD5::md5_base64( scalar _file($local)->slurp );   # maybe slow for very large files, but faster than _md5
            my $local_key = "$job_exec|$local|$local_stat|$local_chksum";  # job exec included, forces reship on every exec
            my $local_key_md5 = Util->_md5( $local_key );
            $agent->copy_attrs($copy_attrs);
            my $hostname = $agent->server->hostname;
            my $sent = $sent_files->{$hostname}{$local_key_md5}{"$remote"}; 
            if( $sent && $exist_mode ne 'reship' ) {
                $log->info( _loc('File `%1` already in machine `%2` (%3). Ship skipped.', "$local", "*$hostname*".':'.$remote, $server_str ), data=>$local_key );
            } else {
                $log->info( _loc( "Sending file '%1' to '%2'", $local, "*$server_str*".':'.$remote ) );
                # create dir if not exists?
                my $remote_dir = _file($remote)->dir;
                if( $create_dir eq 'create' && !$agent->file_exists("$remote_dir") ) {
                    $agent->mkpath( "$remote_dir" );
                }
                $stash->{needs_rollback}{ $needs_rollback_key } = $job->step if $needs_rollback_mode eq 'nb_before';
                # send file remotely
                if(!$is_rollback_no_backup){
                    $agent->put_file(
                        local  => "$local",
                        remote => "$remote",
                    );
                }else{ #El fichero no existía previamente
                    $agent->delete_file(
                        server => $server_str,
                        remote => "$remote"
                    );
                }

                $sent_files->{$hostname}{$local_key_md5}{"$remote"} = _now();
            }
            $stash->{needs_rollback}{ $needs_rollback_key } = $job->step if $needs_rollback_mode eq 'nb_after';
            
            if( length $chown ) {
                _debug "chown $chown $remote";
                $agent->chown( $chown, "$remote" );
                $log->warn( _loc("Error doing a chown '%1' to file '%2': %3", $chown,$remote, $agent->output ), $agent->tuple_str ) if $agent->rc && $agent->rc!=512;
            }
            if( length $chmod ) {
                _debug "chmod $chmod $remote";
                $agent->chmod( $chmod, "$remote" );
                $log->warn( _loc("Error doing a chmod '%1' to file '%2': %3", $chmod,$remote, $agent->output ), $agent->tuple_str ) if $agent->rc && $agent->rc!=512;
            }
        }
        $log->warn( _loc( "Could not find any file locally to ship to '%1'", $server_str ), $config )
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

    my $remote_orig = $config->{remote_path} // _fail 'Missing parameter remote_file';
    my $local_orig  = $config->{local_path} // _fail 'Missing parameter local_file';
    my $user        = $config->{user};

    my $servers = $config->{server};
    for my $server ( Util->_array_or_commas($servers) ) {
        $server = ci->new( $server ) unless ref $server;
        Util->is_ci_or_fail( $server, 'server' );
        my $local  =  $server->parse_vars( "$local_orig" );
        my $remote =  $server->parse_vars( "$remote_orig" );
        my $server_str = "$user\@".$server->name;
        _debug "Connecting to server " . $server_str;
        my $agent = $server->connect( user=>$user );
        $log->info( _loc( "Retrieving file '%1' to '%2'", $local, "*$server_str".'*:'.$remote ) );
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
    _fail _loc "Could not find file '%1'", $f
        unless -e $f;
    if( unlink "$f" ) {
        $log->info( _loc("Successfully delete file '%1'", $f) ); 
    } else {
        _fail( _loc("Error deleting file '%1': %2", $f, $!) ); 
    }
}

sub run_rmtree {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;

    my $dir = $config->{dir} // _fail _loc 'Missing parameter dir';
    
    my $f = _dir( $job->job_dir, $dir );
    _fail _loc "Could not find dir '%1'", $f
        unless -d $f;
    if( $f->rmtree ) {
        $log->info( _loc("Successfully deleted directory '%1'", $f) ); 
    } else {
        _fail( _loc("Error deleting directory '%1': %2", $f, $!) ); 
    }
}

sub run_parse_config {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $config_file = $config->{config_file};
    my $fail_if_not_found  = $config->{fail_if_not_found};
    my $type = $config->{type} || 'yaml';
    my $opts = $config->{opts} || {};
    my $enc = $config->{encoding} || 'utf8';
    
    if( !-e $config_file ) {
        my $msg = _loc( "Config file not found in '%1'", $config_file );
        if( $fail_if_not_found ) {
            _fail $msg; 
        } else {
            _warn $msg;
        }
    }
    
    open my $ff, '<:'.$enc , "$config_file" 
        or _fail( _loc('Error opening config file: %1: %2', $config_file, $!) );
    my $body = do { local $/; <$ff> }; # slurp file
    if( !length $body ) {
        _fail _loc("Config file is empty: '%1'", $config_file);
        return;
    }
    my $vars = try { 
          $type eq 'yaml' ? _load( $body ) 
        : $type eq 'json' ? _decode_json( $body ) 
        : $type eq 'general' ? do { require Config::General; 
            my $f = Config::General->new(-String=>$body, %$opts );
            +{ $f->getall };
        }
        : $type eq 'ini' ? do {
            require Config::Tiny;
            my ($ini) = Config::Tiny->read_string( $body );
            return +{ %$ini } // {};
        }
        : $type eq 'props' ? do {
            require Config::Properties;
            open my $fh, '<', \$body;

            my $properties = Config::Properties->new();
            $properties->load($fh);
            my %props = $properties->properties;
            return +{ %props } // {};
        }
        : $type eq 'xml' ? do {
            require XML::Simple;
            my $xml = XML::Simple::XMLin( "$body", KeepRoot=>1, %$opts ); 
            +{ %$xml }; # convert internal xml to hash
        } : _fail(_loc('Unknown config file type: %1', $type));
    } catch {
        my $err = shift;
        _fail _loc('Error parsing config file `%1` (type %2, encoding %3): %4', $config_file, $type, $enc, $err ) ;
    };
    return $vars;
}

sub run_write_config {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $config_file = $config->{config_file};
    my $fail_if_not_found  = $config->{fail_if_not_found};
    
    my $type = $config->{type} || 'yaml';
    my $varname = $config->{varname};
    my $input_type = $config->{input_type} || 'yaml';
    my $opts = $config->{opts} || {};
    my $enc = $config->{encoding} || 'utf8';
    
    my $write_to_file = sub{
        my $body = shift; 
        open my $ff, '>:'.$enc , "$config_file" 
            or _fail( _loc('Error opening config file: %1: %2', $config_file, $!) );
        print $ff $body;
        close $ff;
    };
    
    my $data = do { 
        if( $input_type eq 'var' ) {
            my $varname = $config->{varname} || _fail(_loc('Missing config file data variable name'));
            $$stash{$varname} or _fail _loc("Config data is missing from stash: %1", $varname );;
        } else {
            $config->{config_data};
        }
    };
    
    my $body = try { 
          $type eq 'yaml' ? do {
             Util->_dump( $data ); 
          }
        : $type eq 'json' ? do{ 
            Util->_encode_json( $data );
        }
        : $type eq 'general' ? do { require Config::General; 
            require Config::General;
            Config::General->new(-ConfigHash=>$data, %$opts )->save_string;
        }
        : $type eq 'ini' ? do {
            require Config::Tiny;
            my $ct = Config::Tiny->new;
            _fail _loc 'Config data is not a hash' unless ref $data eq 'HASH';
            # recursively create a ini compatible structure
            my $loadhash;
            $loadhash = sub{
                my ($sec,$out,$in) = @_;
                for my $k ( keys $in ) {
                    #warn "$sec, K=$k";
                    if( ref $$in{$k} eq 'HASH' ) {
                        $loadhash->(($sec eq '_'?$k:"$sec.$k"),$out,$$in{$k});
                    } else {
                        $out->{$sec}{$k} = $$in{$k};
                    }
                }
            };
            $loadhash->('_',$ct,$data);
            $ct->write_string;
        }
        : $type eq 'xml' ? do {
            require XML::Simple;
            XML::Simple::XMLout( $data, %$opts ); 
        } 
        : _fail(_loc('Unknown config file type: %1', $type));
    } catch {
        my $err = shift;
        _fail _loc('Error writing config file `%1` from variable `%2` (type %3, encoding %4): %5', 
            $config_file, $varname, $type, $enc, $err ) ;
    };
    $write_to_file->( $body );
    return '';
}


1;
