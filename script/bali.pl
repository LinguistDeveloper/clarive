use strict;
use warnings;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib"; 
use Hash::Merge::Simple qw/merge/;

chdir "$FindBin::Bin/..";

#
# auto flush
#
select(STDERR); $|=1;
select(STDOUT); $|=1;

BEGIN { $ENV{BALI_CMD} = 1; }  # prevents controllers from loading

$SIG{TERM} = sub { die "Baseliner process $$ stopped." };

if( !@ARGV ) {
    require Baseliner;

    my $version = Baseliner->config->{About}->{version};
    print "Baseliner $version\n";
    #TODO list service name, if available and perl package
    my @serv = sort Baseliner->registry->starts_with('service');
    print "===Available services===\n", join( "\n", @serv ), "\n";
    exit 0;
}

my @argv = @ARGV;
my $service_name = shift @ARGV;
my @argv_noservice = @ARGV;

if( $service_name =~ /(stop|kill)/ ) {
    stop( $1 );
    exit 0; 
}
elsif( $service_name =~ /^start$/i ) {
    my $rc = start();
    exit $rc;
}
elsif( $service_name =~ /^ps$/i ) {
    ps();
    exit 0;
}
elsif( $service_name =~ /^shut|shutdown$/i ) {
    shut();
    exit 0;
}

print "Starting $service_name...\n";
use Baseliner;
#my $c = Baseliner->commandline;
my $c = bless { stash=>{} } => 'Baseliner';
use Baseliner::Utils;

my $ns = '/';
my $bl = '*';
my %opts = _get_options( @argv_noservice );
$c->stash->{ns} = $ns;
$c->stash->{bl} = $bl;

@ARGV = @argv_noservice;

## get service
if( 1 ) { 
    $opts{ arg_list } = { map { $_ => () } keys %opts }; # so that we can differentiate between defaults and user-fed data
    $opts{ args } = \%opts;
    my $logger = Baseliner->model('Services')->launch($service_name, %opts, data=>\%opts );
    exit $logger->rc;
} else {  # deprecated, in favor of the Services model
    my $service = $c->registry->get($service_name) || die "Could not find service '$service_name'";
    my $config = $c->registry->get( $service->config ) if( $service->config );
    my $config_data;
    if( $config ) {
        #$config_data = { %{$config_data||{}}, %{ $config->getopt ||{}} };
        #$config_data = $config->factory( $c, ns=>$ns, bl=>$bl, getopt=>1 );
        $config_data = $config->factory( $c, ns=>$ns, bl=>$bl, data=>{ %opts } );
    } else {
        $config_data = { %opts };
    }

    # run the service
    my $logger = $service->run( $c, $config_data );
    exit $logger->rc;
}

#pod2usage(1) if $help;
sub ps {
    my @ps = `ps uwwx`;
    for( grep /baseliner_|bali\./, @ps ) {
        chomp;
        next if /$$/;
        print "$_\n";
    }
    exit 0;
}

sub stop {
    my $mode = shift;
    $service_name = shift @ARGV;
    $service_name =~ s{service\.}{}g;
    $0 = '';
    print "Looking for service 'service.$service_name'...\n";
    my $found;
    my @ps = grep /bali\.pl/, `ps uwwx`;
    for( @ps ) {
        if( /(service\.)*$service_name/ ) {
            my @fields = split /[\t|\s]+/;
            my $pid = $fields[1];
            if( $pid ) {
                my $msg = ( $mode eq 'stop' ? 'Stopping ' : 'Killing ' ) . "$pid...\n";
                print $msg;
                kill 1,$pid if $mode eq 'stop';
                kill 9,$pid if $mode eq 'kill';
                $found=1;
            }
        } 
    }
    print $found ? "Done.\n" : "No processes found.\n";
}

sub start {
    print "Starting $ARGV[0] as a daemon...\n";
    my $args = "'" . join( "' '", @ARGV) . "'";  #"
    my $ret = `nohup perl -X script/bali.pl $args >$ENV{BASELINER_LOGHOME}/balid.log 2>&1 &`;
    my $rc = $?;
    print $ret;
    print $rc ? "Error $rc during startup: $ret" : "Started.\n";
    return $rc;
}

sub shut {
    my @ps = `ps uwwx`;
    my $killed=0;
    for( grep /baseliner_|bali\./, @ps ) {
            my @fields = split /[\t|\s]+/;
            my $pid = $fields[1];
            next if $pid eq $$;
            kill 9,$pid if $pid;
            $killed++;
    }
    if( $killed ) {
        print "Baseliner Shutdown. $killed processes shutdown.\n";
    } else {
        print "No Baseliner processes found.\n";
    }
}
