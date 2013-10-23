package BaselinerX::Service::Scripting;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;
use utf8::all;
with 'Baseliner::Role::Service';

our $ICON_DEFAULT = '/static/images/icons/step_run.png';

register 'service.scripting.local' => {
    name => 'Run a local script',
    form => '/forms/script_local.js',
    icon => $ICON_DEFAULT,
    handler => \&run_local,
};

register 'service.scripting.remote' => {
    name => 'Run a remote script',
    form => '/forms/script_remote.js',
    icon => $ICON_DEFAULT,
    handler => \&run_remote,
};

register 'service.scripting.remote_eval' => {
    name => 'Eval Remote',
    form => '/forms/eval_remote.js',
    data => { server=>'', code=>'' },
    icon => $ICON_DEFAULT,
    handler => \&run_eval,
};

sub run_local {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $fail_on_error = $config->{fail_on_error} // 1;
    my $output_files = $config->{output_files};

    my ($user,$home,$path,$args,$stdin) = @{ $config }{qw/user home path args stdin/};
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
    my ($out) = Capture::Tiny::tee_merged(sub{ 
        $ret = system @cmd ;
        $rc = $?;
    });
    if( $home ) {
        chdir $orig;
        _log "CHDIR $orig";
    }
    my $r = { output=>$out, rc=>$rc, ret=>$ret };
    if( $rc ) {
        my $msg = _loc('Error running command %1', join ' ', @cmd);
        $job->logger->error( $msg , $r ); 
        $self->publish_output_files( $job, $output_files );
        _fail $msg if $fail_on_error; 
    } else {
        $self->publish_output_files( $job,$output_files );
        $job->logger->info( _loc('Finished command %1' , join ' ', @cmd ), $r ); 
    }
    return $r;
}

sub publish_output_files {
    my ($self, $job, $output_files ) = @_;
    for my $file ( _array( $output_files ) ) {
        if( !-e $file ) {
            _debug "Output file not found: $file";
        } else {
            my $f = _file($file);
            my $body = $f->slurp;
            my $bn = $f->basename;
            $job->logger->info( "Output File: $bn", data => $body, data_name => $bn );
        }
    }
}

sub run_remote {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $stmt  = $stash->{current_statement_name};

    my $errors = $config->{errors} || 'fail';
    
    my @rets;
    my ($servers,$user,$home, $path,$args, $stdin) = @{ $config }{qw/server user home path args stdin/};
    $args ||= [];
    for my $server ( split /,/, $servers ) { 
        $server = ci->new( $server ) unless ref $server;
        for my $hostname ( _array( $server->hostname ) ) {
            $log->info( _loc( '*%1* STARTING remote script `%2` (%3)', $stmt, $path . ' '. join(' ',_array($args)), $user . '@' . $hostname ), $config );
        }
        
        my $agent = $server->connect( user=>$user );
        $agent->execute( { chdir=>$home }, $path, _array($args) );
        my $out = $agent->output;
        my $rc = $agent->rc;
        my $ret = $agent->ret;
        if( List::MoreUtils::any {$_} _array($rc) ) {
            my $ms = _loc '*%1* Error during script (%2) execution: %3', $stmt, $path, ($out // 'script not found or could not be executed (check chmod or chown)');
            Util->_fail($ms) if $errors eq 'fail';
            Util->_warn($ms) if $errors eq 'warn';
            Util->_debug($ms) if $errors eq 'silent';
        } else {
            my $tuple = $agent->tuple_str;
            $log->info( _loc( '*%1* FINISHED remote script `%2` (%3)', $stmt, $path . join(' ',_array($args)), $user . '@' . $server->hostname ), $agent->tuple_str );
        }
        push @rets, { output=>$out, rc=>$rc, ret=>$ret };
    }
    return @rets > 1 ? \@rets : $rets[0];
}

sub run_eval {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $stmt  = $stash->{current_statement_name};
    
    
    my ($servers, $user, $code) = @{ $config }{qw/server user code/};
    my @rets;
    for my $server ( split /,/, $servers ) {
        $server = ci->new( $server ) unless ref $server;
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
                $log->debug( _loc('%1 (ret)', $stmt), $agent->ret );
                $log->info( _loc('%1 (output)', $stmt), $agent->output );
            }
        }
        push @rets, $ret;
    }
    
    #{ output=>$out, rc=>$rc, ret=>$ret };
    return @rets > 1 ? \@rets : $rets[0];
}

1;
