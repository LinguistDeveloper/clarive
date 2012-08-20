package BaselinerX::CA::Harvest::Service::ApprovalSend;
use Baseliner::Plug;
use Baseliner::Utils;

use utf8;

with 'Baseliner::Role::Service';

##register 'action.harvest.approve' => { name=>'Approve packages in Harvest' };

register 'service.harvest_approval.send' => {
    name => 'Post Job step of a Job that checks if an approval is needed',
    handler => \&run,
};

register 'service.harvest_approval.post' => {
    name => 'Post Promote step of a Job that checks if an approval is needed',
    handler => \&run_post,
};

sub run {
    my ( $self, $c, $p ) = @_;
	#_check_parameters( $p, qw/username package bl project state/ );
   
	my $job = $c->stash->{job};
	my $log = $job->logger;
    my $bl = $job->job_data->{bl};
	my $contents = $job->job_stash->{contents};

    if( $bl ne 'PREP' ) {
        $log->info("Entorno no necesita aprobación");
        return;
    }

    $log->debug( "----------------------Verificando si hay aprobaciones para $bl" );
	if( $job->rollback ) {
    } else {
		foreach my $job_item ( _array $contents ) {
			my $item = $job_item->{item};
			my $ns_package = $c->model('Namespaces')->get( $item ); 
			next unless ref $ns_package;
			next unless $ns_package->isa('BaselinerX::CA::Harvest::Namespace::Package');

			# group packages by application:state
            my $ns = $ns_package->application;
            my $package = $ns_package->ns_data->{packagename}; 
			my $env = $ns_package->environmentname;
			my $state = $ns_package->state; 
			$log->debug( _loc('Aplicacion %1, Estado %2 para el paquete %3', $env, $state, $package ) );
            my $comments = "Paquete promocionado en pase " . $job->{id};

            # find if it's in a release

            # ask for approval
            Baseliner->model('Request')->request(
                    name   => "Aprobación del item $item->{ns_name} en la aplicación $env",
                    action => 'action.harvest.approve',
                    data   => {},
                    callback => 'service.harvest.approval.callback',
                    #template => 'email/package_approval.html',
                    vars   => { reason=>$comments },
                    username => $p->{username},
                    #TODO role_filter => $p->{role},    # not working, no user selected??
                    ns     => $ns,
                    bl     => $p->{bl}, 
            );
        }
    }
}

sub run_post {
    my ( $self, $c, $p ) = @_;
	#_check_parameters( $p, qw/username package bl project state/ );

    my $username = $p->{username};
    my $project = $p->{project};
    my $app = substr( $project, 0,8 );
    my $package = $p->{package};
    my $rfc = substr( $package, 5 );
    $rfc =~ s{\@..}{}g;
    my $to_state = $p->{to_state};
    my $ns = 'harvest.package/' . $package;

    _log "Solicitando aprobación para $package en $ns...";
   
    Baseliner->model('Request')->request(
            name   => "Aprobacion del paquete $package en $to_state ($app)",
            action => 'action.harvest.approve',
            data   => { reason=>"Promocion a $to_state", app=>$app, rfc=>$rfc, user=>$username, items=>$package },
            callback => 'service.harvest.approval.callback',
            #template => 'email/package_approval.html',
            vars   => { reason=>"Promocion a $to_state", app=>$app, rfc=>$rfc, user=>$username, items=>$package },
            username => $username,
            #TODO role_filter => $p->{role},    # not working, no user selected??
            ns     => $ns,
            bl     => $p->{bl}, 
    );
}


1;

