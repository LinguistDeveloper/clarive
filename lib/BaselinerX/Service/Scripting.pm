package BaselinerX::Service::Scripting;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;
use utf8::all;
with 'Baseliner::Role::Service';


register 'service.scripting.local' => {
    name => 'Run a local script',
    form => '/forms/script_local.js',
    handler => \&run_local,
};

register 'service.scripting.remote' => {
    name => 'Run a remote script',
    form => '/forms/script_remote.js',
    handler => \&run_remote,
};

register 'service.scripting.remote_eval' => {
    name => 'Run a remote eval',
    form => '/forms/eval_remote.js',
    data => { server=>'', code=>'' },
    handler => \&run_eval,
};

sub run_local {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;

    my ($user,$home,$path,$args,$stdin) = @{ $config }{qw/user home path args stdin/};
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
        $job->logger->error( _loc('Error running command %1', join ' ', @cmd), $r ); 
    } else {
        $job->logger->info( _loc('Finished command %1' , join ' ', @cmd ), $r ); 
    }
    return $r;
}

sub run_remote {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    
    my ($server,$user,$home, $path,$args, $stdin) = @{ $config }{qw/server user home path args stdin/};
    $server = _ci( $server ) unless ref $server;
    _log "===========> RUNNING remote script `$path $args` ($user\@". $server->hostname . ')';
    
    my $agent = $server->connect( user=>$user );
    $agent->execute( $path, _array($args) );
    my $out = $agent->output;
    my $rc = $agent->rc;
    my $ret = $agent->ret;
    if( $rc ) {
        _fail _loc 'Error during script (%1) execution: %1', $path, $out // 'script not found or could not be executed (check chmod or chown)';
    }
    
    { output=>$out, rc=>$rc, ret=>$ret };
}

sub run_eval {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    
    my ($server, $user, $code) = @{ $config }{qw/server user code/};
    $server = _ci( $server ) unless ref $server;
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
            $log->info( _loc('Eval ok'), data=>{ output=>$out, rc=>$rc, ret=>$ret } );
        }
}
    
    { output=>$out, rc=>$rc, ret=>$ret };
}

1;
