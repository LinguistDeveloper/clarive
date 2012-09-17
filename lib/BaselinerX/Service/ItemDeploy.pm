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
    remove_base: 0

=cut
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::CI;
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
    sub files_clean { my @arr = map { "$_" } _array @_; \@arr };
    for my $m ( @mappings ) {
        next unless $m->{bl} eq '*' || $m->{bl} eq $job->bl;

        if( defined $m->{active} && !$m->{active} ) {
            $log->debug( _loc("Mapping name %1 not active. Ignored", $m->{name} ) );
            next;
        }

        $log->debug( _loc( "Checking if mapping for bl %1 applies", $job->bl ), dump=>$m );

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
                # reset elements to this shorter list
                $wkels = $all_except_excluded; 
                $log->debug( _loc("After exclusions for %1", $m->{name} ), dump=>[ $wkels->paths ] );
            }
        }

        # match variables from workspace against the element path
        my %vars = $elements->extract_variables( $m->{workspace} ) if $m->{workspace};
        $log->debug( "Extracted variables", dump=>\%vars );
        my @scripts_single = map { "$_" } _array $m->{scripts_single};
        $m = $job->parse_job_vars( $m, \%vars ); # reparse, now with workspace variables

        my @applications = $wkels->list('application');  # not used TODO

        $log->debug( "Applications detected", data=>\@applications );

        $log->debug( _loc("Included Elements (before)"), dump=>[ $wkels->paths ] );
        $wkels = $wkels->include_regex( _array $m->{include} ) if ref $m->{include};
        $log->info( _loc("*%1* Included Elements for Deployment"), dump=>[ $wkels->paths ] );

        if( $wkels->count == 0 ) {   # if mapping matches element in job
            $log->debug( _loc( "Mapping to `%1` has no matching workspaces in elements", $m->{workspace} ) );
            next;
        }

        # all elements as Path::Class and appended to jobroot
        $log->debug( "path_deploy = " . $m->{path_deploy} );
        my @origins = $m->{path_deploy}  # path_deploy = deploy paths that match workspace
            ? $self->_unique_paths( elements=>$wkels, workspace=>$m->{workspace}, job_root=>$job_root )
            : map { _file( $job_root, $_->filepath ) } $wkels->all;

        # prepare and push deployments into the stash
        my @deploy = map {
            my @deployments;
            my $destination_node = $_;
            my $ci_destination = Baseliner::CI->new( $destination_node );
            for my $origin ( @origins ) {
                my $re_wks = qr/$m->{workspace}/;
                # parse vars again for single scripts
                my @scripts_single_parsed = map {
                    my $ci = Baseliner::CI->new( $_ );
                    my $script = $ci;
                    my $ret;
                    if( "$origin" =~ $re_wks ) {  # if there's matching
                        my $vars_origin = { %+ };
                        $vars_origin->{origin} = "$origin";
                        $vars_origin->{basename} = $origin->basename;
                        $vars_origin->{home} = $ci_destination->{home};
                        $ret = parse_vars( $script, $vars_origin );
                        try {
                            my @vars = DB->BaliMaster->search({ collection=>'variable' })->hashref->all;
                            if( @vars ) {
                                my %vh = map { $_->{variable} => $_->{value} } 
                                   map { _load($_->{yaml}) if $_->{yaml} } @vars;
                                $ret = parse_vars( $ret, \%vh );
                            }
                        } catch {};
                    } else {
                        $ret = $script;
                    }
                    $ret
                } @scripts_single;
            my $deployment = {
                origin      => [$origin],
                destination => $destination_node,
                scripts     => \@scripts_single_parsed,
            };
            # remove base path ?
                $deployment->{base} = $m->{workspace} unless $m->{no_paths} eq 'true';
            $log->info( _loc("*Pushed deployment* for `%1`", $_ ), dump=>$deployment );
                push @deployments, $deployment;
            }
            @deployments;
        } _array $m->{deployments};
        push @{ $job_stash->{deployments}->{ DOMAIN() } }, @deploy;

        push @{ $job_stash->{deployment_scripts}->{ DOMAIN() } }, 
            map {
                Baseliner::CI->new( $_ )
            } _array $m->{scripts_multi};
    }
    return @workspaces;
}

sub _unique_paths {
    my ($self,%p) = @_;
    my $log = $self->log;
    my $elems = $p{elements} or _throw "Missing parameter elements";
    my $workspace = $p{workspace} or _throw "Missing parameter workspace";
    my $job_root = $p{job_root} or _throw "Missing parameter job_root";

    my %paths;
    for my $e ( map { $_->filepath } $elems->all )  {
        if( $e =~ m/(.*$workspace)/ ) {
            my $path = $1;
            $paths{ $path } = ();
        }
    }
    $log->info( "Unique paths", dump=>[keys %paths] );
    return map { _dir( $job_root, $_ ) } keys %paths;
}

1;

