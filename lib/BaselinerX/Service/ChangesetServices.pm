package BaselinerX::Service::ChangesetServices;
use Moose;

use List::Util qw(first);
use Try::Tiny;
use experimental 'smartmatch';
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;

#with 'Baseliner::Role::Namespace::Create';
with 'Baseliner::Role::Service';

register 'service.changeset.items' => {
    name    => _locl('Load Job Items into Stash'),
    icon    => '/static/images/icons/service-changeset-items.svg',
    job_service  => 1,
    handler => \&job_items,
};

register 'service.changeset.update_baselines' => {
    name    => _locl('Update Baselines'),
    job_service  => 1,
    icon    => '/static/images/icons/service-changeset-baselines.svg',
    handler => \&update_baselines,
};

register 'service.changeset.sync_baselines' => {
    name        => _locl('Sync Baselines'),
    job_service => 1,
    icon        => '/static/images/icons/service-changeset-sync.svg',
    form        => '/forms/sync_baselines.js',
    handler     => \&sync_baselines,
};

register 'service.changeset.verify_revisions' => {
    name    => _locl('Verify Revision Integrity Rules'),
    job_service  => 1,
    icon    => '/static/images/icons/service-changeset-verify.svg',
    handler => \&verify_revisions,
};

register 'service.changeset.checkout' => {
    name    => _locl('Checkout Job Items'),
    icon    => '/static/images/icons/service-changeset-checkout.svg',
    job_service  => 1,
    handler => \&checkout,
};

register 'service.changeset.checkout.bl' => {
    name    => _locl('Checkout Job Baseline'),
    icon    => '/static/images/icons/service-changeset-bl.svg',
    job_service  => 1,
    handler => \&checkout_bl,
};

register 'service.changeset.checkout.bl_all_repos' => {
    name    => _locl('Checkout Job Baseline ... all repos'),
    icon    => '/static/images/icons/service-changeset-bl-all.svg',
    job_service  => 1,
    handler => \&checkout_bl_all_repos,
};

register 'service.changeset.natures' => {
    name    => _locl('Load Nature Items'),
    icon    => '/static/images/icons/service-changeset-natures.svg',
    form    => '/forms/nature_items.js',
    job_service  => 1,
    handler => \&nature_items,
};

register 'service.changeset.update' => {
    name    => _locl('Update Changesets'),
    icon    => '/static/images/icons/service-changeset-update.svg',
    form    => '/forms/changeset_update.js',
    job_service  => 1,
    handler => \&update_changesets,
};

register 'service.topic.status' => {
    name    => _locl('(DEPRECATED) Change Topic Status'),
    icon    => '/static/images/icons/service-topic-status.svg',
    form    => '/forms/topic_status_deprecated.js',
    job_service  => 1,
    handler => \&topic_status,
};

register 'service.changeset.update_bls' => {
    name    => _locl('Update Changesets BLs'),
    icon    => '/static/images/icons/service-changeset-update-bls.svg',
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
            model->Topic->change_bls( mid=>$cs->{mid}, action=>'add', bls=>[$bl], username=>$stash->{username} );
        }
    }
}

sub topic_status {
    my ( $self, $c, $config ) = @_;

    my $stash    = $c->stash;
    my $topics = $config->{topics} // _fail _loc('Missing or invalid parameter topics');
    my $new_status = $config->{new_status} // _fail _loc('Missing or invalid parameter new_status');

    for my $mid ( Util->_array_or_commas( $topics) ) {
        my $topic = ci->new( $mid );
        _log _loc('Changing status for topic %1 to status %2', $topic->topic_name, $new_status);
        Baseliner->model('Topic')->change_status(
            change     => 1,
            id_status  => $new_status,
            mid        => $mid,
            bl         => $stash->{bl},
        );
    }
}

