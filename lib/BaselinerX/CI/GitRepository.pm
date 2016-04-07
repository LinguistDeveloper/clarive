package BaselinerX::CI::GitRepository;
use Baseliner::Moose;

use Git;
use Try::Tiny;
use experimental 'smartmatch';
use Girl;
use Baseliner::Utils;
use Baseliner::Model::Topic;
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
sub icon       { '/static/images/icons/git.png' }
#sub icon       { '/static/images/icons/git-repo.gif' }

sub has_bl { 1 }

service 'create_tags' => {
    name    => _loc('Create tags'),
    form    => '/forms/repo_create_tags.js',
    icon    => '/static/images/icons/git.png',
    #icon    => '/gitweb/images/icons/git.png',
    handler => \&create_tags_handler
};

sub get_system_tags {
    my $self = shift;
    my @tags;
    my @bls = grep { $_ ne '*' } map { $_->bl } BaselinerX::CI::bl->search_cis;
    my @tags_modes = $self->tags_mode ? ( split /,/, $self->tags_mode ) : ();

    if ( grep { $_ eq 'project' } @tags_modes ) {
        my @projects = map { ci->new( $_->{mid} ) } $self->related(
            where     => { collection => 'project' },
            docs_only => 1
        );

        _fail _loc( 'Projects are required when creating baselines ' . 'for repositories with tags_mode project' )
            unless @projects;

        foreach my $bl (@bls) {
            push @tags, map { $self->bl_to_tag( $bl, $_ ) } @projects;
        }

        if ( grep { $_ eq 'release' } @tags_modes ) {
            my @release_versions = $self->_find_release_versions_by_projects( \@projects );

            foreach my $release_version (@release_versions) {
                foreach my $bl (@bls) {
                    push @tags, $self->bl_to_tag( $bl, $release_version );
                }
            }
        }
    }
    else {
        @tags = @bls;
    }

    return @tags;
}


sub create_tags_handler {
    my ( $self, $c, $config ) = @_;
    my $repo = $self;
    my $ref        = $config->{'ref'};
    my $existing   = $config->{'existing'} || 'detect';
    my $tag_filter = join '|', split ',', ($config->{'tag_filter'} // '');

    my $git = $self->git;

    if ( !$ref ) {
        ($ref) = reverse $git->exec( 'rev-list', $self->default_branch // 'HEAD' );
    }

    my @tags = $self->get_system_tags($repo);   

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
    my $type = $p{type} || 'promote';
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
        my $bl = $p{bl} or _fail _loc('Missing parameter bl needed for top revision');

        my $prefix;
        if ($self->tags_mode eq 'project') {
            $prefix = $p{project};
        }
        elsif ($self->tags_mode eq 'release,project') {
            $prefix = $self->_find_release_version_by_revisions($revisions);

            if (!$prefix) {
                $prefix = $p{project};
            }
        }

        my $tag = $self->bl_to_tag($bl, $prefix);

        my $top_rev = $self->top_revision( revisions=>$revisions, type=>$type, tag=>$tag );
        if( !$top_rev ) {
            _fail(_loc('Could not find top revision in repository %1 for tag %2. Attempting to redeploy to environment?', $self->name, $tag))
        }
        @items = $top_rev->items( bl=>$bl, tag=>$tag, type=>$type, project=>$p{project} );
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
            _fail _loc "Error: revision `%1` not found in repository %2", $ref,
              $self->name
        };

        $shas{$sha}++;
    }

    _debug "looking for top revision among shas: " . join ',', keys %shas;

    # get the tag sha
    my $tag_sha = try {
        $git->exec('rev-parse', $tag);
    }
    catch {
        _fail _loc("Error: tag `%1` not found in repository %2", $tag,
            $self->name)
    };

    my @sorted = $self->_order_revisions(keys %shas, $tag_sha);

    my $top_rev;
    if ($type eq 'promote') {
        my $first_sha = $sorted[0];
        _warn _loc "Tag %1 (sha %2) is already on top", $tag, $tag_sha
          if $first_sha eq $tag_sha;
        $top_rev = BaselinerX::CI::GitRevision->new(
            sha  => $first_sha,
            name => $tag,
            repo => $self
        );
    }
    elsif ($type eq 'static') {
        my $first_sha = $sorted[0];
        $top_rev = BaselinerX::CI::GitRevision->new(
            sha  => $first_sha,
            name => $tag,
            repo => $self
        );
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
              substr($last_sha, 0, 7);
        };

        _warn _loc "Tag %1 (sha %2) is already at the bottom", $tag, $tag_sha
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
                _loc($type), substr($top_rev->{sha}, 0, 6), $tag
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
                    substr($sha, 0, 6));
                $valid = 0;
            };
        }

        if (!$valid) {
            _fail _loc(
                "Not all commits are in [%1] history. "
                  . "You probably need to merge branches",
                substr($dest, 0, 6)
            );
        }
    }

    return $top_rev;
}

