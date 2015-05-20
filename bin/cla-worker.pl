#!/usr/bin/env perl

use strict;
use Redis;
use FindBin '$Bin';
use File::Spec;
use File::Path qw/rmtree mkpath/;
use MIME::Base64;
use JSON::PP;
use YAML::Tiny;
use Storable;
use Encode;
use DateTime::Tiny;
use File::Copy qw(copy);
use Time::HiRes qw/gettimeofday tv_interval/;
use Capture::Tiny;
use Try::Tiny;
use Term::ANSIColor qw(:constants);

select(STDERR);
$| = 1;
select(STDOUT); 
$| = 1;

our $t0 = [gettimeofday];
our $workerid;
our %conf;
our $id_has_pid = 0;

# logging functions
sub _log { 
    my $elapsed = tv_interval ( $t0 );
    my $msg = $_[0];
    local $main::log_error=1 if $msg=~/^ERROR/;
    my ($pre,$post) =  $main::log_error ? (RED,RESET) 
        : $main::log_warn ? (YELLOW,RESET) 
        : $main::log_debug ? (GREEN,RESET)
        :('','');
    my $ts = _now();
    print $pre, sprintf("[${workerid}%s $ts %0.4f] ", ( $id_has_pid ? '' : " $$"), $elapsed), @_, $post, "\n"; 
    $t0 = [gettimeofday];
}
sub _error { local $main::log_error = 1; _log( @_ ) }
sub _warn { local $main::log_warn = 1; _log( @_ ) }
sub _debug { return unless $conf{verbose}; local $main::log_debug= 1; _log( @_ ) }
sub _now {
    DateTime::Tiny->now(); #time_zone=>_tz);
}

# main command
our $CMD = $ARGV[0] !~ /^-/ ? shift @ARGV : 'start';
$CMD =~ s/-+/_/g;
$CMD='start' unless length $CMD;

# any args?
my $lastopt;
my %ARGV = map { $lastopt=~/^--?/ && $_=~/^--?/ ? (1, $lastopt=$_) : ($lastopt=$_)  } @ARGV;
$ARGV{$lastopt} = 1 if $lastopt =~ /^--?/; # last option does not get 1 otherwise

my %args;  # nice hasheable args
while( my ($k,$v) = each %ARGV ) {
    $k =~ s/^--?//g;
    $k =~ s/-+/_/g;
    $args{$k} = $v;
}

print "Clarive Worker v6.2\n" unless $args{h};

# config
my $script_home = Cwd::realpath( $Bin );
my $config_file = $ARGV{'--config'} || File::Spec->catfile($script_home,'cla-worker.conf');

require Sys::Hostname;
#use Config;$Config{intsize},
%conf = (
    host           => Sys::Hostname::hostname(),
    user           => getlogin(),
    started_on     => DateTime::Tiny->now() . '',
    script_home    => $script_home,
    encode_format  => 'yaml',
    os             => $^O,
    arch           => ( $^O =~ /win/i 
        ? do{ use Config; $Config{"archname"} } 
        : do{ $a=`uname -m`; chomp $a; $a } ), 
    home           => $script_home,
    pid_dir        => $script_home,
    log_dir        => $script_home,
    pid            => $$,
    verbose        => 0,
    server         => 'localhost:6379',
    timeout        => 600,
    reconnect_wait => 5,
    chunk_size     => 64 * 1024,
    timeout_file   => 1, # seconds
    daemon         => 0,
);
if( -e $config_file ) {
    print "config_file: $config_file\n" unless $args{h};
    open my $fc,'<:encoding(utf-8)', $config_file or die "ERROR: could not open config file: $!\n";
    local $/;
    my $yaml = <$fc>; 
    %conf = ( %conf, %{ Load( $yaml ) || {} } );
}
# merge args
%conf = ( %conf, %args );
my $conf_json = encode_msg( \%conf );

# globals
#my $choose_defined = sub { defined $_ and return $_ for @_ };
$workerid = $conf{id} || do {
    $id_has_pid = 1;
    sprintf '%s@%s/%d', $conf{user}, $conf{host}, $conf{pid};
};
$conf{id} = $workerid;
( my $workerid_clean = $workerid ) =~ s/[^-_\w]+/_/g;
$workerid_clean =~ s/_+/_/g;
$conf{pid_file} ||= File::Spec->catfile( $conf{pid_dir}, "cla-worker-$workerid_clean.pid" );
$conf{log_file} ||= File::Spec->catfile( $conf{log_dir}, "cla-worker.log" );
our ($reconnect_wait, $timeout_file, $daemon, $pid_file, $log_file, $timeout, $chunk_size ) = 
    @conf{ qw/reconnect_wait timeout_file daemon pid_file log_file timeout chunk_size/ };

