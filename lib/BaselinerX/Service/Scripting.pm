package BaselinerX::Service::Scripting;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;
with 'Baseliner::Role::Service';


register 'service.scripting.remote' => {
    name => 'Run a remote script',
    form => '/forms/script_remote.js',
    handler => \&run_remote,
};

sub run_remote {
    my ($self, $c, $stash ) = @_;
    my ($server,$user,$home, $path,$args, $stdin) = @{ $stash }{qw/server user home path args stdin/};
    $server = _ci( $server ) unless ref $server;
    _log "===========> RUNNING remote script `$path $args` ($user\@". $server->name . ')';
    
    # Destination runs scripts
    #my $dest = BaselinerX::CI::destination->new( user=>$user, server=>$server );
    #$dest->execute( $path, $args );
    
    # Script CI runs scripts
    #my $script = BaselinerX::CI::script->new( path=>$path, args=>$args, user=>$user, server=>$server );
    #$script->execute;
    #$script->save;
    
    my $agent = $server->connect( user=>$user );
    $agent->execute;
    my $out = $agent->output;
    my $rc = $agent->rc;
    my $ret = $agent->ret;
    
    { out=>$out, rc=>$rc, ret=>$ret };
}

1;