sub checkout {
    my ( $self, %p ) = @_;

    my $dir = $p{dir} // _fail 'Missing parameter dir';
    my $bl  = $p{bl}  // _fail 'Missing parameter bl';

    my $tag = $bl;
    if ( $self->tags_mode eq 'project' ) {
        $tag = $self->bl_to_tag( $bl, $p{project} );
    }
    elsif ($self->tags_mode eq 'release,project') {
        my $revisions = $p{revisions} or _fail 'Missing parameter revisions';

        my $prefix = $self->_find_release_version_by_revisions($revisions);
        $prefix //= $p{project};

        $tag = $self->bl_to_tag( $bl, $prefix );
    }

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

method update_baselines( :$job, :$revisions, :$bl, :$type, :$ref=undef ) {
    my $git = $self->git;

    my @projects;

    if ( $self->tags_mode eq 'project' || $self->tags_mode eq 'release,project' ) {
        foreach my $project ( _array( $job->{projects} ) ) {
            next
              unless $project->{repositories}
              && grep { $self->mid eq $_->{mid} } @{ $project->{repositories} };

            push @projects, $project;
        }

        _fail _loc( 'Projects are required when moving baselines for repositories with tags_mode project' )
          unless @projects;
    }
    else {
        @projects = ('*');
    }

    my $release_version = $self->_find_release_version_by_revisions($revisions);

    my %retval;
    for my $project ( @projects ) {
        my $retval_key = $project eq '*' ? '*' : ($release_version || $project->mid);

        my $tag = $self->bl_to_tag($bl, $release_version || $project);

        my $top_rev = $ref // $self->top_revision( revisions=>$revisions, type=>$type, tag=>$tag , check_history => 0 );

        $top_rev = $top_rev->{sha} if ref $top_rev;  # new tag location
        my $tag_sha = $git->exec( 'rev-parse', $tag );  # bl tag
        my $previous = BaselinerX::CI::GitRevision->new( sha=>$tag_sha, name=>$tag );
        my $out='';

        # no need to update if it's already there
        if ( $top_rev eq $tag_sha ) {
            $retval{$retval_key} = {
                current  => BaselinerX::CI::GitRevision->new(sha => $top_rev, name => $tag),
                previous => $previous,
                output   => $out
            };

            next;
        }
        
        # rgo: TODO in show revision_mode people deploy earlier commits over the tag base, which leads
        #    to a undefined deployment situation
        
        if( $type eq 'promote' ) {
            _debug( _loc "Promote baseline $tag to $top_rev: tag -f $tag $top_rev" );
            $out = $git->exec( qw/tag -f/, $tag, $top_rev );
            _log _loc( "Promoted baseline %1 to %2", $tag, $top_rev);
        }
        elsif( $type eq 'demote' ) {
            _debug( _loc "Demote baseline $tag to $top_rev: tag -f $tag $top_rev" );
            $out = $git->exec( qw/tag -f/, $tag, $top_rev );
            _log _loc( "Demoted baseline %1 to %2", $tag, $top_rev), data=>$out;
        }
        elsif( $type eq 'static' ) {
            _debug( _loc "Updating baseline $tag to $top_rev: tag -f $tag $top_rev" );
            $out = $git->exec( qw/tag -f/, $tag, $top_rev );
            _log _loc( "Updated baseline %1 to %2", $tag, $top_rev);
        }

        $retval{$retval_key} = {
            current  => BaselinerX::CI::GitRevision->new(sha => $top_rev, name => $tag),
            previous => $previous,
            output   => $out
        };
    }

    return \%retval;
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

method commits_for_branch( :$branch, :$project ) {
    my $git = $self->git;

    my $tag = [ grep { $_ ne '*' } map { $_->bl } sort { $a->seq <=> $b->seq } BaselinerX::CI::bl->search_cis ]->[0];

    $tag = $self->bl_to_tag($tag, $project);

    # check if tag exists
    my $bl_exists = $git->exec( 'rev-parse', $tag, { on_error_empty=>1 });
    Util->_fail( Util->_loc('Error: could not find tag %1 in repository. Repository tags are configured?', $tag) ) unless $bl_exists;
    my @rev_list = $git->exec( 'rev-list', '--pretty=oneline', '--right-only','--max-count=30', $tag."...".$branch );
    my $commit_tag = $git->exec( 'rev-list', '--pretty=oneline', '--right-only','--max-count=1', $tag );
    push @rev_list, $commit_tag;
    return @rev_list;
}

method bl_to_tag(Maybe[Str] $bl = undef, Any $prefix = undef) {
    my ($bl, $project) = @_;

    return unless $bl;

    return $bl if $self->tags_mode eq 'bl';

    _fail 'prefix is required' unless $prefix;

    if (ref $prefix) {
        $prefix = $prefix->moniker or _fail 'prefix has to have moniker';
    }

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
        _fail _loc "Not all given commits were found: %1", join(', ', keys %shas);
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

1;
