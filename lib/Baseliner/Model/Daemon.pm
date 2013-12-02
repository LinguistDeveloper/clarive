package Baseliner::Model::Daemon;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub list {
    my ( $self, %p ) = @_;
    
    my $query = {};
    $query->{active} = defined $p{active} ? $p{active} : 1;
    $p{all} and delete $query->{active};

    my @daemons = Baseliner->model('Baseliner::BaliDaemon')->search($query)->all;
    return @daemons;
}

=head2 service_start

Start a separate perl process for a background service.

    services=>['service.name', 'service.name2', ... ]
    params  => {  job_id=>111, etc=>'aaa' }

=cut
sub service_start {
    my ( $self, %p ) = @_;

    my @services = _array $p{services}, $p{service};

    _throw 'No service specified' unless @services;

    my %params = _array $p{params}, $p{param};

    my @started;
    for my $service_name ( @services ) {
        my $params = join ' ', map { "$_=$params{$_}" } keys %params;
        my $cmd = "perl $0 $service_name $params";
        _debug "Starting service background command '$cmd'";
        my $proc = Proc::Background->new($cmd)
          or _throw "Could not start service $service_name: $!";
        push @started,
          {
            service => $service_name,
            pid     => $proc->pid,
            host    => Util->my_hostname,
            owner   => $ENV{USER} || $ENV{USERNAME}
          };
    }
    return @started;
}

=head2 service_start_forked

Pure forking service starter. See service_start for options. 

=cut
sub service_start_forked {
    my ( $self, %p ) = @_;

    my @services = _array $p{services}, $p{service};

    _throw 'No service specified' unless @services;

    my %params = _array $p{params}, $p{param};
    my $params = join ' ', map { "$_=$params{$_}" } keys %params;

    my @started;
    for my $service_name ( @services ) {
        my $pid = fork;
        unless( $pid ) {
            $SIG{HUP} = 'DEFAULT';
            $SIG{TERM} = 'DEFAULT';
            $SIG{STOP} = 'DEFAULT';
            $0 = "perl $0 $service_name $params";
            _debug "Model/Daemon.pm: --- Starting service forked command '$0'";
            Baseliner->launch( $service_name, data=>\%params );
            exit 0;  #FIXME this leaves zombies behind - use POSIX::_exit() instead?
        }
        push @started,
          {
            service => $service_name,
            pid     => $pid,
            host    => Util->my_hostname,
            owner   => $ENV{USER} || $ENV{USERNAME}
          };
    }
    return @started;
}

1;
