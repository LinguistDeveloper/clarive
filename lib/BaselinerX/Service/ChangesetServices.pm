package BaselinerX::Service::ChangesetServices;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

#with 'Baseliner::Role::Namespace::Create';
with 'Baseliner::Role::Service';

register 'service.changeset.items' => {
    name    => 'Load Job Items into Stash',
    icon    => '/static/images/icons/baseline.gif',
    job_service  => 1,
    handler => \&job_items,
};

register 'service.changeset.update_baselines' => {
    name    => 'Update Baselines',
    job_service  => 1,
    icon    => '/static/images/icons/baseline.gif',
    #form    => '/forms/update_baselines.js',
    handler => \&update_baselines,
};

register 'service.changeset.verify_revisions' => {
    name    => 'Verify Revision Integrity Rules',
    job_service  => 1,
    icon    => '/static/images/icons/baseline.gif',
    #form    => '/forms/update_baselines.js',
    handler => \&verify_revisions,
};

register 'service.changeset.checkout' => {
    name    => 'Checkout Job Items',
    icon    => '/static/images/icons/checkout.png',
    job_service  => 1,
    handler => \&checkout,
};

register 'service.changeset.checkout.bl' => {
    name    => 'Checkout Job Baseline',
    icon    => '/static/images/icons/checkout.png',
    job_service  => 1,
    handler => \&checkout_bl,
};

register 'service.changeset.natures' => {
    name    => 'Load Nature Items',
    icon    => '/static/images/icons/nature.gif',
    form    => '/forms/nature_items.js',
    job_service  => 1,
    handler => \&nature_items,
};

register 'service.changeset.update' => {
    name    => 'Update Changesets',
    icon    => '/static/images/icons/topic.png',
    form    => '/forms/changeset_update.js',
    job_service  => 1,
    handler => \&changeset_update,
};

register 'service.changeset.update_bls' => {
    name    => 'Update Changesets BLs',
    icon    => '/static/images/icons/topic.png',
    job_service  => 1,
    handler => \&update_changesets_bls,
};

sub update_changesets_bls {
    my ( $self, $c, $config ) = @_;

    my $stash    = $c->stash;
    my $job      = $c->stash->{job};
    my $log      = $job->logger;
    my $bl       = $job->bl;
    my $job_type = $job->job_type;
    my @changesets = _array( $stash->{changesets} );
    
    if ( !$stash->{failing} && $job->last_finish_status ne 'REJECTED' ) {
        for my $cs ( @changesets ) {
            my $id_bl = ci->new('moniker:'.$bl)->{mid};
            my $topic = mdb->topic->find_one({ mid => "$cs->{mid}"});
            my @cs_bls = _array $topic->{bls};
            if (!( $id_bl ~~ @cs_bls)) {
                push @cs_bls,$id_bl;
                my %p;
                $p{topic_mid} = $cs->{mid};
                $p{bls} = \@cs_bls;
                Baseliner->model('Topic')->update( { action => 'update', %p } );
                $log->info( _loc("Added %1 to changeset %2 bls",$bl,$cs->{mid}) );        
            }            
        }
    }
}

sub changeset_update {
    my ( $self, $c, $config ) = @_;

    my $stash    = $c->stash;
    my $job      = $c->stash->{job};
    my $log      = $job->logger;
    my $bl       = $job->bl;
    my $job_type = $job->job_type;
    my @changesets;
    
    my $category       = $config->{category};
    my $status_on_ok   = $stash->{failing} || $job->last_finish_status eq 'REJECTED' ? $config->{status_on_fail} : $config->{status_on_ok};
    my $status_on_rollback = $stash->{failing} || $job->last_finish_status eq 'REJECTED' ? $config->{status_on_rollback_fail} : $config->{status_on_rollback_ok};

    if ( $job_type eq 'static' ) {
        $self->log->info( _loc "Changesets status not updated. Static job." );
        return;
    }

    my $status = $status_on_ok || $stash->{status_to};
    if ( !$status ) {
        my $ci_self_status = ci->new('moniker:'.$bl);
        ($status) = grep {$_->{type} eq 'D'} _array($ci_self_status->parents( isa => 'status'));
    }

    $stash->{update_baselines_changesets} //= {};

    for my $cs ( _array( $stash->{changesets} ) ) {
        if( length $category && $cs->id_category_status == $category) {
            $log->debug( _loc('Topic %1 does not match category %2. Skipped', $cs->name, $category) );
            next;
        }
        if( $stash->{rollback} ) {
            # rollback to previous status
            $status = $status_on_rollback || $stash->{update_baselines_changesets}{ $cs->mid };
            if( !length $status ) {
                _debug _loc 'No last status data for changeset %1. Skipped.', $cs->name;
                next;
            }
        } else {
            # save for rollback
            _debug "Saving changeset status for rollback: " . $cs->mid . " = " . $cs->id_category_status;
            $stash->{update_baselines_changesets}{ $cs->mid } = $cs->id_category_status;
        }
        my $status_row = DB->BaliTopicStatus->find( $status );
        _fail _loc 'Status row not found for status `%1`', $status unless $status_row;
        my $status_name = $status_row->name;
        $log->info( _loc( 'Moving changeset *%1* to stage *%2*', $cs->name, $status_name ) );
        Baseliner->model('Topic')->change_status(
           change          => 1, 
           username        => $job->username,
           id_status       => $status,
           #id_old_status   => $cs->id_category_status,
           mid             => $cs->mid,
        );
    }

}

