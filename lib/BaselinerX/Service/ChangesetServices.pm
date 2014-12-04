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

register 'service.changeset.checkout.bl_all_repos' => {
    name    => 'Checkout Job Baseline ... all repos',
    icon    => '/static/images/icons/checkout.png',
    job_service  => 1,
    handler => \&checkout_bl_all_repos,
};

register 'service.changeset.natures' => {
    name    => 'Load Nature Items',
    icon    => '/static/images/nature/nature.png',
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

register 'service.topic.status' => {
    name    => '(DEPRECATED) Change Topic Status',
    icon    => '/static/images/icons/topic.png',
    form    => '/forms/topic_status.js',
    job_service  => 1,
    handler => \&topic_status,
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
    
    if ( !$job->is_failed( status => 'last_finish_status') ) {
        for my $cs ( @changesets ) {
            my $id_bl = ci->bl->find_one({ bl => $bl })->{mid};
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

sub topic_status {
    my ( $self, $c, $config ) = @_;

    my $stash    = $c->stash;
    my $topics = $config->{topics} // _fail _loc 'Missing or invalid parameter topics'; 
    my $new_status = $config->{new_status} // _fail _loc 'Missing or invalid parameter new_status'; 
   
    for my $mid ( Util->_array_or_commas( $topics) ) {
        my $topic = ci->new( $mid );
        _log _loc 'Changing status for topic %1 to status %2', $topic->topic_name, $new_status; 
        Baseliner->model('Topic')->change_status( 
            change     => 1, 
            id_status  => $new_status,
            mid        => $mid,
        );
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
    my $status_on_ok   = $job->is_failed( status => 'last_finish_status') ? $config->{status_on_fail} : $config->{status_on_ok};
    my $status_on_rollback = $job->is_failed( status => 'last_finish_status') ? $config->{status_on_rollback_fail} : $config->{status_on_rollback_ok};

    if ( $job_type eq 'static' ) {
        $self->log->info( _loc "Changesets status not updated. Static job." );
        return;
    }

    my $status = $status_on_ok || $stash->{status_to};
    if ( !$status ) {
        my $ci_self_status = ci->bl->search_ci( bl => $bl);
        ($status) = grep {$_->{type} eq 'D'} _array($ci_self_status->parents( where=>{collection => 'status'}));
    }

    $stash->{update_baselines_changesets} //= {};

    for my $cs ( _array( $stash->{changesets} ) ) {
        if( length $category && $cs->id_category_status == $category) {
            $log->debug( _loc('Topic %1 does not match category %2. Skipped', $cs->title, $category) );
            next;
        }

        if( $stash->{rollback} ) {
            # rollback to previous status
            $status = $status_on_rollback || $stash->{update_baselines_changesets}{ $cs->mid };
            if( !length $status ) {
                _debug _loc 'No last status data for changeset %1. Skipped.', $cs->title;
                next;
            }
        } elsif ($job_type eq 'demote') {
            $status = $status_on_rollback || $stash->{state_to};
        } else {
            # save for rollback
            _debug "Saving changeset status for rollback: " . $cs->mid . " = " . $cs->id_category_status;
            $stash->{update_baselines_changesets}{ $cs->mid } = $cs->id_category_status;
        }
        my $status_name = ci->status->find_one({ id_status=>''.$status })->{name};
        _fail _loc 'Status row not found for status `%1`', $status_name unless $status_name;
        $log->info( _loc( 'Moving changeset %1 (#%2) to stage *%3*', $cs->title, $cs->mid, $status_name ) );
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
    
    my %rev_repos;
    
    if ( !$job->is_failed( status => 'last_finish_status')) {
        my @project_changes = @{ $stash->{project_changes} || [] };
        $log->info( _loc('Updating baseline for %1 project(s) to %2', scalar(@project_changes), $bl ) );
        
        # first, group revisions by repository
        for my $pc ( @project_changes ) {
            my ($project, $repo_revisions_items ) = @{ $pc }{ qw/project repo_revisions_items/ };
            next unless ref $repo_revisions_items eq 'ARRAY';
            for my $rri ( @$repo_revisions_items ) {
                my ($repo, $revisions,$items) = @{ $rri }{ qw/repo revisions items/ };
                
                # TODO if 2 projects share a repository, need to create different tags with project in str?
                for my $revision ( _array( $revisions ) ) {
                    $rev_repos{ $revision->repo->mid }{ 'repo' } //= $revision->repo;
                    $rev_repos{ $revision->repo->mid }{ $revision->mid } = $revision;
                }
            }
        }
        
        # now update
        for my $revgroup ( values %rev_repos ) {
            my $repo = delete $revgroup->{repo};
            my $revisions = [ values %$revgroup ];
            my $out;
            $log->info( _loc('Updating baseline %1 for repository %2, job type %3', $bl, $repo->name, $type ) );
            if( $job->rollback ) {
                if( my $previous = $stash->{bl_original}{$repo->mid} ) {
                    $out = $repo->update_baselines( ref=>$previous, revisions=>[], tag=>$bl, type=>$type );
                } else {
                    _warn _loc 'Could not find previous revision for repository: %1 (%2)', $repo->name, $repo->mid;
                }
            } else {
                $out = $repo->update_baselines( revisions => $revisions, tag=>$bl, type=>$type );
            }
            # save previous revision by repo mid
            $stash->{bl_original}{$repo->mid} = $out->{previous}; 
            $log->info( _loc('Baseline update of %1 item(s) completed', $repo->name), $out );
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
    
    my %rev_repos;
    
    my @project_changes = @{ $stash->{project_changes} || [] };
    $log->info( _loc('Checking job revisions', scalar(@project_changes) ) );
    for my $pc ( @project_changes ) {
        my ($project, $repo_revisions_items ) = @{ $pc }{ qw/project repo_revisions_items/ };
        next unless ref $repo_revisions_items eq 'ARRAY';
        for my $rri ( @$repo_revisions_items ) {
            my ($repo, $revisions,$items) = @{ $rri }{ qw/repo revisions items/ };
            
            # TODO if 2 projects share a repository, look into tags from both?
            for my $revision ( _array( $revisions ) ) {
                $rev_repos{ $revision->repo->mid }{ 'repo' } //= $revision->repo;
                $rev_repos{ $revision->repo->mid }{ $revision->mid } = $revision;
            }
        }
    }
    
    # now verify, only once for each repository
    for my $revgroup ( values %rev_repos ) {
        my $repo = delete $revgroup->{repo};
        my $revisions = [ values %$revgroup ];
        $log->info( _loc('Verifying baseline %1 for repository %2, job type %3', $bl, $repo->name, $type ) );
        $log->debug( _loc('Revisions selected'), $revisions );
        my $out = $repo->verify_revisions( revisions=>$revisions, tag=>$bl, type=>$type );
        $log->info( _loc('Baseline verified for repository %1', $repo->name), $out );
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
        _debug("Changeset $cs->{mid} detected for job");
    }
    
    for my $project_group ( values %projects ) {
        my ($project,$changesets,$revisions,$repos) = @{ $project_group }{ qw/project changesets revisions repos/ };
        my $pc = { project => $project };
        $repos //= {};
        my @items;
        
        # Topic files - group
        my %topic_files;
        for my $cs ( _array( $changesets )  ) {
            my %mid_files = 
                map { $_->{to_mid} => $_->{rel_field} }
                mdb->master_rel->find({ from_mid=>$cs->mid, rel_type=>'topic_asset' })->all;

            my @files = ci->asset->search_cis( mid=>mdb->in( keys %mid_files ) );
            my %meta = map { $_->{id_field} => $_ } grep { $_->{meta_type} && $_->{meta_type} eq 'file' } _array $cs->get_meta;
            _warn "Meta: ". _dump \%meta;
            my ($project) = ( map { $_->name } $cs->projects );
            $project //= '';
            TOPIC_FILE: for my $tfile ( @files ) {
               my $mid = $tfile->mid;
               my $fieldlet = $meta{ $mid_files{$mid} };
               my $co_dir = $fieldlet->{checkout_dir};
               my $fullpath = ''.Util->_dir( "/", $project, $co_dir, $tfile->filename );
               _warn "Full path: ". $fullpath;
               # select only files for this BL
               if( $rename_mode && $fullpath =~ /{($all_bls)}/ ) {
                   next TOPIC_FILE if $fullpath !~ /{$bl}/;  # not for this bl
                   $fullpath =~ s/{$bl}//g; # cleanup
               }
           
               my $versionid = $tfile->versionid;
               $tfile->fullpath( $fullpath );
               # if I'm the highest version, then save. Topic files are unique by project + path
               my $unique_key = $project . '&%&' . $fullpath;
               $topic_files{$unique_key} = { item=>$tfile, row=>$tfile, mid=>$mid, versionid=>$versionid }
                   if !exists $topic_files{$unique_key} || $topic_files{$unique_key}->{versionid} < $versionid;
            } 
        }
        # Topic files - finalize groupings
        @items = map { $_->{item} } values %topic_files;
    
        # Now work with Repositories
        for my $repo_group ( values %$repos ) {
            my ($revs,$repo) = @{ $repo_group }{qw/revisions repo/};
            $log->debug( _loc('Grouping items for revision'), { revisions=>$revs, repository=>$repo } );
            my @repo_items = $repo->group_items_for_revisions( revisions=>$revs, type=>$type, tag=>$bl );
            push @items, map {
                my $it = $_;
                $it->rename( sub{ s/{$bl}//g } ) if $rename_mode;
                $it->path_in_repo( $it->{path} );  # otherwise source/checkout may not work
                $it->path_rel( '' . _dir('/', $repo->rel_path, $it->path) );  # no project name, good for deploying
                $it->path( '' . _dir('/', $project->name, $repo->rel_path, $it->path) );  # prepend project name
                $it;
            } grep {
                # select only files for this BL
                $rename_mode 
                ? ( $_->path =~ /{$bl}/ || $_->path !~ /{($all_bls)}/ )
                : 1 
            } @repo_items;
            push @{ $pc->{repo_revisions_items} }, { repo=>$repo, revisions=>$revisions, items=>\@items };
        }
        $project->{items} = \@items;
        $stash->{project_items}{ $project->mid }{items} = \@items;
        _warn \@items;
        $all_items{ $_->{fullpath} }=$_ for @items;
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

sub checkout_bl_all_repos {
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
        my ($project) = @{ $pc }{ qw/project/ };
        my @repos = grep { $_->{bl} =~ /(\*|$bl)/} _array(ci->new($project->{mid})->{repositories});
        for my $repo ( @repos ) {
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
    my @items = _array( $stash->{items} );
    for my $item ( @items ) {
        $item->checkout( dir=>$job_dir );
        $cnt++;
    }

    $log->info(
        _loc( 'Checked out %1 item(s) to %2', $cnt, $job_dir ),
        [   map {
                    my $path = $_->path;
                    $path =~ s/\n//g;

                      "("
                    . $_->status . ") "
                    . $path . " ("
                    . $_->versionid . ")"
            } @items
        ]
    );
}

sub nature_items {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    my $commit_items = $config->{commit_items};

    $stash->{natures} = {}; 
    my $nat_id = $config->{nature_id} // 'name';  # moniker?
   
    my @nat_rows =  ci->nature->find({active=>'1'})->fields({ mid=>1 })->all;
    my @projects = _array( $job->projects );
    for my $project ( @projects ) {
        #my @items = @{ $stash->{items} || [] };
        my @items = @{ $stash->{project_items}{ $project->mid }{items} || [] };
        # $log->debug( _loc('Project items before for %1', $project->name), \@items );
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
                    $stash->{natures}{ $project->mid }{ $id } = $nature;
                    $stash->{natures}{ $project->mid }{ $mid } = $nature;
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
        # $log->debug( _loc('Project items for %1', $project->name), $stash->{project_items}{ $project->mid }{items} );
        # $log->debug( _loc('Project natures for %1', $project->name), $stash->{project_items}{ $project->mid }{natures} );
        # $log->debug( _loc('Nature check log'), \@msg );
        # $log->debug( _loc('Natures'), $stash->{natures} );
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

    my @projects = map {$_->{mid} } _array($job->{projects});
    my @project_names = map {$_->{name} } _array($job->{projects});
    my @changesets = map {$_->{mid} } _array($job->{changesets});
    my $subject = _loc("Applications: %1. Requesting approval for job %2", "(".join(",",@project_names).")",$job->name);

    my $job_config = model->ConfigStore->get( 'config.job', bl=>$bl );

    my $notify = {
        project => \@projects
    };

    event_new 'event.job.approval_request' => 
        { job => $job, subject => $subject, notify => $notify, username => $job->username, name=>$job->name, step=>$job->step, status=>$job->status, bl=>$job->bl } => sub {
        $job->approval_config( $config );
        $job->final_status( 'APPROVAL' );

        my $now = Class::Date->now();
        my $schedtime = Class::Date->new($job->schedtime);
        my $maxapprovaltime
            = $schedtime < $now
            ? '' . ( $now + $job_config->{approval_expiry_time} ) : ''.($schedtime + $job_config->{approval_delay});
        $job->maxapprovaltime($maxapprovaltime);
    };
    1;
}

1;