sub update_changesets {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $job   = $c->stash->{job};

    my $log      = $job->logger;
    my $job_type = $job->job_type;

    my $is_rollback = !!$stash->{rollback};
    my $cache_key   = '_update_changesets';

    if ( $job_type eq 'static' ) {
        $self->log->info( _loc("Changesets status not updated. Static job.") );
        return;
    }

    my $status_to;
    my $status_to_rollback;

    if ( $job->is_failed( status => 'last_finish_status' ) ) {
        $status_to          = $config->{status_on_fail};
        $status_to_rollback = $config->{status_on_rollback_fail};
    }
    else {
        $status_to          = $config->{status_on_ok};
        $status_to_rollback = $config->{status_on_rollback_ok};
    }

    if ( $job_type eq 'demote' ) {
        ( $status_to, $status_to_rollback ) = ( $status_to_rollback, $status_to );
    }

    $stash->{$cache_key} //= {};

    for my $cs ( _array( $stash->{changesets} ) ) {
        my $id_next_status = $status_to;

        if ($is_rollback) {

            # rollback to previous status
            $id_next_status = $status_to_rollback || $stash->{$cache_key}->{ $cs->mid };

            if ( !$id_next_status ) {
                _debug _loc( 'No last status data for changeset %1. Skipped.', $cs->title );
                next;
            }
        }
        else {
            # save for rollback
            _debug "Saving changeset status for rollback: " . $cs->mid . " = " . $cs->id_category_status;

            $stash->{$cache_key}->{ $cs->mid } = $cs->id_category_status;
        }

        next unless $id_next_status;

        my $next_status = ci->status->find_one( { id_status => '' . $id_next_status } );
        _fail _loc( 'Status row not found for status `%1`', $id_next_status ) unless $next_status;

        $log->info( _loc( 'Moving changeset %1 (#%2) to status *%3* (%4)', $cs->title, $cs->mid, $next_status->{name}, $id_next_status ) );

        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            username  => $job->username,
            id_status => $id_next_status,
            bl        => $stash->{bl},
            mid       => $cs->mid,
        );
    }

    return 1;
}

sub update_baselines {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $job   = $stash->{job};
    my $log   = $job->logger;
    my $type = $job->job_type;
    my $bl = $job->bl;

    my $rev_repos = $self->_group_revisions_by_repo([_array $stash->{project_changes}]);

    return if $job->is_failed( status => 'last_finish_status');

    $log->info( _loc('Updating baseline for %1 project(s) to %2', scalar(_array $stash->{project_changes}), $bl ) );

    # now update
    for my $revgroup ( values %$rev_repos ) {
        my $project = delete $revgroup->{project};
        my $repo = delete $revgroup->{repo};

        my $updated_baselines;

        if( $job->rollback ) {
            my $previous_ref;
            my $previous_tag;
            my $bl_original = $stash->{bl_original};

            $log->info( _loc( 'Searching for original baseline in %1', $repo->name ) );

            if ( my $repo_stash = $bl_original->{ $repo->mid } ) {
                if ( my $project_stash = $repo_stash->{ $project->mid } ) {
                    $previous_ref = $project_stash->{previous};
                    $previous_tag = $project_stash->{tag};
                }
            }

            if ( $previous_ref && $previous_tag ) {
                $log->info( _loc('Rollbacking baseline %1 for repository %2, job type %3', $previous_tag, $repo->name, $type ) );

                $updated_baselines = $repo->update_baselines(
                    job       => $job,
                    revisions => [$previous_ref],
                    tag       => $previous_tag,
                    type      => $type
                );
            }
            else {
                _warn _loc( 'Could not find previous revision for repository: %1 (%2)', $repo->name, $repo->mid );
            }
        } else {
            my $revisions = [ values %$revgroup ];

            my $prefix;
            if ($repo->tags_mode eq 'release') {
                $prefix = $self->_find_release_version_by_revisions($revisions);
            }

            my $tag = $repo->bl_to_tag($bl, $prefix);

            $log->info( _loc('Updating baseline %1 for repository %2, job type %3', $tag, $repo->name, $type ) );

            $updated_baselines = $repo->update_baselines( job => $job, revisions => $revisions, tag => $tag, type => $type );
        }

        # save previous revision by repo mid
        $stash->{bl_original}->{ $repo->mid }->{ $project->mid } = $updated_baselines;

        $log->info( _loc('Baseline update of %1 item(s) completed', $repo->name), $updated_baselines );
    }
}

