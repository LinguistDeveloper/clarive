package BaselinerX::Service::Scripting;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;
use utf8::all;
use Encode qw(encode decode);
with 'Baseliner::Role::Service';

our $ICON_DEFAULT = '/static/images/icons/step_run.png';

register 'service.scripting.local' => {
    name => 'Run a local script',
    form => '/forms/script_local.js',
    icon => $ICON_DEFAULT,
    job_service  => 1,
    handler => \&run_local,
};

register 'service.scripting.remote' => {
    name => 'Run a remote script',
    form => '/forms/script_remote.js',
    icon => $ICON_DEFAULT,
    job_service  => 1,
    handler => \&run_remote,
};

register 'service.scripting.remote_eval' => {
    name => 'Eval Remote',
    form => '/forms/eval_remote.js',
    data => { server=>'', code=>'' },
    icon => $ICON_DEFAULT,
    job_service  => 1,
    handler => \&run_eval,
};

sub run_local {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $fail_on_error = $config->{fail_on_error} // 1;
    my $output_files = $config->{output_files};
    
    # rollback basics
    my $task  = $stash->{current_task_name};
    my $needs_rollback_mode = $config->{needs_rollback_mode} // 'none'; 
    my $needs_rollback_key = $config->{needs_rollback_key} // $task;

    my ($user,$home,$path,$args,$stdin) = @{ $config }{qw/user home path args stdin/};
    my $environment = $config->{environment} // {};
    $args ||= [];
    require Capture::Tiny;
    my $rc;
    my $ret;
    my $orig;
    if( $home ) {
        _fail _loc "Could not change dir to directory `%1`: does not exist", $home unless -e $home;
        $orig = Cwd::cwd;
        chdir $home;
        _log "CHDIR $home";
    }
    my @cmd = ($path, _array( $args ) );
    $job->logger->info( _loc('Running command: %1', join ' ', @cmd), \@cmd ); 
    $stash->{needs_rollback}{ $needs_rollback_key } = 1 if $needs_rollback_mode eq 'nb_before';
    my ($out) = Capture::Tiny::tee_merged(sub{ 
        local %ENV = ( %ENV, %$environment );
        $ret = system @cmd ;
        $rc = $?;
    });
    if( $home ) {
        chdir $orig;
        _log "CHDIR $orig";
    }

    $out = encode("utf8",$out);
    my $r = { output=>$out, rc=>$rc, ret=>$ret };

    if( $rc ) {
        my $msg = _loc('Error running command %1', join ' ', @cmd);
        $job->logger->error( $msg , qq{RC: $rc\nRET: $ret\nOUTPUT: $out} ); 
        $self->publish_output_files( 'error', $job, $output_files );
        _fail $msg if $fail_on_error; 
    } else {
        $self->publish_output_files( 'info', $job,$output_files );
        $self->check_output_errors($stash, ($fail_on_error ? 'fail' : 'error'),$log,$out,$config);
        $job->logger->info( _loc('Finished command %1' , join ' ', @cmd ), qq{RC: $rc\nRET: $ret\nOUTPUT: $out} ); 
    }
    $stash->{needs_rollback}{ $needs_rollback_key } = 1 if $needs_rollback_mode eq 'nb_after'; # only if everything went alright
    return $r;
}

sub publish_output_files {
    my ($self, $lev, $job, $output_files ) = @_;
    for my $file ( _array( $output_files ) ) {
        if( !-e $file ) {
            _debug "Output file not found: $file";
        } else {
            my $f = _file($file);
            my $body = $f->slurp;
            my $bn = $f->basename;
            $job->logger->$lev( "Output File: $bn", data => $body, data_name => $bn );
        }
    }
}

