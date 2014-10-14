package Baseliner::Model::Daemons;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub list {
    my ( $self, %p ) = @_;
    
    my $query = {};
    $query->{active} = defined $p{active} ? $p{active} : '1';
    $p{all} and delete $query->{active};

    if(defined $p{disp_id}){
        $query = {
            '$or' => [
                { 'instances.instance' => { '$in'     => [ $p{disp_id}, undef, [] ] } },
                { instances => { '$exists' => 0 } },
                { instances => [] }
            ]
        };
    }elsif(defined $p{no_id}){
#        $query->{'instances.instance'} = {'$nin' => [ $p{no_id} ]};
        $query = {
                'instances.instance' => { '$nin'     => [ $p{no_id} ] }, 
                instances => { '$nin' => [undef,[]] }
        };

    }

    my @daemons = mdb->daemon->find($query)->all;
    return @daemons;
}

=head2 request_start_stop

Changes the db status of the daemon, but relies on the corresponding 
host dispatcher to start or stop the process.

=cut
sub request_start_stop {
    my ( $self, %p ) = @_;
    my $id = mdb->oid($p{id});
    my $action = $p{action};
    mdb->daemon->update(
        {_id => $id},
        {   '$set' => {
                active => $action eq 'start' ? '1' : '0'
            }
        });
}

=head2 service_start

Start a separate perl process for a background service.

    services=>['service.name', 'service.name2', ... ]
    params  => {  job_id=>111, etc=>'aaa' }

=cut
sub service_start {
    my ( $self, %p ) = @_;

    my @services = Util->_array_all( $p{services}, $p{service} );
    my $disp_id = $p{disp_id};
    $self->mark_as_pending( id=>$p{id}, disp_id => $p{disp_id} );

    _throw 'No service specified' unless @services;

    my %params = Util->_array_all( $p{params}, $p{param} );

    my @started;
    for my $service_name ( @services ) {
        my $params = join ' ', map { "$_=$params{$_}" } keys %params;
        $params .= '--id '.$disp_id;
        my $cmd = "perl $ENV{BASELINER_PERL_OPTS} $0 $service_name $params";
        _debug "Starting service background command '$cmd'";
        my $proc = Proc::Background->new($cmd)
          or _throw "Could not start service $service_name: $!";
        push @started,
          {
            service => $service_name,
            pid     => $proc->pid,
            disp_id    => $disp_id,
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

    my @services = Util->_array_all( $p{services}, $p{service} );
    $self->mark_as_pending( id=>$p{id}, disp_id => $p{disp_id});

    _throw 'No service specified' unless @services;

    my $disp_id = $p{disp_id};
    my %params = Util->_array_all( $p{params}, $p{param} );
    my $params = join ' ', map { "$_=$params{$_}" } keys %params;

    my @started;
    for my $service_name ( @services ) {
        my $pid = fork;
        unless( $pid ) {
            $SIG{HUP} = 'DEFAULT';
            $SIG{TERM} = 'DEFAULT';
            $SIG{STOP} = 'DEFAULT';
            $0 = "perl $ENV{BASELINER_PERL_OPTS} $0 $service_name $params";
            _debug "Model/Daemons.pm: --- Starting service forked command '$0'";
            if( exists $p{frequency} ) { 
                while(1) {
                    Baseliner->launch( $service_name, data=>\%params );
                    sleep $p{frequency};
                }
            } else {
                Baseliner->launch( $service_name, data=>\%params );
            }
            exit 0;  #FIXME this leaves zombies behind - use POSIX::_exit() instead?
        }
        push @started,
          {
            service => $service_name,
            pid     => $pid,
            disp_id    => $disp_id,
            owner   => $ENV{USER} || $ENV{USERNAME}
          };
    }
    return @started;
}

=head2 kill_daemon $daemon [, $signal]

Just kill it. Optionally 'kill it' with a signal. 

=cut
sub kill_daemon {
    my ( $self, $daemon, $signal, $disp_id ) = @_;

    $signal ||= 9;
    $self->mark_as_pending( id=>$daemon->{_id}.'' );

    my ($instance) = grep { $_->{disp_id} eq $disp_id} _array $daemon->{active_instances};

    if( kill $signal,$instance->{pid} ) {
        mdb->daemon->update(
            {_id => $daemon->{_id} },
            {   '$pull' => {
                    active_instances => {disp_id => $disp_id }
                }
            });
        _log "Daemon " . $daemon->{service} . " stopped";
    } else {
        _log "Could not kill daemon "
            . $daemon->{service}
            . " with pid "
            . $instance->{pid};
    }
}

=head2 mark_as_pending

Put the pid field to -1 to indicate that the daemon is either starting or stopping.

=cut
sub mark_as_pending {
    my ($self, %p) = @_;

    my $instance = mdb->daemon->find_one({_id => mdb->oid($p{id}),'active_instances.disp_id' => $p{disp_id}});
    if ( $instance ) {
        my $rs = mdb->daemon->update(
                {_id => mdb->oid($p{id}),'active_instances.disp_id' => $p{disp_id}},
                {   '$set' => {
                        'active_instances.$.last_ping' => mdb->ts,
                        'active_instances.$.pid' => '-1',
                        'active_instances.$.status' => 'pending'
                    }
                });
    }
}

1;