our @capabilities;
push @capabilities, "$conf{user}\@$conf{host}";
if( ref $conf{capabilities} eq 'ARRAY' ) {
    push @capabilities, @{ $conf{capabilities} };
}
if( my $cans = $conf{can} ) {
    push @capabilities, split /,/, $conf{can};
}
@capabilities = sort keys %{ +{ map { $_ => undef } @capabilities } };

# usage ?
if( exists $ARGV{'-h'} || exists $ARGV{'--help'} ) {
    usage();
    exit 1;
}

# run command: start, stop
our ($redis, $queue); 
{
    no strict 'refs';
    *{ "main::$CMD" }->();
    exit 0;
}

sub start {
    print "cla-worker starting with id '$workerid', pid $$\n";
    my $recon_count = 1;
    # connect
    CONNECT:
    print "connecting to server $conf{server}...";
    $redis = try {
        Redis->new( 
            server=>$conf{server},
            encoding => undef,
            on_connect => sub {
                print "db connected";
            }
        );
    } catch {
        my $err = shift;
        print "\n";
        _error "ERROR connecting to Redis (db): $err";
        my $mult = int log $recon_count;  # wait a little longer logarithmically
        my $wait = $mult > 2 ? $reconnect_wait*$mult : $reconnect_wait;
        _log "Retrying connection in $wait seconds...";
        sleep $wait;
        $recon_count++;
        goto CONNECT;
    };

    $queue = try {
        Redis->new(
            server     => $conf{server},
            encoding   => undef,
            on_connect => sub {
                print ", queue connected.\n";
            }
        );
    } catch {
        my $err = shift;
        print "\n";
        _error "\nERROR connecting to Redis (db): $err";
        my $mult = int log $recon_count;  # wait a little longer logarithmically
        my $wait = $mult > 2 ? $reconnect_wait*$mult : $reconnect_wait;
        _log "Retrying connection in $wait seconds...";
        sleep $wait;
        $recon_count++;
        goto CONNECT;
    };
    
    $recon_count = 1; # reset logarithm 
    
    # check if someone has this id already
    $queue->subscribe("queue:pong:$workerid", sub {
        my ($msg, $topic, $subscribed_topic) = @_;
        my $d = decode_json( $msg ) if $msg;
        return if $$ eq $d->{pid};
        die WHITE ON_RED, "FATAL:", RESET," there's another worker with id `$workerid` in the network (me=$$):\n", Dump($d);
    });
    $redis->publish( "queue:$workerid:ping", '' );
    # wait 1 sec for an answer and unsubscribe?
    $queue->wait_for_messages(1);
    $queue->unsubscribe("queue:pong:$workerid", sub{});  # XXX not working?

    # daemonize?
    if( $daemon ) {
        print "pid_file: $pid_file\n";
        print "log_file: $log_file\n";
        if( -e $pid_file ) {
            my $pid = read_pid( $pid_file );
            # check if proc exists
            if( kill 0 => $pid ) {
                die "FATAL: pid file '$pid_file' already exists.\n" 
            } else {
                unlink $pid_file;
            }
        }
        my $pid = fork();
        die "can't fork: $!" unless defined $pid;
        if( $pid ) {
            print "forked daemon with pid $pid\n"; 
            open my $fp,'>', $pid_file or die "FATAL: could not open pid file '$pid_file': $!\n";
            print $fp $pid;
            close $fp;
            exit 0;
        }
        # child
        require POSIX;
        POSIX::setsid(); 
        log_shorten();
        open STDIN, '/dev/null' or die "Could not redirect STDIN: $!";
        open STDOUT, '>>', $log_file or die sprintf "Could not redirect STDIN to %s: $!", $log_file;
        open STDERR, '>&STDOUT' or die "Could not redirect STDERR: $!";
    }

    # register and announce
    _log "registering worker $workerid";
    $redis->hset( 'queue:workers', $workerid, $conf_json );
    _log "announcing $workerid";
    $redis->publish( 'queue:worker:new', $workerid );

    _log "subscribing to work queue";
    $queue->psubscribe("queue:$workerid:*", sub {
        my ($msg, $topic, $subscribed_topic) = @_;
        _log "got message with topic=$topic";
        # process
        process_message( $msg, $topic, $subscribed_topic );
    });

    # register for capabilities searches
    if( @capabilities ) {
        _log "capabilities announced: " . join ',', @capabilities;
        #my @keys = map { "queue:capability.$_" } @capabilities;
        $queue->psubscribe( 'queue:capability:*', sub {
            my ($msg, $topic, $subscribed_topic) = @_;
            my $reqid = ( split /:/, $topic )[2];
            my $caps = decode_base64( $msg );
            _debug "got request for capabilities: $caps";
            my @caps = split /,/,$caps; 
            my %all_caps = map { $_ => 1 } @capabilities;
            if( scalar( grep {defined} @all_caps{@caps}) == scalar @caps ) {
                # send requester that I'm ok
                _log "responding capable of $caps (reqid=$reqid)";
                #$redis->publish( "queue:capable:$cap", $workerid );
                $redis->rpush( "queue:capable:$reqid", $workerid );
            }
        });
    }

    # loop on messages
    _log "waiting for messages, restarting each $timeout seconds";
    while( 1 ) {
        try {
            $queue->wait_for_messages($timeout);
        } catch {
            my $err = shift;
            _log "ERROR waiting for messages: $err";
            if( $err =~ /__try_read_sock/ ) {
                _log "diag: redis server down? Retrying connection in $reconnect_wait seconds...";
                sleep $reconnect_wait;
                goto CONNECT;  # start over
            }
        };
        _log "done waiting, restarting again." if $conf{verbose};
    }
}