sub sync_baselines {
    my ( $self, $c, $config ) = @_;

    my $stash = $c->stash;

    my $job    = $stash->{job};
    my $log    = $job->logger;
    my $type   = $job->job_type;
    my $job_bl = $job->bl;

    return if $job->is_failed( status => 'last_finish_status' );

    my $bl_matched = 0;

    my @bls;
    foreach my $bl_mid ( _array $config->{bls} ) {
        if ( my $bl = ci->new($bl_mid) ) {
            if ($bl->bl eq $job_bl) {
                $bl_matched = 1;
            }
            else {
                push @bls, $bl->bl;
            }
        }
    }

    return unless $bl_matched;

    my $rev_repos = $self->_group_revisions_by_repo([_array $stash->{project_changes}]);

    foreach my $bl_to_sync (@bls) {
        $log->info( _loc( 'Synchronizing baseline `%1` with `%2`', $bl_to_sync, $job_bl ) );

        for my $revgroup ( values %$rev_repos ) {
            my $project = delete $revgroup->{project};
            my $repo = delete $revgroup->{repo};

            my $updated_baselines;

            if( $job->rollback ) {
                my $previous_ref;
                my $previous_tag;
                my $bl_original = $stash->{bl_sync};

                $log->info( _loc( 'Searching for original baseline in %1', $repo->name ) );

                if ( my $repo_stash = $bl_original->{ $repo->mid } ) {
                    if ( my $project_stash = $repo_stash->{ $project->mid } ) {
                        $previous_ref = $project_stash->{previous};
                        $previous_tag = $project_stash->{tag};
                    }
                }

                if ( $previous_ref && $previous_tag ) {
                    $log->info( _loc('Rollbacking baseline %1 for repository %2, job type %3', $previous_tag, $repo->name, $type ) );

                    $updated_baselines = $repo->update_baselines(
                        job       => $job,
                        revisions => [$previous_ref],
                        tag       => $previous_tag,
                        type      => $type
                    );
                }
                else {
                    _warn _loc( 'Could not find previous revision for repository: %1 (%2)', $repo->name, $repo->mid );
                }
            } else {
                my $revisions = [ values %$revgroup ];

                my $prefix;
                if ($repo->tags_mode eq 'release') {
                    $prefix = $self->_find_release_version_by_revisions($revisions);
                }

                my $tag = $repo->bl_to_tag($bl_to_sync, $prefix);

                $log->info( _loc('Updating baseline %1 for repository %2, job type %3', $tag, $repo->name, $type ) );

                $updated_baselines = $repo->update_baselines( job => $job, revisions => $revisions, tag => $tag, type => $type );
            }

            # save previous revision by repo mid
            $stash->{bl_sync}->{ $repo->mid }->{ $project->mid } = $updated_baselines;

            $log->info( _loc( 'Baseline `%1` synchronized with `%2`', $bl_to_sync, $job_bl ) );
        }
    }
}