sub update_baselines {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $job   = $stash->{job};
    my $log   = $job->logger;
    my $type = $job->job_type;
    my $bl = $job->bl;
    
    if ( !$stash->{failing} && $job->last_finish_status ne 'REJECTED' ) {
        my @project_changes = @{ $stash->{project_changes} || [] };
        $log->info( _loc('Updating baseline for %1 project(s) to %2', scalar(@project_changes), $bl ) );
        for my $pc ( @project_changes ) {
            my ($project, $repo_revisions_items ) = @{ $pc }{ qw/project repo_revisions_items/ };
            next unless ref $repo_revisions_items eq 'ARRAY';
            for my $rri ( @$repo_revisions_items ) {
                my ($repo, $revisions,$items) = @{ $rri }{ qw/repo revisions items/ };
                
                $log->info( _loc('Updating baseline %1 for project %2, repository %3, job type %4', $bl, $project->name, $repo->name, $type ) );
                my $out = $repo->update_baselines( revisions => $revisions, tag=>$bl, type=>$type );
                $log->info( _loc('Baseline update of %1 item(s) completed', $repo->name), $out );
            }
        }
    }
}

sub verify_revisions {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $job   = $stash->{job};
    my $log   = $job->logger;
    my $type = $job->job_type;
    my $bl = $job->bl;
    
    my @project_changes = @{ $stash->{project_changes} || [] };
    $log->info( _loc('Checking job revisions', scalar(@project_changes) ) );
    for my $pc ( @project_changes ) {
        my ($project, $repo_revisions_items ) = @{ $pc }{ qw/project repo_revisions_items/ };
        next unless ref $repo_revisions_items eq 'ARRAY';
        for my $rri ( @$repo_revisions_items ) {
            my ($repo, $revisions,$items) = @{ $rri }{ qw/repo revisions items/ };
            
            $log->info( _loc('Verifying baseline %1 for project %2, repository %3, job type %4', $bl, $project->name, $repo->name, $type ) );
            $log->debug( _loc('Revisions selected'), $revisions );
            my $out = $repo->verify_revisions( revisions=>$revisions, tag=>$bl, type=>$type );
            $log->info( _loc('Baseline verified for repository %1', $repo->name), $out );
        }
    }
}