sub stop {
    my $pid = read_pid( $pid_file );
    print "stopping worker id $workerid with pid $pid...\n";
    my $sig = $conf{sig} || 'HUP';
    my $ret = kill $sig => $pid; 
    print $ret ? "stopped.\n" : "ERROR during shutdown: $!\n";
    unlink $pid_file;
    exit !$ret;
}

sub stop_all {
    print "looking for pid files in $conf{home} and/or $conf{pid_dir}...\n";
    my $rc = 0;
    my $k = 0;
    for my $pf( sort keys %{ +{ map { $_=>1 } <$conf{home}/cla-worker-*.pid $conf{pid_dir}/cla-worker-*.pid> } } )  {
        $k ||= 1;
        print "stopping daemon with pid file $pf...\n";
        my $pid = read_pid( $pf );
        my $sig = $conf{sig} || 'HUP';
        my $ret = kill $sig => $pid; 
        if( $ret ) {
            print "stopped daemon with pid $pid\n";
        } else {
            print "could not stop daemon with pid $pid: $!\n";
        }
        unlink $pf;
        $rc += !$ret;
    }
    print YELLOW, "no pid files found.\n" unless $k;
    exit !$k ? 1 : $rc;
}

sub ps {
    print "cla-worker processes:\n";
    my @ps = `ps -ef`;
    for my $pr ( grep /cla-worker/, @ps ) {
        my @pp = grep { length } split /\s+/, $pr;
        next if $pp[1] == $$;
        print $pr;
    }
    exit 0;
}

sub capabilities {
    print "worker capabilities:\n";
    for my $cap ( @capabilities ) {
        print "   - $cap\n";        
    }
}

sub config {
    print "worker config:\n";
    print Dump( \%conf );
}

###################################

sub log_shorten {
    my ($file) = @_;
    system tail => -1000 => $file => ">$file.new"; 
    unlink $file;
    copy "$file.new" => $file;
}

sub read_pid {
    my ($pid_file) = @_;
    open my $fp, '<', $pid_file or die "FATAL: could not open pid_file $pid_file: $!\n";
    my $pid = join '', <$fp>;
    $pid =~ s/[^0-9]*//g;
    close $fp;
    return $pid; 
}

sub process_message {
    my ($msg, $topic, $subscribed_topic) = @_;
    my ($ns, $workerid, $cmd, $id_msg) = ( split /:/, $topic );
    # send ack
    $redis->publish( "queue:$id_msg:start",'' ); 
        
    # start payload
    _log "start: $topic ($cmd): msg bytes=" . length($msg);  
    _debug "CMD       =$cmd";
    _debug "CMD DATA  =$msg";
    my ($ret, $rc);
    my $t1 = [gettimeofday];
    # run command
    my $output = try {
        Capture::Tiny::tee_merged( sub {
            $ret = run_cmd( $cmd, $workerid, $id_msg, $msg );
            $rc = $?;
        });
    } catch {
        my $err = shift;
        $rc = 99;
        $ret = '';
        $err;
    };
    # finalize
    _debug "CMD RC    =$rc";
    _debug "CMD RET   =$ret";
    _debug "CMD OUTPUT=$output";
    my $result = {
        ret    => $ret,     # ret value from command
        rc     => $rc,      # return code
        output => $output,  # stdout + stderr 
    };
    _log sprintf "$cmd DONE in %0.4fs", tv_interval $t1;
    $redis->set( "queue:$id_msg:result", encode_msg( $result ) );
    $redis->publish( "queue:$id_msg:done", '' );
}

