package BaselinerX::Service::ItemDeploy;
=head1 NAME

BaselinerX::Service::ItemDeploy - Services to deploy job items

=head1 DESCRIPTION

This service will deploy job elements (items).

    projects: 
        - /
    bl: *
    workspace: /  (basedir)
    include:
        - /xxx/bar/\.js$
    exclude:
        - /xxx/bar/\.js$
    destinations:
        - ssh://aaa/dir/dir
    scripts_single:    (one for each file)
        - ssh_script://aaa/dir/dir
    scripts_multi:     (once for all)
        - ssh://aaa/dir/dir
    order: 1

=cut
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Node;
use Baseliner::Sugar;
use Try::Tiny;
with 'Baseliner::Role::Service';

register 'service.deploy.item.prepare' => {
    name => 'Prepare Elements to Deploy',
    handler => \&prepare,
};

use constant DOMAIN => 'deploy.item';

=head1 METHODS

=head2 prepare

Main prepare service. Finds mappings and stashes them
for later deployment.

=cut
sub prepare {
    my ($self,$c,$config) = @_;

    my $job = $c->stash->{job};
    ref $self->job || $self->job( $job );
    ref $self->log || $self->log( $job->logger );

    my $log = $job->logger;
    my $job_stash = $job->job_stash;

    my %nodes;
    my @mappings = $self->mappings;
    $log->debug( _loc( "Item Deploy Mappings"), data=>\@mappings );

    $log->info( _loc "*Item Deploy* nature started" );

    # cleanup
    if( ref $job_stash->{deployments} eq 'HASH' )  {
        delete $job_stash->{deployments}->{ DOMAIN() } ;
    } else { $job_stash->{deployments} = {} } 
    if( ref $job_stash->{deployment_scripts} eq 'HASH' ) {
        delete $job_stash->{deployment_scripts}->{ DOMAIN() } ;
    } else { $job_stash->{deployment_scripts} = {} }
    # group projects into each mapping
    my @workspaces = $self->select_mappings( mappings=>\@mappings );

    $log->info( _loc "*Item Deploy* nature finished" );
}

=head2 mappings 

Get all mappings from DB.

=cut
sub mappings {
    my ($self, %p ) = @_;
    my @m = map { $_->kv } kv->find( provider => DOMAIN )->all;
    # sort by order
    #@m = sort { $_->{order} <=> $_->{order} } @m;
    return wantarray ? @m : \@m;
}

=head2 select_mappings

Check which mappings match.

=cut 
sub select_mappings {
    my ($self, %args ) = @_;
    my $job = $self->job;
    my $log = $self->log;
    my $job_stash = $self->job->job_stash;

    # all job elements
    my $elements = $job_stash->{elements};					
    # job root directory
    my $job_root = _dir $self->job->root;
    _throw _loc( "Invalid job_root %1", $job_root ) unless -d $job_root;
    my @mappings = _array $args{mappings}; 
    my @workspaces;
    for my $m ( @mappings ) {
        next unless $m->{bl} eq '*' || $m->{bl} eq $job->bl;

        #$m->{ignore} = [ split /;/, $m->{ignore} ] unless ref $m->{ignore};
        #$m->{classpath} = [ split /;/, $m->{classpath} ] unless ref $m->{classpath};
        #$m->{deployments} = [ split /;/, $m->{deployments} ] unless ref $m->{deployments};

        # parse mapping variables - undefined are left untouched
        $log->debug( "Parse vars (before)", dump=>$m );
        $m = $job->parse_job_vars( $m );
        $log->debug( "Parse vars (after)", dump=>$m );

        my $wks_path = $job_root->subdir( $m->{workspace} ); 
        $m->{output_local} = $wks_path->subdir( $m->{output} );

        $log->debug( _loc("Checking workspace `%1` for changes `%2` ...", $m->{workspace}, $wks_path ) );

        #_log "Elements before workspace cut" . _dump $elements;
        my $wkels = $elements->cut_to_path_regex( $m->{workspace} ) if $m->{workspace};
        #_log "Elements after workspace cut" . _dump $wkels;

        # exclude elements if any
        if( _array( $m->{exclude} ) > 0 ) {
            $log->debug( _loc("Checking exclusions"), dump=>$m->{exclude} );
            my $all_except_excluded  = $wkels->exclude_regex( _array $m->{exclude} );
            if( $all_except_excluded->count == 0 ) {
                $log->info( _loc("Excluded workspace mapping %1", $m->{name} ) );
                next;
            } else {
                $log->debug( _loc("No exclusions for %1", $m->{name} ) );
            }
        }

        my @applications = $wkels->list('application');  # not used TODO

        $log->debug( "Applications detected", data=>\@applications );

        $log->debug( _loc("Included Elements (before)"), dump=>[ $wkels->paths ] );
        $wkels = $wkels->include_regex( _array $m->{exclude} ) if ref $m->{exclude};
        $log->info( _loc("Included Elements"), dump=>[ $wkels->paths ] );

        if( $wkels->count == 0 ) {   # if mapping matches element in job
            $log->debug( _loc( "Mapping to `%1` has no matching workspaces in elements", $m->{workspace} ) );
            next;
        }

        # all elements as Path::Class and appended to jobroot
        my @origins = map { _file( $job_root, $_->filepath ) } $wkels->all;

        # prepare and push deployments into the stash
        my @deploy = map {
            my $destination_node = $_;
            my $deployment = {
                origin      => \@origins,
                destination => $destination_node,
                scripts     => $m->{scripts_multi} || [],
            };
            $log->info( _loc("*Pushed deployment* for `%1`", $_ ), dump=>$deployment );
            $deployment;
        } _array $m->{deployments};
        push @{ $job_stash->{deployments}->{ DOMAIN() } }, @deploy;

    }
    return @workspaces;
}

1;

