package BaselinerX::Service::DeployFromStash;
=head1 NAME

BaselinerX::DeployFromStash - Service to deploy from the deployment stash and local files

=head1 DESCRIPTION

This service deploys local files or directories stashed
in the job stash as C<deployments>. 

It also runs scripts from C<deployment_scripts>.

Usage:

    push @{ $job->job_stash->{deployments}->{my_group} }, {
          origin => [ '/path/file.txt', '/home/tmp/dir' ],
          destination => 'ssh://host:port/remote_dest/dir',
    }

The service will detect and automatically deploy these during RUN.

=cut
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.deploy.stash' => {
    name => 'Deploy Stashed Files',
    handler => \&deploy_from_stash,
};

use constant DOMAIN => 'deploy.local';

sub deploy_from_stash {
    my ($self, $c, $config ) = @_;
    
    my $job = $c->stash->{job};
    my $log = $job->logger;
    my $job_stash = $job->job_stash;
    my $job_root = _dir( $job->root );
   
    $self->deployments( $c, $config );
    $self->deploy_scripts( $c, $config );
}

sub deployments {
    my ($self, $c, $config ) = @_;
    my $log = $self->log;
    my $job_stash = $self->job->job_stash;

    ref $job_stash->{deployments} eq 'HASH'
        ? $log->info( _loc( "Deployments detected"), dump=>$job_stash->{deployments} )
        : do { $log->debug( _loc "No Deployments detected. Skipped" ); return };

    require Baseliner::Core::Deployment;
    for my $group ( keys %{  $job_stash->{deployments} } ) {
        $log->info( _loc("Deployment files for group %1", $group ), dump=>$job_stash->{deployments}->{$group});
        for my $deployment ( _array $job_stash->{deployments}->{$group} ) {
            # rollback?
            next if $self->job->rollback && ! $deployment->{needs_rollback} ;

            _debug "Deployment " . _dump $deployment ;
            ref $deployment->{scripts} or do {
                $deployment->{scripts} = [];
                $log->debug( _loc( "*resetting* deployment scripts - they were unset" ) );
            };
            ref $deployment eq 'HASH' and $deployment = Baseliner::Core::Deployment->new( $deployment );
            my $name = $deployment->destination->uri;
            $log->info( _loc( "Running deployment: %1", $name ), dump=>$deployment );
            $deployment->destination->throw_errors( 0 );  # I'll catch them myself
            my %vars;
            $vars{bl} = $self->job->bl;
            $deployment->push_vars( %vars );

            # now deploy and run scripts
            $deployment->deploy_and_run( callback=>sub {
                my ($ret, $f) = @_;
                if( $ret->rc ) {
                    $log->error( _loc("Deployment error for %1", $name ), data=>$ret->output, milestone => 1, data_name => 'Deployment_error_'.$name.'.txt' );
                    _throw _loc( "Error during deployment %1", $name );
                } else {
                    my $file_or_script = ref $f =~ /Path::Class/ ? $f->basename : "$f";
                    $log->info( _loc("Deployment ok for *%1* - %2", $name, $file_or_script ), data=>$ret->output );
                }
            });

            $deployment->{needs_rollback} = 1;

            $log->info( _loc( 'Deployed %1 files/dirs to `%2`', $deployment->count, $deployment->destination->uri ) ); 
        }
    }
}

=head2 deploy_scripts

Execute scripts from the stash.

    push @{ $job->job_stash->{deployment_scripts}->{'my.service.domain'} }, 
        Baseliner::CI->new( 'ssh_script://user@host:port/path/script.sh?arg=aaa&arg=bbb' );

Important: entries need to be keyed from source.

=cut
sub deploy_scripts {
    my ($self, $c, $config ) = @_;
    my $log = $self->log;
    my $job_stash = $self->job->job_stash;
    my $count = 0;

    ref $job_stash->{deployment_scripts} eq 'HASH' && 0 < keys %{  $job_stash->{deployment_scripts} }
        ? $log->info( _loc( "Deployments Scripts detected"), dump=>$job_stash->{deployment_scripts} )
        : do { $log->debug( _loc "No Deployments scripts detected. Skipped" ); return };

    for my $group ( keys %{  $job_stash->{deployment_scripts} } ) {
        $log->info( _loc("Deployment scripts for group *%1*", $group ) );
        for my $d ( _array $job_stash->{deployment_scripts}->{$group}  ) {
            # rollback?
            next if $self->job->rollback && ! $d->{needs_rollback} ;

            $count++;
            # load module
            eval 'require ' . ref $d;  # load module
            $@ and _throw _loc( "Error loading module %1", $@ );
            # get a nice name
            my $name = $d->uri;
            _debug "Deployment script $name";
            $log->info( _loc( "Running Deployment script %1...", $name ) );
            $d->throw_errors( 0 );  # I'll catch them myself
            $d->run();
            if( $d->rc ) {
                $log->error( _loc("Deployment script error for %1", $name ), data=>$d->output, milestone => 1, data_name => $name.'.txt' );
                _throw _loc( "Error during deployment script %1", $name );
            } else {
                $log->info( _loc("Deployment scripts ok for *%1*", $name), data=>$d->output, milestone => 1, data_name => $name.'.txt' );
            }
            $d->{needs_rollback} = 1;
        }
    }
    $log->info( _loc( 'Finished running %1 scripts', $count ) ); 
}

1;
