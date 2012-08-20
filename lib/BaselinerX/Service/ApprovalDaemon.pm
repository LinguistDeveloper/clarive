package BaselinerX::Service::ApprovalDaemon;
=head1 DESCRIPTION

Daemon that checks if packages and releases need approval.

=cut
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

use utf8;

with 'Baseliner::Role::Service';

# configuration
register 'config.approval' => {
    name => 'Approval Check and Daemon configuration',
    metadata => [
        { id=>'frequency', name=>'Email daemon frequency', default=>10 },
        { id=>'active', name=>'Approvals activation flag', default=>0 },
        { id=>'cycle', label=>'Approval Lifecyle', type=>'hash',
            default=> qq{{
                start => { action=>'action.approve.pruebas_integradas', bl=>'PREP' },
                'action.approve.pruebas_integradas' => { action=>'action.approve.pruebas_aceptacion', bl=>'PREP' },
                'action.approve.pruebas_aceptacion' => { action=>'action.approve.pruebas_sistemas', bl=>'PREP' },
            }
        }},
    ]
};

# daemon
register 'service.approval.daemon' => {
    name => 'Approval Daemon',
    config => 'config.approval',
    handler => \&daemon,
};

# run once
register 'service.approval.check' => {
    name => 'Approval Check',
    config => 'config.approval',
    handler => \&check_approvals,
};

sub daemon {
    my ( $self, $c, $config ) = @_;

    my $frequency = $config->{frequency};
    _log "Starting approval daemon with frequency ${frequency}s";
    for( 1..200 ) {
        $self->check_approvals( $c, $config );
        # enforce pending
        Baseliner->model('Request')->enforce_pending if $config->{active};
        # make sure all requests have a project relationship
        sleep $frequency;
    }
    _log 'Approval deamon stopping.';
}

sub check_approvals {
    my ( $self, $c, $config ) = @_;

    my $bl = 'PREP';
    my $inf = $c->model('ConfigStore')->get('config.approval', bl=>$bl); #TODO cycle thru Baselines

    unless( $inf->{active} ) {
        _log _loc ">>> WARNING: Approvals are not active (config.approval.active=0) for the baseline '%1'", $bl;
        return -1;
    }

    if( ref $inf->{cycle} ne 'HASH' ) {
        _log "Approval Cycle variable is incorrect. Approval checking skipped.";
        return;
    }

    # now get candidate packages
    my @candidates;
    _log "Looking for elements needing approval in PREP...";
    my $list = Baseliner->model('Namespaces')->list(
        does => ['Baseliner::Role::Approvable', 'Baseliner::Role::Namespace::Package' ],
        bl   => 'PREP',
    );
    _log "No elements found for approval" unless ref $list;

    for my $ns ( $list->list ) {
        my $name = $ns->ns_name;
        my $rs_releases = Baseliner->model('Baseliner::BaliReleaseItems')->search({ 'me.ns'=>$ns->ns },{ prefetch=>'id_rel' });
        if( my $count = $rs_releases->count ) {
            _debug "Item '$name' is in $count releases. Requests will be handled by the releases. Skipped.";
            next;
        }

        # get the approval lifecycle
        my $cycle = $inf->{cycle};

        # check its single approval status
        my $reqs = $c->model('Baseliner::BaliRequest')->search(
            {
                action => { -like => 'action.approve.%' },
                status => { '<>'  => 'cancelled' },
                ns     => $ns->ns,
            },
            { order_by => 'id desc' }
        );
        $reqs->result_class('DBIx::Class::ResultClass::HashRefInflator');

        my $next_action;
        #_log "Start review of ". $ns->ns;

        # if it has a latest request 
        if( my $req = $reqs->next ) { # only the first one matters
            #_log "Finished review of ". $ns->ns;
            if( $req->{status} eq 'approved' ) {
                # where was it approved 
                # check if next state matches
                my $lastaction = $req->{action};
                # _log "Last action was: $lastaction";
                my $data = _load $req->{data};
                # _log "Lifecycle: ". _dump $cycle;
                $next_action = $cycle->{ $lastaction }->{action};
            }
            #rejected - send message is handled at the Request model level on rejection
            #         maybe move it here?
        } else {  # no request ever, or cancelled
            # find start action 
            $next_action = $cycle->{ 'start' }->{action};
            _log "No start action found" unless $next_action;

            # save its release approval status 
            push @candidates, $ns;
        }

        if( $next_action ) {
            my $action   = $c->model('Registry')->get($next_action);
            _log "Next action is: $next_action";
            _log "No status found for $name. Requesting approval...";

            my $bl = 'PREP'; #TODO 
            my $rfc = try { $ns->rfc } catch { '' };
            my $app = try { $ns->application } catch { '' };
            $app = ( ns_split( $app ) )[1];
            my $state = 'PREP'; #TODO 

            # find the user from last job, or package owner, or release creator
            my $last_job = Baseliner->model('Jobs')->top_job( item=>$ns->ns, bl=>$bl ); 
            my $username = ref $last_job ? $last_job->username : $ns->user || 'internal';
            my $reason = ref $last_job ? $last_job->comments : $action->{name};

            _log "Role action for this approval: $action->{name} ($next_action)";

            try {
                _log "Requesting for $name...";
                my $new_req = Baseliner->model('Request')->request(
                    name         => $action->{name},
                    action       => $next_action,
                    requested_by => $username,
                    data         => {
                        rfc     => $rfc,
                        project => $app, #FIXME not used, could be the harvest project though
                        app     => $app,
                        state   => $state,
                        reason  => $reason,
                        ts      => _now(),
                    },
                    template    => '/email/approval.html',
                    template_engine => 'mason',
                    ns          => $ns->ns,
                    bl          => $bl,
                );
                $ns->active(1);
                _log _loc( "Request %1 created", $new_req->id );
            } catch {
                #TODO try-catch, if cannot request, inform the package owner - group of error
                my $err = shift;
                _log _loc("Error creating request: %1", $err );
                _log "Notifying admins that this is not working";	
                my $subject =_loc("Error creating a request for %1", $name );
                my $msg = Baseliner->model('Messaging')->notify(
                    subject  => $subject,
                    sender   => 'internal',
                    to       => { action=>'action.notify.error' },
                    carrier  => 'email',
                    template => 'email/error.html',
                    vars     => {
                        status        => _loc('Request Error'),
                        username      => $username,
                        subject       => $subject,
                        description   => $err,
                        template      => "/email/error.html",
                    }
                );
                #_throw 'Interrupted but shoudnt';
            };
        }
    }

    # list packages for apps with approval 
    #my $reqs = Baseliner->model('Baseliner::BaliRequest')
    #	->search(
    #		{ action=>'action.harvest.approve', status=>{ '<>' => 'cancelled' } },
    #		{ order_by=>'id desc' }
    #	);
    #while( my $req = $reqs->next ) {
    #}

    # traverse pending releases, and check its content status
}

# del all
register 'service.approval.delete_all' => {
    name => 'Delete Requests',
    handler => sub {
        my ($self,$c,$p)=@_;
        my $rs = Baseliner->model('Baseliner::BaliRequest')->search( $p );
        while( my $r = $rs->next ) {
            $r->delete;
        }
    }
};

1;

