package BaselinerX::CI::GitRepository;
use Baseliner::Moose;

use Git;
use Try::Tiny;
use experimental 'smartmatch';
use Girl;
use Baseliner::Utils;
use BaselinerX::CI::bl;
use BaselinerX::CI::GitRevision;
use BaselinerX::GitBranch;

with 'Baseliner::Role::CI::Repository';

has repo_dir        => qw(is rw isa Str);
has name            => qw(is rw isa Str);
has default_branch  => qw(is rw isa Str default HEAD);
has revision_mode   => qw(is rw isa Str default diff);
has include   => qw(is rw isa Any);
has exclude   => qw(is rw isa Any);

sub collection { 'GitRepository' }
sub icon       { '/static/images/icons/git.svg' }

sub has_bl { 1 }

service 'create_tags' => {
    name    => _loc('Create system tags'),
    form    => '/forms/repo_create_tags.js',
    icon    => '/static/images/icons/git.svg',
    handler => \&create_tags_handler
};

sub get_system_tags {
    my $self = shift;

    my @bls = grep { $_ ne '*' } map { $_->{bl}} ci->bl->find({active => '1'})->all;
    my @tags = @bls;

    if ($self->tags_mode eq 'release') {
        my @projects = map { ci->new( $_->{mid} ) } $self->related(
            where     => { collection => 'project' },
            docs_only => 1
        );

        _fail _loc( 'Projects are required when creating baselines ' . 'for repositories with tags_mode project' )
          unless @projects;

        my @release_versions = $self->_find_release_versions_by_projects( \@projects );

        foreach my $release_version (@release_versions) {
            foreach my $bl (@bls) {
                push @tags, $self->bl_to_tag( $bl, $release_version );
            }
        }
    }

    return @tags;
}