sub run_remote {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;

    my $errors = $config->{errors} || 'fail';
    
    my @rets;
    my ($servers,$user,$home, $path,$args, $stdin, $output_error, $output_warn, $output_capture, $output_ok) = 
        @{ $config }{qw/server user home path args stdin output_error output_warn output_capture output_ok/};
        
    # rollback basics
    my $task  = $stash->{current_task_name};
    my $needs_rollback_mode = $config->{needs_rollback_mode} // 'none'; 
    my $needs_rollback_key = $config->{needs_rollback_key} // $task;
    
    $args ||= [];
    for my $server ( Util->_array_or_commas($servers)  ) {
        $server = ci->new( $server ) unless ref $server;
        Util->is_ci_or_fail( $server, 'server' );
        if( !$server->active ) {
            $log->warn( _loc('Server %1 is inactive. Skipped', $server->name) );
            next;
        }
        my $path_parsed = $server->parse_vars( $path );
        my $args_parsed = $server->parse_vars( $args );
        for my $hostname ( _array( $server->hostname ) ) {
            my $dest = $user . '@' . $hostname;
            $log->info( _loc( "STARTING remote script %1: '%2'", $dest, $path_parsed . ' '. join(' ',_array($args_parsed)) ), 
                { config => $config, dest => $dest });
        }
        
        my $agent = $server->connect( user=>$user );
        $stash->{needs_rollback}{ $needs_rollback_key } = 1 if $needs_rollback_mode eq 'nb_before';
        $agent->execute( { chdir=>$home }, $path_parsed, _array($args_parsed) );
        my $out = $agent->output;
        my $rc = $agent->rc;
        my $ret = $agent->ret;
        
        my $lev_custom = '';
        if( $errors eq 'custom' ) {
            $lev_custom = 'warn' if length $config->{rc_warn} && List::MoreUtils::any { Util->in_range($_, $config->{rc_warn}) } _array($rc);
            $lev_custom = 'fail' if length $config->{rc_error} && List::MoreUtils::any { Util->in_range($_, $config->{rc_error}) } _array($rc);
            # OK resets any previous error
            $lev_custom = 'silent' if length $config->{rc_ok} && List::MoreUtils::any { Util->in_range($_, $config->{rc_ok}) } _array($rc);
            _debug( _loc('Custom error detected: %1 (rc=%2)', $lev_custom, join(',',map { $_ } _array($rc)) ) );
        }
        
        if( ($errors eq 'custom' && $lev_custom ) || List::MoreUtils::any {$_} _array($rc) ) {
            my $ms = _loc 'Error during script (%1) execution: %2', $path_parsed, ($out // 'script not found or could not be executed (check chmod or chown)');
            Util->_fail($ms) if $errors eq 'fail' || $lev_custom eq 'fail';
            Util->_warn($ms) if $errors eq 'warn' || $lev_custom eq 'warn';
            Util->_debug($ms) if $errors eq 'silent' || $lev_custom eq 'silent';
        } else {
            my $tuple = $agent->tuple_str;
            my $output = $agent->output;
            # check for output errors and warnings
            #   if we find an output ok, then ignore all other errors
            $self->check_output_errors($stash,$errors,$log,$output,$config);
            $log->info( _loc( "FINISHED remote script %1: '%2'", $user . '@' . $server->hostname, $path_parsed . join(' ',_array($args_parsed)) ), 
                $agent->tuple_str );
        }
        push @rets, { output=>$out, rc=>$rc, ret=>$ret };
        $stash->{needs_rollback}{ $needs_rollback_key } = 1 if $needs_rollback_mode eq 'nb_after';  # after only one ok, needs rollback
    }
    return @rets > 1 ? \@rets : $rets[0];
}

sub check_output_errors {
    my ($self, $stash, $error_mode, $log, $output, $config)=@_;
    
    my $ignore_errors = 0;
    my ($output_ok, $output_error, $output_warn, $output_capture) = @{$config}{qw(output_ok output_error output_warn output_capture)}; 
    OUT_OK: for my $ook ( _array($output_ok) ) {
        if( my @match = ( $output =~ _regex($ook) ) ) {
           my %found = %+;
           $log->info( _loc('Output ok detected by `%1` (errors will be ignored): %2', $ook, %found ? _encode_json(\%found) : join(',',@match) ) );
           $ignore_errors = 1;
           last OUT_OK;
        }
    }
    for my $oerr ( _array($output_error) ) {
        if( my @match = ( $output =~ _regex($oerr) ) ) {
           my %found = %+;
           $log->error( _loc("Output error detected by '%1': %2", $oerr, %found ? _encode_json(\%found) : join(',',@match) ), data=>$output );
           _fail _loc 'Output error detected' if $error_mode eq 'fail' && !$ignore_errors;
        }
    }
    for my $owarn ( _array($output_warn) ) {
        if( my @match = ( $output =~ _regex($owarn) ) ) {
           my %found = %+;
           $log->warn( _loc("Output error detected by '%1': %2", $owarn, %found ? _encode_json(\%found) : join(',',@match) ), data=>$output );
        }
    }
    for my $ocap ( _array($output_capture) ) {
        if( $output =~ _regex($ocap) ) {
           my %found = %+;
           for( keys %found ) {
               $log->debug( _loc("Captured from output '%1' into stash '%2'", $ocap, $_) );
               $stash->{$_} = $found{$_};
           }
        }
    }
}

sub run_eval {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    my ($servers, $user, $code) = @{ $config }{qw/server user code/};
    my @rets;
    for my $server ( Util->_array_or_commas($servers)  ) {
        $server = ci->new( $server ) unless ref $server;
        Util->is_ci_or_fail( $server, 'server' );
        if( !$server->active ) {
            $log->warn( _loc('Server %1 is inactive. Skipped', $server->name) );
            next;
        }
        _log _loc "===========> RUNNING remote eval: %1\@%2", $user, $server->hostname ;
        
        my $agent = $server->connect( user=>$user );
        # TODO some agents may not support eval, check this out first, call exec instead?
        $agent->remote_eval( $code );
        my $out = $agent->output;
        my $rc = $agent->rc;
        my $ret = $agent->ret;
        if( $rc == 99 ) {
            _fail _loc 'Error during eval execution: %1', $out;
        } else {
            if( ref $ret eq 'HASH' && ref $ret->{job_logs} eq 'ARRAY' ) {
                for my $msg ( @{$ret->{job_logs}} ) {
                    my $lev = $msg->{lev} // 'info';
                    $log->$lev( _loc( $msg->{text} // '(no message)' ), $msg->{data} );
                }
            } else {
                $log->debug( _loc('return'), $agent->ret );
                $log->info( _loc('output'), $agent->output );
            }
        }
        push @rets, $ret;
    }
    
    #{ output=>$out, rc=>$rc, ret=>$ret };
    return @rets > 1 ? \@rets : $rets[0];
}

1;