sub run_cmd {
    my ($cmd, $workerid, $id_msg, $msg)=@_;
    #_log "command=$cmd, id_msg=$id_msg";
    $msg = try { decode_json( $msg ) } catch { $msg };
    if( $cmd eq 'eval' ) {
        my ($code,$stash) = ($msg->{code}, $msg->{stash});
        my $ret = eval $code;
        #die $@ if $@;
        return $@ || $ret;
    }
    elsif( $cmd eq 'put_file' ) {
        _log "writing file: $msg->{filepath}" if $conf{verbose};
        open my $ff, '>:raw', $msg->{filepath} or do{
            my $msg = "error writing file `$msg->{filepath}`: $!" ;
            _log $msg;
            $? = -1;
            return { error=>$msg };
        };
        my $key = "queue:$id_msg:file";
        my $k = 1;
        while( my $chunk = $redis->blpop( $key, $timeout_file ) ) {
            # chunk 0: key, 1: data
            print $ff decode_base64( $chunk->[1] );
            #print $ff join '', pack 'H*', $chunk->[1]; #decode_base64( $chunk->[1] );
        }
        close $ff;
        _log "done writing file: $msg->{filepath}" if $conf{verbose};
        my $stat = stat $msg->{filepath};
        $? = 0;
        return { stat => $stat };
    }
    elsif( $cmd eq 'get_file' ) {
        open my $ff, '<:raw', $msg->{filepath} or do{
            my $msg = "error reading file `$msg->{filepath}`: $!" ;
            _log $msg;
            $? = -1;
            return { error=>$msg };
        };

        my $chunk = '';
        my $bytes = 0;
        while( sysread $ff, $chunk, $chunk_size ) {
            $redis->rpush( "queue:$id_msg:file", encode_base64($chunk) );
            $bytes += length( $chunk );
        }
        close $ff;
        $? = 0;
        return $bytes;
    }
    elsif( $cmd eq 'ping' ) {
        $redis->publish( "queue:pong:$workerid", encode_msg( \%conf ) );
    }
    else {
        die "cla-worker: Invalid command: $cmd\n";
    }
}

sub aborted {
    my ($code)=@_;
    print "Aborted (code=$code)\n";
    #print "More info using: tail -200 '$ENV{LOGFILE}'\n";
    exit $code;
}

sub encode_msg {
    my ($d) = @_;
    # json: has problems with utf8, storable: may hit incompatible version binaries
    return $conf{encode_format} eq 'yaml' 
        ? 'yaml:' . Dump( $d )  
        : $conf{encode_format} eq 'stor'
            ? 'stor:' . Storable::freeze( $d )
            : encode_json( $d );
}

exit 0;
########## main end

sub usage {
    print banner();
    print qq{usage: cla-worker command <options>
    
commands available:
        start                starts a new worker
        stops                stops a daemon worker
        stop-all             stops all daemon workers (from *.pid files)
        capabilities         lists capabilities
        config               display worker config
        ps                   lists all worker processes
        
options:
        --server             host and port of the queue server: localhost:6379
        --id                 client id
        --daemon             fork a daemon worker
        --host               hostname to report to queue
        --user               username to report to queue
        --timeout            timeout secs waiting for messages (default=$conf{timeout})
        --reconnect-wait     seconds to wait in between reconnection attempts (default=$conf{reconect_wait})
        --log_file           path to log file
        --pid-file           path to pid file
        --log-file           path to log file
        --sig                signal to kill daemons (default=HUP)
        --can                list of comma separated capabilities

examples:

    cla-worker start --server 192.168.1.2:6379 
    cla-worker stop 
    curl -fsL http://clarive.com/downloads/cla-worker | perl - start --server 192.168.1.2:6379 --id centos
    
};
}

sub tpl_eval {
    my $s = shift;
    $s =~ s/(\<%(.*?)%\>)/eval("$2")/eg;
    return $s;
}

sub banner {
q{

    88888888  888          8888      888888888    88  888      888   8888888   
   888888888  888          88888     8888888888   88  888     888   8888888888 
  888         888         888888     88     888   88   888    888  888     888 
  88          888         888 888    88     888   88   888   888   88       888
 888          888        888  888    8888888888   88    888  888   888888888888
  88          888        888888888   88888888     88    888 888    888888888888
  888         888       8888888888   88    888    88     888888    888         
   888888888  888888888 888     888  88     888   88     88888      8888888888 
    88888888  888888888888      888  88      888  88      8888       888888888 

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Clarive Worker v6.2 - Copyright (c) 2015 clarive.com

}
}