sub _group_revisions_by_repo {
    my $self = shift;
    my ($project_changes) = @_;

    my %rev_repos;

    # first, group revisions by repository
    for my $pc ( @$project_changes ) {
        my ($project, $repo_revisions_items ) = @{ $pc }{ qw/project repo_revisions_items/ };
        next unless ref $repo_revisions_items eq 'ARRAY';
        for my $rri ( @$repo_revisions_items ) {
            my ($repo, $revisions,$items) = @{ $rri }{ qw/repo revisions items/ };

            # TODO if 2 projects share a repository, need to create different tags with project in str?
            for my $revision ( _array( $revisions ) ) {
                $rev_repos{ $revision->repo->mid }{ 'project' } //= $project;
                $rev_repos{ $revision->repo->mid }{ 'repo' } //= $revision->repo;
                $rev_repos{ $revision->repo->mid }{ $revision->mid } = $revision;
            }
        }
    }

    return \%rev_repos;
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
            my ($project) = ( map { $_->name } $cs->projects );
            $project //= '';
            TOPIC_FILE: for my $tfile ( @files ) {
               my $mid = $tfile->mid;
               my $fieldlet = $meta{ $mid_files{$mid} };
               my $co_dir = $fieldlet->{checkout_dir};
               my $fullpath = ''.Util->_dir( "/", $project, $co_dir, $tfile->filename );
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

            my $tag = $bl;
            if ( $repo->tags_mode eq 'release' ) {
                my $prefix = $self->_find_release_version_by_revisions($revs);
                $tag = $repo->bl_to_tag( $bl, $prefix );
            }

            my @repo_items = $repo->group_items_for_revisions(
                revisions => $revs,
                type      => $type,
                bl        => $bl,
                tag       => $tag,
                project   => $project
            );

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
        $all_items{ $_->{fullpath} || $_->{path}}=$_ for @items;
        push @project_changes, $pc;
    }
    # put unique items into stash
    $stash->{items} = [ values %all_items ];

    # create name list
    my %name_list;
    for my $i ( _array( $stash->{items} ) ) {
        my $f = $i->{fullpath} || $i->{path};
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
    _fail _loc('Missing job_dir') unless length $job_dir;

    my @project_changes = @{ $stash->{project_changes} || [] };

    $log->info( _loc('Checking out baseline for %1 project(s)', scalar(@project_changes) ) );
    for my $pc ( @project_changes ) {
        my ($project, $repo_revisions_items ) = @{ $pc }{ qw/project repo_revisions_items/ };
        next unless ref $repo_revisions_items eq 'ARRAY';
        for my $rri ( @$repo_revisions_items ) {
            my ($repo, $revisions,$items) = @{ $rri }{ qw/repo revisions items/ };

            $self->_checkout_repo(
                job       => $job,
                project   => $project,
                repo      => $repo,
                bl        => $bl,
                revisions => $revisions,
            );
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
    _fail _loc('Missing job_dir') unless length $job_dir;

    my @project_changes = @{ $stash->{project_changes} || [] };

    $log->info( _loc('Checking out baseline for %1 project(s)', scalar(@project_changes) ) );
    for my $pc ( @project_changes ) {
        my ($project) = @{ $pc }{ qw/project/ };
        my @repos = grep { $_->bl =~ /(\*|$bl)/} _array $project->repositories;
        for my $repo ( @repos ) {
            $self->_checkout_repo(
                job     => $job,
                project => $project,
                repo    => $repo,
                bl      => $bl,
            );
        }
    }
}

sub _checkout_repo {
    my $self = shift;
    my (%params) = @_;

    my $job       = $params{job};
    my $project   = $params{project};
    my $repo      = $params{repo};
    my $bl        = $params{bl};
    my $revisions = $params{revisions};

    my $log     = $job->logger;
    my $job_dir = $job->job_dir;

    my $prefix;
    if ($repo->tags_mode eq 'release') {
        $prefix = $self->_find_release_version_by_revisions($revisions);
    }

    my $tag = $repo->bl_to_tag( $bl, $prefix );

    my $dir_prefixed = File::Spec->catdir( $job_dir, $project->name, $repo->rel_path );
    $log->info(
        _loc( 'Checking out baseline %1 for project %2, repository %3: %4',
            $tag, $project->name, $repo->name, $dir_prefixed )
    );

    my $co_info = $repo->checkout( tag => $tag, dir => $dir_prefixed, project => $project, revisions => $revisions );

    my @ls = _array( $co_info->{ls} );
    $log->info( _loc( 'Baseline checkout of %1 item(s) completed', scalar(@ls) ), join( "\n", @ls ) );

    return $self;
}

sub checkout {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $job_dir = $job->job_dir;
    _fail _loc('Missing job_dir') unless length $job_dir;

    my $cnt = 0;
    # TODO group all items by repo provider and ask repo for a multi-item checkout
    my @items = _array( $stash->{items} );
    for my $item ( @items ) {
        $item->checkout( dir=>$job_dir );
        $cnt++;
    }

    $log->info(
        _loc( 'Checked out %1 item(s) to %2', $cnt, $job_dir ),
        [   map {
                    my $path = $_->{fullpath} || $_->{path};
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

    my $commit_items = $config->{commit_items} // 0;

    $stash->{natures} = {};
    my $nat_id = $config->{nature_id} // 'name';  # moniker?
    $log->info( _loc('Starting nature analysis for all job items...') );

    my @nat_rows =  ci->nature->find({active=>'1'})->fields({ mid=>1 })->all;
    my @projects = _array( $job->projects );
    my $start_t = Util->_ts();
    my $item_cnt = 0;
    for my $project ( @projects ) {
        #my @items = @{ $stash->{items} || [] };
        my @items = @{ $stash->{project_items}{ $project->mid }{items} || [] };
        # $log->debug( _loc('Project items before for %1', $project->name), \@items );
        my %nature_names;
        my @msg;
        for my $nature ( map { ci->new($_->{mid}) } @nat_rows ) {
            my $nature_clon = Util->_clone( $nature );
            my @chosen;
            push @msg, "nature = " . $nature->name;
            ITEM: for my $it ( @items ) {
                $item_cnt++;
                if( $commit_items && $it->ns && !ci->find( ns=>$it->ns) ) {
                    $it->save;
                }
                push @msg, "item = " . $it->{fullpath} if $it->{fullpath};
                if( $nature->push_item( $it ) ) {
                    my $id =  $nature->$nat_id;
                    my $mid =  $nature->mid;
                    $stash->{natures}{ $project->mid }{ $id } = $nature;
                    $stash->{natures}{ $project->mid }{ $mid } = $nature;
                    $nature_names{ $nature->name }++;
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
        $log->debug( _loc('%1 analysis executed in %2 seconds', $item_cnt, -($start_t - Util->_ts()) ) );
        my @nats = keys %nature_names;
        if( my $cnt = scalar @nats ) {
            $log->info( _loc('%1 nature(s) detected in job items: %2', $cnt, join ', ', map{ sprintf '%s (%d)', $_, $nature_names{$_}//0 } @nats ) );
        } else {
            $log->warn( _loc('No natures detected in job items') );
        }
    }
    return 0;
}

register 'service.approval.request' => {
    name    => _locl('Request Approval'),
    icon => '/static/images/icons/service-approval-request.svg',
    form => '/forms/approval_request.js',
    job_service  => 1,
    handler => \&request_approval,
};

register 'event.job.approval_request' => {
    text        => _locl('Approval requested for job %3 (user %1)'),
    description => _locl('approval requested for job'),
    vars        => [ 'username', 'ts', 'name', 'bl', 'status', 'step' ],
    notify      => {
        scope => [ 'project', 'bl' ],
    },
};
register 'event.job.approved' => {
    text        => _locl('Job %3 Approved'),
    description => _locl('Job Approved'),
    vars        => [ 'username', 'ts', 'name', 'bl', 'status', 'step', 'comments' ],
    notify => { scope => [ 'project', 'bl' ] },
};
register 'event.job.rejected' => {
    text        => _locl('Job %3 Rejected'),
    description => _locl('Job Rejected'),
    vars        => [ 'username', 'ts', 'name', 'bl', 'status', 'step', 'comments' ],
    notify => { scope => [ 'project', 'bl' ] },
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

sub _find_release_version_by_revisions {
    my $self = shift;
    my ($revisions) = @_;

    return unless $revisions && @$revisions;

    my $changeset_rel;
    foreach my $revision (@$revisions) {
        ($changeset_rel) = $revision->parents( where => { collection => 'topic' }, mids_only => 1 );
        last if $changeset_rel;
    }

    my $changeset = mdb->topic->find_one({mid => $changeset_rel->{mid}});
    return unless $changeset;

    require Baseliner::Model::Topic;
    my $topics_model = Baseliner::Model::Topic->new;
    return unless my ($release_field) =
      $topics_model->get_meta_fields_by_key( $changeset->{mid}, 'fieldlet.system.release' );
    return unless my ($release_mid) = _array $changeset->{$release_field};

    my $release = mdb->topic->find_one({mid => $release_mid});
    return unless $release;

    return unless my ($release_version_field) =
      $topics_model->get_meta_fields_by_key( $release->{mid}, 'fieldlet.system.release_version' );
    return $release->{$release_version_field};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
