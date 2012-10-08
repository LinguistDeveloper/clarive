package BaselinerX::CA::Harvest::Service::ApprovalDaemon;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

use utf8;

with 'Baseliner::Role::Service';

register 'config.harvest_approval' => {
    name => 'Approval Check and Daemon configuration',
    metadata => [
        { id=>'cycle', label=>'The Harvest Approval Lifecyle', type=>'hash' },
        { id=>'frequency', name=>'Email daemon frequency', default=>10 },
        { id=>'active', name=>'Approvals activation flag', default=>0 },
    ]
};

register 'service.harvest_approval.daemon' => {
    name => 'Email Daemon',
    config => 'config.harvest.approval',
    handler => \&daemon,
};

register 'service.harvest_approval.check' => {
    name => 'Approval Check',
    config => 'config.harvest.approval',
    handler => \&check_approvals,
};

sub daemon {
    my ( $self, $c, $config ) = @_;

    my $frequency = $config->{frequency};
    while( 1 ) {
        $self->check_approvals( $c, $config );
        sleep $frequency;
    }
}

sub check_approvals {
    my ( $self, $c, $config ) = @_;

    # get projects with approval enabled
    my @projects;
    my %done;
    my $rs = $c->model('Harvest::Harenvironment')->search({ envisactive=>'Y' },{ order_by=>'environmentname' });
    while( my $env = $rs->next ) {
        my $envname = $env->environmentname;
        my $ns = 'application/' . BaselinerX::CA::Harvest::Project::get_apl_code( $envname );
        next unless $ns;
        #next if exists $done{$ns}; $done{$ns}=();
        _log "Chequeando si están activadas las aprobaciones para $ns...";
        my $config = $c->model('ConfigStore')->get('config.harvest.approval', ns=>$ns); 

        # add to active list
        if( $config->{active} ) {
            _log "$ns - approval checks active";
            push @projects, { env=>$env, envname=>$envname, ns=>$ns, config=>$config };
        }
    }

    _log( "No hay aprobaciones activadas para ninguna aplicación. Terminado."),return unless @projects;

    #TODO put this in the config
    my %action_for_state = (
            'Pruebas Integradas' => 'action.approve.pruebas_integradas',
            'Pruebas Aceptación' => 'action.approve.pruebas_aceptacion',
            'Pruebas Sistemas'   => 'action.approve.pruebas_sistemas',
    );

    # now get candidate packages
    my @candidates;
    for my $project ( @projects ) {

        my %transitions;

        # list project packages
        my $rs = $c->model('Harvest::Harpackage')->search({ envobjid=>$project->{env}->envobjid },);
        while( my $package = $rs->next ) {
            my $pkg = $package->packagename ;
            _log "Processing package: " . $pkg . "\n";
            
            # check its single approval status
            my $ns_package = 'harvest.package/' . $package->packagename;
            my $paq = $c->model('Namespaces')->get( $ns_package );
            my $reqs = $c->model('Baseliner::BaliRequest')->search(
                {
                    action => { -like => 'action.approve.%' },
                    status => { '<>'  => 'cancelled' },
                    ns     => $ns_package
                },
                { order_by => 'id desc' }
            );
            $reqs->result_class('DBIx::Class::ResultClass::HashRefInflator');
            if( my $req = $reqs->next ) { # only the first one matters
                _log "Package $pkg approval status=" . _dump( $req );

                if( $req->{status} eq 'approved' ) {
                    # where was it approved 
                    # check if next state matches
                    my $curr_state = $paq->state;
                    _log "Current state: " . $curr_state;
                    my $data = _load $req->{data};
                    my $where = $data->{state};
                    my $cycle = $project->{config}->{cycle};
                    #my $cycle = $c->model('ConfigStore')->get('config.harvest.approval.cycle', bl=>'PREP');
                    try {
                        $cycle = eval "{$cycle}" unless ref $cycle eq 'HASH';
                    } catch { };
                    _log "Lifecycle: ". _dump $cycle;
                    _log "Where approved: " . $where;
                    if( $where eq $curr_state ) {
                        my $next_state = $cycle->{ $curr_state }->{promote};
                        _log "Promote needed to " . $next_state; 
                    }

                }
            } else {
                _log "No status found for $pkg. Requesting approval...";
                my $bl = '*';
                my $row_hist = $package->harpkghistories->search(undef, { order_by => 'execdtime desc' })->first;
                my $hist_state = $row_hist->statename; 
                my $hist_action = $row_hist->action; 
                my $username = $row_hist->user->username; 
                my $rfc = substr($pkg, 5, 8) ;
                _log "Last event: action $hist_action in state $hist_state";

                # find action for current state
                my $action = $action_for_state{ $hist_state };
                _log "Role action for this approval: $action";
                _throw "No action found for current state" unless $action;
                #my $rs = $c->model('Harvest::Harpkghistory')->search({ packageobjid=>
                try {
                    my $message  = _loc('Requesting Approval for %1', $pkg);
                    my @users    = users_with_permission $action;
                    Baseliner->model('Request')->request(
                            name   => "$hist_state",
                            action => $action,
                            data   => { rfc=>$rfc, project=>$project->{envname}, app=>$project->{envname}, state=>$hist_state },
                            callback => 'service.harvest.approval.callback',
							template_engine => 'mason',
                            template => 'email/approval.html',
                            username => $username,
                            ns     => $ns_package,
                            bl     => $bl,
                            vars     => {
                                reason  => '',
                                message => $message,
                                subject => $message,
                                to      => [ @users ],
                                url     => _notify_address(),
                            },
                    );
                } catch {
                    #try-catch, if cannot request, inform the package owner - group of error
                };
            }
            # save its release approval status
            push @candidates, $package;
        }
    }


    # list packages for apps with approval 
	my $reqs = $c->model('Baseliner::BaliRequest')->search({ action=>'action.harvest.approve', status=>{ '<>' => 'cancelled' } }, { order_by=>'id desc' });
	while( my $req = $reqs->next ) {
	}

    # traverse pending releases, and check its content status
}

1;