sub create_tags_handler {
    my ( $self, $c, $config ) = @_;

    my $repo;

    # Rule mode
    if ($config->{repo}) {
        my ($repo_mid) = _array $config->{repo};

        $repo = ci->new($repo_mid);
    }

    # Service mode
    else {
        $repo = $self;
    }

    my $ref        = $config->{'ref'};
    my $existing   = $config->{'existing'} || 'detect';
    my $tag_filter = join '|', split ',', ($config->{'tag_filter'} // '');

    my $git = $repo->git;

    if ( !$ref ) {
        ($ref) = reverse $git->exec( 'rev-list', $repo->default_branch // 'HEAD' );
    }

    my @tags = $repo->get_system_tags;

    @tags = grep { /^(?:$tag_filter)$/ } @tags if $tag_filter;

    my @out;
    foreach my $tag (@tags) {
        if ( $existing eq 'detect' ) {
            next if try {
                my ($tag_ref) = $git->exec( 'rev-parse', $tag );
                _log "Tag $tag already exists ($tag_ref). Skipped";
                1;
            }
            catch {
                _log "Tag $tag not found. Replacing...";
                0;
            };
        }

        _log "Creating tag $tag for ref $ref";
        push @out, $git->exec( 'tag', '-f', $tag, $ref );
    }

    return join "\n", @out;
}

sub repository {
    my ( $self, %p ) = @_;
    my $repo = Girl::Repo->new( path => $self->repo_dir );
}

sub git {
    my ($self) = @_;
    return $self->repository->git;
}

sub group_items_for_revisions {
    my ($self,%p) = @_;
    my $revisions = $p{revisions};
    my $project = $p{project};
    my $type = $p{type} || 'promote';
    my $bl = $p{bl};
    my $tag = $p{tag};
    my @items;
    if( $self->revision_mode eq 'show' ) {
        my %all_revs = map { $_->sha_long => $_ } _array($revisions);
        my @ordered_revs = $self->_order_revisions(keys %all_revs);
        @ordered_revs = reverse @ordered_revs if $type ne 'demote';
        _debug( \@ordered_revs );
        my %items_uniq;
        for my $rev ( map { $all_revs{$_} } @ordered_revs ) {
            my @rev_items = $rev->show( type=>$p{type} );
            $items_uniq{$_->path} = $_ for @rev_items;
        }
        # TODO --- in demote, blob is empty for deleted items status=D, which in demote are changed to status=A
        @items = values %items_uniq;
    } else {
        my $tag = $p{tag} or _fail _loc('Missing parameter tag needed for top revision');

        my $top_rev = $self->top_revision( revisions=>$revisions, type=>$type, tag=>$tag );
        if( !$top_rev ) {
            _fail(_loc('Could not find top revision in repository %1 for tag %2. Attempting to redeploy to environment?', $self->name, $tag))
        }

        if ( $type eq 'promote' ) {
            my $rev_sha = $top_rev->sha_long;
            my $tag_sha = $self->git->exec( qw/rev-parse/, $tag );

            if ( $rev_sha eq $tag_sha ) {
                my ( $job, $found_tag_sha ) = $self->_find_sha_from_previous_jobs( $project, $top_rev, $bl, $tag );

                if ($found_tag_sha) {
                    $tag = $found_tag_sha;
                    _warn _loc( "Tag %3 sha set to %1 as it was in previous job %2", $found_tag_sha, $job->{name},
                        $tag );
                }
                else {
                    _fail _loc( "No last job detected for commit %1.  Cannot redeploy it", $tag_sha );
                }
            }
        }

        @items = $top_rev->items( tag=>$tag, type=>$type );
    }
    # prepend path prefix for repo
    #  my $rel_path = $self->rel_path;
    #  @items = map {
    #      my $it = $_;
    #      $it->path( $rel_path, $it->path ) if length $rel_path && $rel_path ne '/';
    #      $it;
    #  } @items;
    return @items;
}

sub items {
    my ($self, %p ) = @_;
    my $revisions = $p{revisions};
    my $tag = $p{tag};

}

method verify_revisions( :$revisions, :$tag, :$type='promote' ) {
    $self->top_revision( revisions=>$revisions, tag=>$tag, type=>$type );
}

method top_revision( :$revisions, :$tag, :$type='promote', :$check_history=1 ) {
    my $git = $self->git;

    my @revisions = _array($revisions) or _fail 'Error: No revisions passed';

    my %shas;
    foreach my $revision (@revisions) {
        my $ref = $revision->{sha};

        my $sha = try { $git->exec('rev-parse', $ref) }
        catch {
            _fail _loc("Error: revision `%1` not found in repository %2", $ref, $self->name),
              $self->name
        };

        $shas{$sha} = $revision;
    }

    # get the tag sha
    my $tag_sha = try {
        $git->exec('rev-parse', $tag);
    }
    catch {
        _fail _loc("Error: tag `%1` not found in repository %2", $tag,
            $self->name)
    };

    my @shas = keys %shas;

    _debug "Looking for top revision among shas: " . join ',', map { substr $_, 0, 8 } @shas;

    my @sorted = $self->_order_revisions(@shas);

    my $top_rev;
    if ($type eq 'promote') {
        my $first_sha = $sorted[0];
        _warn _loc("Tag %1 (sha %2) is already on top", $tag, $tag_sha)
          if $first_sha eq $tag_sha;
        $top_rev = $shas{$first_sha};
    }
    elsif ($type eq 'static') {
        my $first_sha = $sorted[0];

        $top_rev = $shas{$first_sha};
    }
    elsif ($type eq 'demote') {
        my $last_sha = $sorted[-1];

        my $before_last = try {
            $git->exec('rev-parse', $last_sha . '~1');
        }
        catch {
            _fail _loc
              "Trying to demote all revisions in a repository, "
              . "can't set tag %1 before %2",
              $tag,
              substr($last_sha, 0, 8);
        };

        _warn _loc("Tag %1 (sha %2) is already at the bottom", $tag, $tag_sha)
          if $before_last eq $tag_sha;

        $top_rev = BaselinerX::CI::GitRevision->new(
            sha  => $before_last,
            name => $tag,
            repo => $self
        );
    }

    if ($top_rev && $check_history) {
        my ($orig, $dest) =
          $type eq 'demote'
          ? ($top_rev->{sha}, $tag_sha)
          : ($tag_sha, $top_rev->{sha});

        _debug _loc("Looking for common history between %1 and %2", $orig,
            $dest);

        try {
            $git->exec('merge-base', '--is-ancestor', $orig, $dest);
        }
        catch {
            _fail _loc(
                "Cannot %1 commit [%2] to %3 since "
                  . "they don't have common history and doing that may cause regressions. "
                  . "You probably need to merge branches",
                _loc($type), substr($top_rev->{sha}, 0, 8), $tag
            );
        };

        my $valid = 1;
        for my $sha (keys %shas) {
            try {
                $git->exec('merge-base', '--is-ancestor', $sha, $dest);
            }
            catch {
                _error _loc(
                    "Revision [%1] is not in the top revision's history",
                    substr($sha, 0, 8));
                $valid = 0;
            };
        }

        if (!$valid) {
            _fail _loc(
                "Not all commits are in [%1] history. "
                  . "You probably need to merge branches",
                substr($dest, 0, 8)
            );
        }
    }

    return $top_rev;
}

sub checkout {
    my ( $self, %p ) = @_;

    my $dir = $p{dir} // _fail 'Missing parameter dir';
    my $tag = $p{tag} // _fail 'Missing parameter tag';

    my $git = $self->git;

    if ( !-d $dir ) {
        _mkpath $dir;
        _fail _loc( "Could not find or create directory %1: %2", $dir, $! )
          unless -d $dir;
    }

    my $tag_sha = try {
        $git->exec( 'rev-parse', $tag )
    }
    catch {
        _fail _loc( "Error: tag `%1` not found in repository %2", $tag, $self->name )
    };

    # get dir listing
    my @ls = $git->exec( qw/ls-tree -r -t -l --abbrev=7/, $tag_sha );
    if ( !@ls ) {
        return { ls => [], output => Util->_loc( 'No files for ref %1 in repository. Skipping', $tag ) };
    }

    # save curr dir, chdir to repo, archive only works from within (?)
    my $cwd = Cwd::cwd;
    chdir $dir;

    my $out;
    try {
        $out = $git->exec( "archive '$tag' | tar x", { cmd_unquoted => 1 } );
        _log _loc("*Git*: checkout of repository %1 (%2) into `%3`", $self->repo_dir, $tag, $dir);

        chdir $cwd;
    } catch {
        my $error = shift;

        chdir $cwd;

        die $error;
    };

    return { ls => \@ls, output => $out };
}

sub list_elements {
    my ( $self, %p ) = @_;

    my $job   = $self->job;
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    my $bl    = $job->bl;
    my $rev = $p{rev};
    my $prj  = $p{prj};
    my $repo_name = $self->mid;

    my @elems;

    #Load rev & bl sha
    my $rev_sha;
    my $bl_sha;
    my $bl_def = $rev eq 'DESA'? 'master':$bl;
    my $rev_def = $rev eq 'DESA'? 'master':$rev;
    my $repo = $self->repository;
    my $git  = $repo->git;


    #_log $_ for $git->exec(qw/tag/);

    if (   $job->stash->{$self->mid . $rev}->{git_rev_sha}
        && $job->stash->{$self->mid . $rev}->{git_bl_sha} )
    {
        $rev_sha = $job->stash->{$self->mid . $rev}->{git_rev_sha};
        $bl_sha  = $job->stash->{$self->mid . $rev}->{git_bl_sha};
    } else {
        $rev_sha = $repo->git->exec( qw/rev-parse/, $rev_def );
        $bl_sha  = $repo->git->exec( qw/rev-parse/, $bl_def );
        $job->stash->{$self->mid . $rev}->{git_rev_sha} = $rev_sha;
        $job->stash->{$self->mid . $rev}->{git_bl_sha}  = $bl_sha;
    } ## end else [ if ( $job->stash->{$repo_name...})]

    # job elements
    if ( $job->job_type eq 'demote' || $job->rollback ) {
        @elems = $git->exec( qw/diff --name-status/, $bl_sha, $rev_sha . "~1" );
    } else {
        if ( $rev_sha ne $bl_sha ) {
            $log->debug( "BL and REV distinct" );
            @elems = $git->exec( qw/diff --name-status/, $bl_sha, $rev_sha );
        } else {
            $log->debug( "BL and REV equal" );
            @elems = $git->exec( qw/ls-tree -r --name-status/, $bl_sha );
            @elems = map { my $item = 'M   ' . $_; } @elems;
        }
    } ## end else [ if ( $job->job_type eq...)]

    $log->debug( "Elements in tree", data => join "\n", @elems );
    my $count = scalar @elems;
    my $prjdir =  _dir $prj, $repo_name;
    $log->info( _loc( "*Git* Job Elements %1", $count ), data => join "\n", map {
            my ( $status, $blanks, $path ) = /^(.*?)(\s+)(.*)$/;
            $status.$blanks._dir $self->rel_path,$path;
        }@elems
    );
    @elems = map {
        my ( $status, $path ) = /^(.*?)\s+(.*)$/;
        my $fullpath = _dir "/", $prjdir, $self->rel_path, $path;
        BaselinerX::GitElement->new( fullpath => "$fullpath", status => $status, version => 1 );
    } @elems;
    return @elems;
} ## end sub list_elements

method update_baselines( :$job, :$revisions, :$tag, :$type ) {
    my $git = $self->git;

    my $top_rev = $self->top_revision( revisions=>$revisions, type=>$type, tag=>$tag , check_history => 0 );

    $top_rev = $top_rev->{sha} if ref $top_rev;  # new tag location
    my $tag_sha = $git->exec( 'rev-parse', $tag );  # bl tag
    my $previous = BaselinerX::CI::GitRevision->new( sha=>$tag_sha, name=>$tag );
    my $out='';

    # no need to update if it's already there
    if ( $top_rev eq $tag_sha ) {
        return {
            current  => BaselinerX::CI::GitRevision->new( sha => $top_rev, name => $tag ),
            previous => $previous,
            output   => $out,
            tag      => $tag
        };
    }

    # rgo: TODO in show revision_mode people deploy earlier commits over the tag base, which leads
    #    to a undefined deployment situation

    if( $type eq 'promote' ) {
        _debug( _loc("Promote baseline $tag to $top_rev: tag -f $tag $top_rev" ) );
        $out = $git->exec( qw/tag -f/, $tag, $top_rev );
        _log _loc( "Promoted baseline %1 to %2", $tag, $top_rev);
    }
    elsif( $type eq 'demote' ) {
        _debug( _loc("Demote baseline $tag to $top_rev: tag -f $tag $top_rev" ) );
        $out = $git->exec( qw/tag -f/, $tag, $top_rev );
        _log _loc( "Demoted baseline %1 to %2", $tag, $top_rev), data=>$out;
    }
    elsif( $type eq 'static' ) {
        _debug( _loc("Updating baseline $tag to $top_rev: tag -f $tag $top_rev" ) );
        $out = $git->exec( qw/tag -f/, $tag, $top_rev );
        _log _loc( "Updated baseline %1 to %2", $tag, $top_rev);
    }

    return {
        current  => BaselinerX::CI::GitRevision->new( sha => $top_rev, name => $tag ),
        previous => $previous,
        output   => $out,
        tag      => $tag
    };
}

sub get_last_commit {
    my ( $self, %p ) = @_;

    my $job      = $self->job;
    my $log      = $job->logger;
    my $stash    = $job->job_stash;
    my $bl       = $job->bl;
    my $job_type = $job->job_type;
    my @commits  = _array $p{commits};
    my $repo     = $self->repository;
    my $git      = $repo->git;

    my @shas = sort(map { $_->{sha} } @commits);

    $log->debug( "Lista de commits",  data => join "\n",@shas );

#   my @log = $git->exec( qw/log --pretty=oneline/);
    if ( scalar @commits == 1 ) { return $commits[0]->{sha} };

    for my $change_commit ( @commits ) {
        $log->debug( "Mirando si el commit ".$change_commit->{sha}." incluye al resto");
        my $direction;
        if ( $job_type eq 'demote' || $job->rollback ) {
            $direction = $change_commit->{sha}."..".$bl;
        } else {
            $direction = $bl . ".." . $change_commit->{sha};
        }

        my @gitlog =
            $git->exec( 'rev-list', '--pretty=oneline', $direction );

        $log->debug("Salida de rev-list", data => join "\n", @gitlog);

        @gitlog = map { my @parts = split " ", $_; shift @parts;} @gitlog;

        my @intersect = sort(grep { ( $_ ~~ @shas ) } @gitlog);

        $log->debug( "Lista de commits comunes",  data => join "\n",@intersect );

        if ( @intersect ~~ @shas ) {
            $log->debug( "He entrado por el if");
            return $change_commit->{sha};
        }
    } ## end for my $change_commit (...)
}

sub list_branches {
    my ( $self, %p ) = @_;

    my $repo_name = $self->{name};
    my $repo_dir  = $self->{repo_dir};
    my $project = $p{project};
    my $id_project = $p{id_project};

    my @changes;

    my $repo = Girl::Repo->new( path => $repo_dir );    # TODO combine repos

    my @heads = $repo->heads;    # git local branches
                                 #$p{bl} and @heads = grep { $_->name =~ /^$p{bl}/ } @heads;

    if ( _array($self->include) ) {
        my $includes = '^('.join('|', _array($self->include)).')$';
        @heads = grep { $_->{name} =~ /$includes/ } @heads;
    }

    if ( _array($self->exclude) ) {
        my $excludes = '^('.join('|', _array($self->exclude)).')$';
        @heads = grep { $_->{name} !~ /$excludes/ } @heads;
    }

    push @changes, map {

        BaselinerX::GitBranch->new(
            {
                head         => $_,
                repo_dir     => $repo_dir,
                name         => $_->name,
                repo_name    => $repo_name,
                project      => $project,
                id_project   => $id_project,
                repo_mid     => $self->mid,
                username     => $p{username}
            }
        );
    } @heads;

    return @changes;
} ## end sub list_branches

sub close_branch {
    my ( $self, $p ) = @_;

    my $branch = $p->{branch};

    my @exclude = _array($self->exclude);
    if ( !($branch ~~ @exclude) ) {
        push @exclude, $branch;
        $self->update( exclude => \@exclude );
    }
}

method commits_for_branch( :$branch, :$project, :$page=1, :$page_size=30, :$show_commit_tag=1 ) {
    my $revision_mode = $self->revision_mode;
    my @rev_list;
    my $git  = $self->git;
    if( $revision_mode eq 'diff' ){
        my $tag = [ grep { $_ ne '*' } map { $_->bl } sort { $a->seq <=> $b->seq } BaselinerX::CI::bl->search_cis ]->[0];
        $tag = $self->bl_to_tag($tag);
        my $skip = ($page-1) * $page_size;

        # check if tag exists
        my $bl_exists = $git->exec( 'rev-parse', $tag, { on_error_empty => 1 } );
        Util->_fail( Util->_loc( 'Error: could not find tag %1 in repository. Repository tags are configured?', $tag ) )
            unless $bl_exists;
        $page_size++;
        @rev_list = $git->exec(
            'rev-list',     '--pretty=oneline', '--right-only', "--max-count=$page_size",
            "--skip=$skip", $tag . "..." . $branch
        );

        if ($show_commit_tag) {
            my $commit_tag = $git->exec( 'rev-list', '--pretty=oneline', '--right-only', '--max-count=1', $tag );
            push @rev_list, $commit_tag;
        }
    } else {
        @rev_list = $git->exec( 'rev-list', '--pretty=oneline', '--right-only',"--max-count=$page_size", $branch);
    }

    return @rev_list;
}

method bl_to_tag(Maybe[Str] $bl = undef, Any $prefix = undef) {
    my ($bl, $project) = @_;

    return unless $bl;

    return $bl unless $prefix;

    return sprintf( '%s-%s', $prefix, $bl);
}

sub _order_revisions {
    my $self = shift;
    my (@shas) = @_;

    my %shas = map { $_ => 1 } @shas;
    my $shas_count = keys %shas;

    my $repo = Git->repository(Directory => $self->repo_dir);
    my ($fh, $ctx) = $repo->command_output_pipe('rev-list', '--topo-order', keys %shas);

    my @sorted;
    while (my $line = <$fh>) {
        chomp($line);

        if ($shas{$line}) {
            push @sorted, $line;

            if (@sorted == $shas_count) {
                last;
            }
        }
    }

    $repo->command_close_pipe($fh, $ctx);

    if (@sorted != $shas_count) {
        _fail _loc("Not all given commits were found: %1", join(', ', keys %shas));
    }

    return @sorted;
}

sub _find_release_versions_by_projects {
    my $self = shift;
    my ($projects) = @_;

    my @projects = _array $projects;

    my @release_versions;

    my @release_categories =
      mdb->category->find( { is_release => '1' } )->fields( { id => 1 } )->all;

    my @id_statuses = map { $_->{id_status} }
      ci->status->find( { type => { '$not' => qr/I|F|FC/ } } )->fields( { id_status => 1 } )->all;

    require Baseliner::Model::Topic;
    my $topics_model = Baseliner::Model::Topic->new;
    foreach my $release_category (@release_categories) {
        my $meta = $topics_model->get_meta( undef, $release_category->{id} );

        my ($release_version_field) = map { $_->{id_field} }
          grep { $_->{key} eq 'fieldlet.system.release_version' } @$meta;
        next unless $release_version_field;

        my ($project_field) = map { $_->{id_field} }
          grep { $_->{key} eq 'fieldlet.system.projects' } @$meta;
        next unless $project_field;

        my @releases = mdb->topic->find(
            {
                is_release         => '1',
                id_category_status => mdb->in(@id_statuses),
                $project_field => mdb->in( map { $_->{mid} } @projects )
            }
        )->all;

        foreach my $release (@releases) {
            my $version = $release->{$release_version_field};
            next unless $version;

            push @release_versions, $version;
        }
    }

    return @release_versions;
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

sub _find_sha_from_previous_jobs {
    my $self = shift;
    my ($project, $top_rev, $bl, $tag) = @_;

    _debug sprintf 'Searching for previous job of sha %s for tag %s', $top_rev->sha, $tag;

    my $git = $self->git;

    my @topics = map { $_->{mid} } $top_rev->parents( where => { collection => 'topic'}, mids_only => 1);

    if ( scalar(@topics) eq 0 ) {
        _fail _loc("No changesets for this sha %1", substr($top_rev->sha, 0, 8));
    } elsif ( scalar(@topics) gt 1 ) {
        _fail _loc("This sha %1 is contained in more than one changeset: %2", substr($top_rev->sha, 0, 8), join(',', @topics));
    }
    my $cs = $topics[0];

    my (@last_jobs) = map {
        $_->{mid}
    } sort {
        $b->{endtime} cmp $a->{endtime}
    } grep {
        $_->{final_status} eq 'FINISHED' && $_->{bl} eq $bl
    } ci->new($cs)->jobs;

    return unless @last_jobs;

    my $last_job;
    my $job;
    my $st;

    for $last_job ( @last_jobs ) {
        $job = ci->new($last_job);
        $st = $job->stash;
        if ( my $bl_original = $st->{bl_original}) {
            my $repo_original = $bl_original->{ $self->mid }->{ $project->mid };

            next unless $repo_original;

            if ($bl ne $tag) {
                next unless $repo_original->{tag} && $repo_original->{tag} eq $tag;
            }

            my $tag_sha = $repo_original->{previous};

            if ($tag_sha && $tag_sha->sha ne $top_rev->sha) {
                return ($job, $tag_sha->sha);
            }
        }
    }

    return;
}

1;