sub job_items {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $job   = $stash->{job};
    my $log   = $job->logger;
    
    my $type = $job->job_type;
    my $bl = $job->bl;
    my $all_bls = join '|', grep !/^\*$/, map { $_->bl } BaselinerX::CI::bl->search_cis;
    my $rename_mode = $config->{rename_mode} // 'on';
    
    my %projects;
    my @project_changes;
    my %all_items;

    $log->debug( _loc( "Loading items into stash... (type=%1, bl=%2)", $type, $bl ) );
    
    # group changesets by project->repos->revisions
    for my $cs ( _array( $stash->{changesets} )  ) {
        my ($project) = $cs->projects;
        _fail _loc('No project assigned to changeset %1', $cs->topic_name) unless $project;
        $projects{ $project->mid }{project} //= $project;
        push @{ $projects{ $project->mid }{changesets} }, $cs;
        push @{ $projects{ $project->mid }{revisions} }, $cs->revisions;
        # group revisions by repo
        for my $rev ( _array( $cs->revisions ) ) {
            my $repo = $rev->repo;
            $projects{ $project->mid }{repos}{ $repo->mid }{repo} //= $repo;
            push @{ $projects{ $project->mid }{repos}{ $repo->mid }{revisions} }, $rev; 
        }
    }
    
    for my $project_group ( values %projects ) {
        my ($project,$changesets,$revisions,$repos) = @{ $project_group }{ qw/project changesets revisions repos/ };
        my $pc = { project => $project };
        $repos //= {};
        my @items;
        for my $repo_group ( values %$repos ) {
            my ($revs,$repo) = @{ $repo_group }{qw/revisions repo/};
            $log->debug( _loc('Grouping items for revision'), { revisions=>$revs, repository=>$repo } );
            my @repo_items = $repo->group_items_for_revisions( revisions=>$revs, type=>$type, tag=>$bl );
            push @items, map {
                my $it = $_;
                $it->rename( sub{ s/{$bl}//g } ) if $rename_mode;
                $it->path_in_repo( $it->path );  # otherwise source/checkout may not work
                $it->path_rel( '' . _dir('/', $repo->rel_path, $it->path) );  # no project name, good for deploying
                $it->path( '' . _dir('/', $project->name, $repo->rel_path, $it->path) );  # prepend project name
                $it;
            } grep {
                $rename_mode 
                ? ( $_->path =~ /{$bl}/ || $_->path !~ /{$all_bls}/ )
                : 1 
            } @repo_items;
            push @{ $pc->{repo_revisions_items} }, { repo=>$repo, revisions=>$revisions, items=>\@items };
        }
        $project->{items} = \@items;
        $stash->{project_items}{ $project->mid }{items} = \@items;
        $all_items{ $_->path }=$_ for @items;
        push @project_changes, $pc; 
    }
    # put unique items into stash
    $stash->{items} = [ values %all_items ];

    # create name list
    my %name_list;
    for my $i ( _array( $stash->{items} ) ) {
        my $f = $i->path;
        next unless $f;
        $f = _file( $f )->basename;
        $name_list{ "$f" } = 1;
    }
    $stash->{item_name_list} = [ keys %name_list ];
    $stash->{item_name_list_quote} = "'" . join("' '", keys %name_list) . "'";
    $stash->{item_name_list_comma} = join(",", keys %name_list);

    # save project-repository-revisions structure
    $stash->{project_changes} = \@project_changes;
    
    my $cnt = scalar keys %all_items; 
    $log->info( _loc( "Found %1 items for this job", $cnt ), [ keys %all_items ] ); 
    
    { project_count=>scalar keys %projects };
}

sub checkout_bl {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $job_dir = $job->job_dir;
    my $bl = $stash->{bl};
    _fail _loc 'Missing job_dir' unless length $job_dir;
    
    my @project_changes = @{ $stash->{project_changes} || [] };
    
    $log->info( _loc('Checking out baseline for %1 project(s)', scalar(@project_changes) ) );
    for my $pc ( @project_changes ) {
        my ($project, $repo_revisions_items ) = @{ $pc }{ qw/project repo_revisions_items/ };
        next unless ref $repo_revisions_items eq 'ARRAY';
        for my $rri ( @$repo_revisions_items ) {
            my ($repo, $revisions,$items) = @{ $rri }{ qw/repo revisions items/ };
            my $dir_prefixed = File::Spec->catdir( $job_dir, $project->name, $repo->rel_path );
            $log->info( _loc('Checking out baseline %1 for project %2, repository %3: %4', $bl, $project->name, $repo->name, $dir_prefixed ) );
            my $co_info = $repo->checkout( tag=>$bl, dir=>$dir_prefixed );
            my @ls = _array( $co_info->{ls} );
            $log->info( _loc('Baseline checkout of %1 item(s) completed', scalar(@ls)), join("\n",@ls) );
        }
    }
}

sub checkout {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $job_dir = $job->job_dir;
    _fail _loc 'Missing job_dir' unless length $job_dir;
    
    my $cnt = 0;
    my @item_paths;
    my @items = _array( $stash->{items} );
    for my $item ( @items ) {
        push @item_paths, $item->path;
        $item->checkout( dir=>$job_dir );
        $cnt++;
    }
    $log->info( _loc('Checked out %1 item(s) to %2', $cnt, $job_dir), [ map { "$_->{path} ($_->{versionid})" } @items ] );
}

sub nature_items {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    my $commit_items = $config->{commit_items};

    $stash->{natures} = {}; 
    my $nat_id = $config->{nature_id} // 'name';  # moniker?
   
    my @nat_rows = DB->BaliMaster->search({ collection=>'nature' }, { select=>'mid' })->hashref->all;
    my @projects = _array( $job->projects );
    for my $project ( @projects ) {
        #my @items = @{ $stash->{items} || [] };
        my @items = @{ $stash->{project_items}{ $project->mid }{items} || [] };
        $log->debug( _loc('Project items before for %1', $project->name), \@items );
        my %nature_names;
        my @msg;
        for my $nature ( map { ci->new($_->{mid}) } @nat_rows ) {
            my @chosen;
            push @msg, "nature = " . $nature->name;
            ITEM: for my $it ( @items ) {
                my $nature_clon = Util->_clone( $nature );
                if( $commit_items && $it->ns && !ci->find( ns=>$it->ns) ) {
                    $it->save;
                }
                push @msg, "item = " . $it->path;
                if( $nature->push_item( $it ) ) {
                    my $id =  $nature->$nat_id;
                    my $mid =  $nature->mid;
                    $stash->{natures}{ $id } = $nature;
                    $stash->{natures}{ $mid } = $nature;
                    $nature_names{ $nature->name } = ();
                    $job->push_ci_unique( 'natures', $nature_clon );
                    push @chosen, $it;
                    
                    push @msg, "MATCH = " . $it->path;
                    #last ITEM;
                } else {
                    push @msg, "NO = " . $it->path;
                }
            }
            $stash->{project_items}{ $project->mid }{natures}{ $nature->mid } = \@chosen;
        }
        #$log->debug( _loc('Job natures after push'), $job->natures );
        $log->debug( _loc('Project items for %1', $project->name), $stash->{project_items}{ $project->mid }{items} );
        $log->debug( _loc('Project natures for %1', $project->name), $stash->{project_items}{ $project->mid }{natures} );
        $log->debug( _loc('Nature check log'), \@msg );
        $log->debug( _loc('Natures'), $stash->{natures} );
        my @nats = keys %nature_names;
        if( my $cnt = scalar @nats ) {
            $log->info( _loc('%1 nature(s) detected in job items: %2', $cnt, join ', ',@nats ) );
        } else {
            $log->warn( _loc('No natures detected in job items') );
        }
    }
    return 0;
}    
    
register 'service.approval.request' => {
    name    => 'Request Approval',
    icon => '/static/images/icons/user_delete.gif', 
    form => '/forms/approval_request.js',
    job_service  => 1,
    handler => \&request_approval,
};

register 'event.job.approval_request' => {
    text => 'Approval requested for job %3 (user %1)',
    description => 'approval requested for job',
    vars => ['username', 'ts', 'name', 'bl', 'status','step'],
    notify => {
        scope => ['project'],
    },
};
register 'event.job.approved' => {
    text        => 'Job %3 Approved',
    description => 'Job Approved',
    vars        => [ 'username', 'ts', 'name', 'bl', 'status', 'step', 'comments' ],
    notify => { scope => ['project'] },
};
register 'event.job.rejected' => {
    text        => 'Job %3 Rejected',
    description => 'Job Rejected',
    vars        => [ 'username', 'ts', 'name', 'bl', 'status', 'step', 'comments' ],
    notify => { scope => ['project'] },
};
sub request_approval {
    my ( $self, $c, $config ) = @_;

    my $stash    = $c->stash;
    my $job      = $c->stash->{job};
    my $log      = $job->logger;
    my $bl       = $job->bl;

    event_new 'event.job.approval_request' => 
        { username => $job->username, name=>$job->name, step=>$job->step, status=>$job->status, bl=>$job->bl } => sub {
        $job->approval_config( $config );
        $job->final_status( 'APPROVAL' );
    };
    1;
}

1;

__END__

##########################################################################
########### DEPRECATED:

## deprecated in favor of service.changeset.items, changesets now included in stash
register 'service.changeset.job_elements' => {
    name    => 'Fill job_elements',
    deprecated => 1,
    handler => \&job_elements,
};

sub checkout_items {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $bl    = $job->bl;

    my $e = $stash->{elements};

    $log->debug( "Elements", data => _dump $e);
    my @eltos = $e->list( '' );

    my $checkout;

    # Topic Files
    for my $element ( @eltos ) {
        next if ( ref $element ne 'BaselinerX::ChangesetElement' );
        my $file = $c->model( 'Baseliner::BaliFileVersion' )->find( $element->{mid} );
        my $filepath = _file $job->root, $element->{path}, $element->{name};
        _mkpath( _file $job->root, $element->{path} );

        $log->debug( "Element $element->{mid}", data => _dump $element);

        open my $fout, '>', $filepath
            or _throw _loc( 'Changeset checkout: failed to write to file "%1": %2', $filepath, $! );
        print $fout $file->filedata;
        close $fout;
        $checkout .= $filepath . "\n";
    } ## end for my $element ( @eltos)
    $log->info( _loc( "Checked out files" ), data => $checkout );

    # Topic Files END

    # Git Checkouts
    my $git_checkouts = $stash->{git_checkouts};

    for ( keys %{$git_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $log->debug( "Llamando a repo->checkout para la revision ".$git_checkouts->{$_}->{rev}." del proyecto ".$git_checkouts->{$_}->{prj} );
        $repo->checkout( rev => $git_checkouts->{$_}->{rev}, prj => $git_checkouts->{$_}->{prj} );
    }

    # Git Checkouts End

    # Svn Checkouts
    my $svn_checkouts = $stash->{svn_checkouts};

    for ( keys %{$svn_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->checkout( repo => $repo, rev => $svn_checkouts->{$_}->{rev}, prj => $svn_checkouts->{$_}->{prj}, branch => $svn_checkouts->{$_}->{branch} );
    }

    # Svn Checkouts End

    # Plastic Checkouts
    my $plastic_checkouts = $stash->{plastic_checkouts};

    for ( keys %{$plastic_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->checkout( repo => $repo, rev => $plastic_checkouts->{$_}->{rev}, prj => $plastic_checkouts->{$_}->{prj}, branch => $plastic_checkouts->{$_}->{branch} );
    }

    # Plastic Checkouts End
} ## end sub checkout

sub job_elements {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $bl    = $job->bl;
    my @changesets;

    for my $item ( _array $stash->{contents} ) {
        my $ns = ns_get $item->{item};
        next unless $ns->ns_type eq 'changeset';

        if ( $ns->{ns} =~ /.*\/(.*)$/ ) {
            my $mid = $1;
            $log->debug( "Changeset $mid detected for job" );
            push @changesets, $mid;
        }

    } ## end for my $item ( _array $stash...)

    my @elems;
    my @versions;

    if ( $job->job_type eq 'demote' || $job->rollback ) {

    } else {

        #Topic Files
        my $versions_ref = $c->model( 'Baseliner::BaliMasterRel' )->search(
            {from_mid => \@changesets, rel_type => 'topic_file_version'},
            {
                join    => { 'topic_file_version_to' => { 'file_projects' => { 'directory' } } },
                +select => [
                    'topic_file_version_to.filename', 'max(topic_file_version_to.versionid)',
                    'max(topic_file_version_to.mid)', 'max(directory.name)'
                ],
                +as      => [ 'filename', 'version', 'mid', 'path' ],
                group_by => 'topic_file_version_to.filename',
            }
        )->hashref->all;
        
        @elems = map {
            BaselinerX::ChangesetElement->new(
                mid      => $_->{mid},
                fullpath => "/changesets/" . $_->{filename},
                status   => 'M',
                version  => $_->{version}
            );
        } @versions;
        $log->debug(_loc("<b>Changeset:</B> Files detected for job"), data => _dump @elems);

        #Topic Files end

    } ## end else [ if ( $job->job_type eq...)]

    # Releases?
    my @chi = DB->BaliMasterRel->search({ from_mid=>\@changesets, rel_type=>'topic_topic' })->hashref->all;
    if( @chi ) {
        ###TODO: Buscar SOLO los tópicos que estén en el estado de origen
        push @changesets, map { $_->{to_mid} } @chi;
    }
    $log->debug( _loc("Searching for revisions for mids: %1", join(',',@changesets ) ) );
    #Git revisions
    my @revisions =
        $c->model( 'Baseliner::BaliMasterRel' )
        ->search( {from_mid => \@changesets, rel_type => 'topic_revision'} )->hashref->all;

    if ( @revisions ) {

        my $revisions_shas;
        my $git_checkouts;

        for ( @revisions ) {
            my $rev  = Baseliner::CI->new( $_->{to_mid} );
            next if ref $rev ne 'BaselinerX::CI::GitRevision';
            $log->debug(_loc("<b>GIT Revisions:</B> Treating revision"), data => _dump $_);
            my $repo = $rev->{repo};
            push @{$revisions_shas->{$repo->{mid}}->{shas}}, $rev;
            my $topic     = Baseliner->model( 'Baseliner::BaliTopic' )->find( $_->{from_mid} );
            try {
                my $projectid = $topic->projects->search()->first->id;
                my $prj       = Baseliner::Model::Projects->get_project_name( id => $projectid );
                $revisions_shas->{$repo->{mid}}->{prj} = $prj;
                $git_checkouts->{$repo->{mid}}->{prj}  = $prj;
            } catch {
                $log->warn( _loc( 'No project found for revision *%1*', $rev->name ) );
            };
        } ## end for ( @revisions )

        for ( keys %{$revisions_shas} ) {
            $log->debug(_loc("<b>GIT Revisions:</B> Processing revision $_"));
            my $repo = Baseliner::CI->new( $_ );
            $log->debug("JOB", data => $job);
            $repo->job( $job );

            $log->debug( "Detecting last commit" );
            my $last_commit =
                $repo->get_last_commit( commits => $revisions_shas->{$_}->{shas} );
            $log->debug( "Detected last commit", data => $last_commit );
            $log->debug( "Generating git list of elements" );
            #TODO: Comprobar si tengo last_commit
            my @git_elements =
                $repo->list_elements( rev => $last_commit, prj => $revisions_shas->{$_}->{prj} );
            $log->debug( "Generated git list of elements", data => _dump @git_elements );
            push @elems, @git_elements;
            $git_checkouts->{$_}->{rev} = $last_commit;
        } ## end for ( keys %{$revisions_shas...})
        $stash->{git_checkouts} = $git_checkouts;
    } ## end if ( @revisions )

    #Git revisions fin

    #SVN revisions

    if ( @revisions ) {

        my $revisions_shas;
        my $svn_checkouts;
        my $branch;

        for ( @revisions ) {
            my $rev  = Baseliner::CI->new( $_->{to_mid} );
            next if ref $rev ne 'BaselinerX::CI::SvnRevision';
            $log->debug(_loc("<b>SVN Revisions:</B> Treating revision"), data => _dump $_);
            $branch = $rev->{branch};
            $log->debug(_loc("<b>SVN Revisions:</B> Branch of revision $rev->{sha} ... $branch"), data => _dump $rev);
            my $repo = $rev->{repo};
            push @{$revisions_shas->{$repo->{mid}}->{shas}}, $rev->{sha};
            my $topic     = Baseliner->model( 'Baseliner::BaliTopic' )->find( $_->{from_mid} );
            my $projectid = $topic->projects->search()->first->id;
            my $prj       = Baseliner::Model::Projects->get_project_name( id => $projectid );
            $revisions_shas->{$repo->{mid}}->{prj} = $prj;
            $svn_checkouts->{$repo->{mid}}->{prj}  = $prj;
            $svn_checkouts->{$repo->{mid}}->{branch}  = $branch;
        } ## end for ( @revisions )

        for ( keys %{$revisions_shas} ) {
            $log->debug(_loc("<b>SVN Revisions:</B> Processing revision $_"));
            my $repo = Baseliner::CI->new( $_ );
            $repo->job( $job );

            $log->debug(_loc("<b>SVN Revisions:</B> Calling revision $_ list_elements"));
            my @svn_elements =
                $repo->list_elements( repo => $repo,  prj => $revisions_shas->{$_}->{prj}, commits => $revisions_shas->{$_}->{shas}, branch => $branch );
            $log->debug( "<b>SVN Revisions:</B> Generated git list of elements", data => _dump @svn_elements );
            push @elems, @svn_elements;
            $svn_checkouts->{$_}->{rev} = $repo->last_commit( commits => $revisions_shas->{$_}->{shas} );
        } ## end for ( keys %{$revisions_shas...})
        $stash->{svn_checkouts} = $svn_checkouts;
    } ## end if ( @revisions )

    #SVN revisions fin

    #CVS revisions

    if ( @revisions ) {

        my $revisions_shas;
        my $cvs_checkouts;
        my $branch;

        for ( @revisions ) {
            my $rev  = Baseliner::CI->new( $_->{to_mid} );
            next if ref $rev ne 'BaselinerX::CI::CvsRevision';
            $log->debug(_loc("<b>CVS Revisions:</B> Treating revision"), data => _dump $_);
            $branch = $rev->{branch};
            $log->debug(_loc("<b>CVS Revisions:</B> Branch of revision $rev->{sha} ... $branch"), data => _dump $rev);
            my $repo = $rev->{repo};
            push @{$revisions_shas->{$repo->{mid}}->{shas}}, $rev->{sha};
            my $topic     = Baseliner->model( 'Baseliner::BaliTopic' )->find( $_->{from_mid} );
            my $projectid = $topic->projects->search()->first->id;
            my $prj       = Baseliner::Model::Projects->get_project_name( id => $projectid );
            $revisions_shas->{$repo->{mid}}->{prj} = $prj;
            $cvs_checkouts->{$repo->{mid}}->{prj}  = $prj;
            $cvs_checkouts->{$repo->{mid}}->{branch}  = $branch;
        } ## end for ( @revisions )

        for ( keys %{$revisions_shas} ) {
            $log->debug(_loc("<b>CVS Revisions:</B> Processing revision $_"));
            my $repo = Baseliner::CI->new( $_ );
            $repo->job( $job );

            $log->debug(_loc("<b>CVS Revisions:</B> Calling revision $_ list_elements"));
            my @cvs_elements =
                $repo->list_elements( repo => $repo,  prj => $revisions_shas->{$_}->{prj}, commits => $revisions_shas->{$_}->{shas}, branch => $branch );
            $log->debug( "<b>CVS Revisions:</B> Generated git list of elements", data => _dump @cvs_elements );
            push @elems, @cvs_elements;
            $cvs_checkouts->{$_}->{rev} = $repo->last_commit( commits => $revisions_shas->{$_}->{shas} );
        } ## end for ( keys %{$revisions_shas...})
        $stash->{cvs_checkouts} = $cvs_checkouts;
    } ## end if ( @revisions )

    #CVS revisions fin

    #Plastic revisions
    @revisions =
        $c->model( 'Baseliner::BaliMasterRel' )
        ->search( {from_mid => \@changesets, rel_type => 'topic_revision'} )->hashref->all;

    if ( @revisions ) {

        my $revisions_shas;
        my $plastic_checkouts;
        my $branch;

        for ( @revisions ) {
            my $rev  = Baseliner::CI->new( $_->{to_mid} );
            next if ref $rev ne 'BaselinerX::CI::PlasticRevision';
            $log->debug(_loc("<b>PLASTIC Revisions:</B> Treating revision"), data => _dump $_);
            $branch = $rev->{branch};
            my $repo = $rev->{repo};
            push @{$revisions_shas->{$repo->{mid}}->{shas}}, $rev;
            my $topic     = Baseliner->model( 'Baseliner::BaliTopic' )->find( $_->{from_mid} );
            try {
                my $projectid = $topic->projects->search()->first->id;
                my $prj       = Baseliner::Model::Projects->get_project_name( id => $projectid );
                $revisions_shas->{$repo->{mid}}->{prj} = $prj;
                $plastic_checkouts->{$repo->{mid}}->{prj}  = $prj;
                $plastic_checkouts->{$repo->{mid}}->{branch}  = $branch;
            } catch {
                $log->warn( _loc( 'No project found for revision *%1*', $rev->name ) );
            };
        } ## end for ( @revisions )

        for ( keys %{$revisions_shas} ) {
            $log->debug(_loc("<b>PLASTIC Revisions:</B> Processing revision $_"));
            my $repo = Baseliner::CI->new( $_ );
            $log->debug("JOB", data => $job);
            $repo->job( $job );

            $log->debug( "Detecting last commit", data => $revisions_shas );
            my $last_commit =
                $repo->get_last_commit( commits => $revisions_shas->{$_}->{shas} );
            $log->debug( "Detected last commit", data => $last_commit );
            $log->debug( "Generating plastic list of elements" );
            #TODO: Comprobar si tengo last_commit
            my @plastic_elements =
                $repo->list_elements( rev => $last_commit, prj => $revisions_shas->{$_}->{prj} );
            $log->debug( "Generated git list of elements", data => _dump @plastic_elements );
            push @elems, @plastic_elements;
            $plastic_checkouts->{$_}->{rev} = $last_commit;
        } ## end for ( keys %{$revisions_shas...})
        $stash->{plastic_checkouts} = $plastic_checkouts;
    } ## end if ( @revisions )

    #End of Plastic Revisions

    my $e = $stash->{elements} || BaselinerX::Job::Elements->new;
    $e->push_elements( @elems );

    $stash->{elements} = $e;
    $log->info(
        _loc( "Elements included in job" ),
        data => join "\n",
        map { "M  " . $_->{filename} . ":" . $_->{version} } @versions
    );


} ## end sub job_elements


sub update_baselines_old {
    my ( $self, $c, $config ) = @_;

    my $stash    = $c->stash;
    my $job      = $c->stash->{job};
    my $log      = $job->logger;
    my $bl       = $job->bl;
    my $job_type = $job->job_type;
    my @changesets;


    if ( $job_type eq 'static' ) {
        $self->log->info( _loc "Changesets status not updated. Static job." );
        return;
    }

    my $status = $stash->{status_to};

    ### DANGER!!!! ADDED FOR DEMO PURPOSES ONLY
    my $jt = $job->job_type;
    if( $jt eq 'demote' ){
        $bl = { 'PROD' => 'PREP', PREP => 'IT' }->{ $bl };
    }
    if ( !$status ) {
        $status = $c->model( 'Baseliner::BaliTopicStatus' )->search( {bl => $bl} )->first->id;
    }
    ### DANGER!!!! ADDED FOR DEMO PURPOSES ONLY

    for my $item ( _array $stash->{contents} ) {

        if ( $item->{item} =~ /.*\/(.*)$/ ) {
            my $mid = $1;
            push @changesets, $mid;
        }
    } ## end for my $item ( _array $stash...)
    # XXX - quitar try-catch
    # my @chi = DB->BaliMasterRel->search({ from_mid=>\@changesets, rel_type=>'topic_topic' })->hashref->all;
    # if( @chi ) {
    #     push @changesets, map { $_->{to_mid} } @chi;
    # }
    try {
        my $rs_changesets = DB->BaliTopic->search( {mid => \@changesets}, { prefetch => 'status'} );

        while ( my $row = $rs_changesets->next ) {
            my $status_name = $c->model( 'Baseliner::BaliTopicStatus' )->find( $status )->name;
            event_new 'event.topic.change_status' => { username => $job->row->username, status => $status_name, old_status => $row->status->name } => sub {
                $row->id_category_status( $status );
                $row->update;
                $log->info( _loc( "%1 %2 to %3", $job_type, $row->title, $status_name ) );
                return { mid => $row->mid, topic => $row->title };
                Baseliner->cache_remove( qr/:$row->mid:/ );
            };
    } ## end while ( my $row = $rs_changesets...)
    } catch {
        _error( shift() );
    };

    # Git Update Baselines
    my $git_checkouts = $stash->{git_checkouts};

    for ( keys %{$git_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->update_baselines( rev => $git_checkouts->{$_}->{rev} );
    }

    # Git Update Baselines

    # Svn Update Baselines
    my $svn_checkouts = $stash->{svn_checkouts};

    for ( keys %{$svn_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->update_baselines( repo => $repo, branch => $svn_checkouts->{$_}->{branch}, rev => $svn_checkouts->{$_}->{rev} );
    }

    my $plastic_checkouts = $stash->{plastic_checkouts};

    for ( keys %{$plastic_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->update_baselines( rev => $plastic_checkouts->{$_}->{rev} );
    }
    # Svn Update Baselines
} ## end sub update_baselines

package BaselinerX::ChangesetElement;
use Moose;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;

with 'BaselinerX::Job::Element';

has mask => qw(is rw isa Str default /application/subapp/nature);
has sha  => qw(is rw isa Str);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p    = @_;

    if ( !exists $p{path} && !exists $p{name} ) {
        if ( $p{fullpath} =~ /^(.*)\/(.*?)$/ ) {
            ( $p{path}, $p{name} ) = ( $1, $2 );
        } else {
            ( $p{path}, $p{name} ) = ( '', $p{fullpath} );
        }
    } ## end if ( !exists $p{path} ...)
    $self->$orig( %p );
};

1;
