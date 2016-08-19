package BaselinerX::Service::WindowsService;
use Moose;

use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_fail _loc _locl);

with 'Baseliner::Role::Service';

register 'service.scripting.windows_service' => {
    name        => _locl('Windows Service'),
    form        => '/forms/windows_service.js',
    icon        => '/static/images/icons/services_new.png',
    job_service => 1,
    handler     => \&run_windows_service,
};

sub run_windows_service {
    my ( $self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;

    my $errors = $config->{errors} || 'fail';
    my $action = $config->{action} || 'start';
    my $service = $config->{service};
    my $servers = $config->{server};
    my $user    = $config->{user};

    for my $server ( Util->_array_or_commas($servers) ) {
        $server = ci->new($server) unless ref $server;

        Util->is_ci_or_fail( $server, 'server' );

        if ( !$server->active ) {
            $log->warn( _loc( 'Server %1 is inactive. Skipped', $server->name ) );
            next;
        }

        my $agent = $server->connect( user => $user );

        if ( $action eq 'start' ) {
            $self->_start( $agent, $service, $errors, $log );
        }
        elsif ( $action eq 'stop' ) {
            $self->_stop( $agent, $service, $errors, $log );
        }
        elsif ( $action eq 'restart' ) {
            $self->_stop( $agent, $service, $errors, $log );

            $self->_start( $agent, $service, $errors, $log );
        }
    }

    return $self;
}

sub _start {
    my $self = shift;
    my ( $agent, $service, $errors, $log ) = @_;

    if ( $self->_is_running( $agent, $service ) ) {
        $log->info( _loc( "Service `%1` is already running", $service ) );
        return;
    }

    my $out = $agent->execute(qq{net start $service /y});

    if ( !$self->_is_success($out) ) {
        my $error = _loc( "Service `%1` starting failed: %2", $service, $out->{output} );

        if ( $errors eq 'fail' ) {
            _fail $error;
        }
        elsif ( $errors ne 'silent' ) {
            $log->info($error);
        }
    }
    else {
        $log->info( _loc( "Service `%1` started", $service ) );
    }
}

sub _stop {
    my $self = shift;
    my ( $agent, $service, $errors, $log ) = @_;

    if ( !$self->_is_running( $agent, $service ) ) {
        $log->info( _loc( "Service `%1` is already stopped", $service ) );
        return;
    }

    my $out = $agent->execute(qq{net stop $service /y});

    if ( !$self->_is_success($out) ) {
        my $error = _loc( "Service `%1` stopping failed: %2", $service, $out->{output} );

        if ( $errors eq 'fail' ) {
            _fail $error;
        }
        elsif ( $errors ne 'silent' ) {
            $log->info($error);
        }
    }
    else {
        $log->info( _loc( "Service `%1` stopped", $service ) );
    }
}

sub _is_running {
    my $self = shift;
    my ( $agent, $service ) = @_;

    my $is_running = $agent->execute(qq{sc query $service | findstr RUNNING});
    if ( $is_running && $is_running->{output} && $is_running->{output} =~ m/RUNNING/ ) {
        return 1;
    }

    return 0;
}

sub _is_success {
    my $self = shift;
    my ($out) = @_;

    if ( $out->{rc} && ( !$out->{output} || $out->{output} !~ m/was .*? successfully/ ) ) {
        return 0;
    }

    return 1;
}

1;
