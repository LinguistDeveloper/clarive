package BaselinerX::CI::GitRepository;
use Baseliner::Moose;
use Baseliner::Utils;
use Git::Wrapper;
use Try::Tiny;

require Girl;

with 'Baseliner::Role::CI::Repository';

has repo_dir        => qw(is rw isa Str);
has name            => qw(is rw isa Str);
has default_branch  => qw(is rw isa Str default HEAD);
has revision_mode   => qw(is rw isa Str default diff);

sub collection { 'GitRepository' }
sub icon       { '/static/images/icons/git-repo.gif' }

sub has_bl { 1 }

service 'create_tags' => {
    name    => _loc('Create tags'),
    form    => '/forms/repo_create_tags.js',
    icon    => '/gitweb/images/icons/git.png',
    handler => sub {
        my ($self,$c,$config) = @_;
        my $ref = $config->{'ref'};
        my $existing = $config->{'existing'} || 'detect';
        my $tag_filter = join '|', split ',', $config->{'tag_filter'};
        my $git = $self->git;
        if( !$ref ) {
            ($ref) = reverse $git->exec( 'rev-list', $self->default_branch // 'HEAD' );
        }
        my @out;
        for my $blci ( BaselinerX::CI::bl->search_cis ) {
            my $bl = $blci->bl;
            next if $tag_filter && $bl !~ /^($tag_filter)$/;
            next if $bl eq '*';
            if( $existing eq 'detect' ) {
                next if try { 
                    my ($bl_ref) = $git->exec( 'rev-parse', $bl ); 
                    _log "Tag $bl already exists ($bl_ref). Skipped";
                    1;
                } catch {
                    _log "Tag $bl not found. Replacing...";
                    0;
                };
            }
            _log "Creating tag $bl for ref $ref"; 
            push @out, $git->exec( 'tag', '-f', $bl, $ref );
        }
        join "\n", @out;
    },
};
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
        my @ordered_revs = $self->git->exec( 'rev-list', '--no-walk=sorted', keys %all_revs );
        @ordered_revs = reverse @ordered_revs if $type eq 'demote';
        _debug( \@ordered_revs );
        my %items_uniq;
        for my $rev ( map { $all_revs{$_} } @ordered_revs ) {
            my @rev_items = $rev->show( type=>$p{type} );
            $items_uniq{$_->path} = $_ for @rev_items;
        }
        # TODO --- in demote, blob is empty for deleted items status=D, which in demote are changed to status=A
        @items = values %items_uniq;
    } else {
        my $tag = $p{tag} // _fail(_loc 'Missing parameter tag needed for top revision');
        my $top_rev = $self->top_revision( revisions=>$revisions, type=>$p{type}, tag=>$tag );
        if( !$top_rev ) {
            _fail _loc 'Could not find top revision in repository %1 for tag %2. Attempting to redeploy to environment?', $self->name, $tag
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
    
    my @revisions = _array( $revisions );
    my $top_rev;
    
    my %shas = map { 
        # make sure every sha is there, for better error messaging
        my $sha = $_->{sha};
        my $long = try { $git->exec('rev-parse', $sha ) }
        catch { _fail _loc "Error: revision `%1` not found in repository %2", $sha, $self->name };
        $long => $_;
    } @revisions; 
    _debug "looking for top revision among shas: " . join ',', keys %shas;
    # get the tag sha
    my $tag_sha = $git->exec( 'rev-parse', $tag );
    # get an ordered list, with the tag in the middle
    my @sorted = $git->exec( 'rev-list', '--no-walk=sorted', keys %shas, $tag_sha );
    _fail _loc "None of the given revisions are in the repository: %1", join(', ', keys %shas)
         unless @sorted;
    # index
    my $k=1;
    my %by_sha = map { $_ => $k++ } @sorted;
    $k=1;
    my %by_pos = map { $k++ => $_ } @sorted;
    
    if( !exists $by_sha{ $tag_sha} ) {
        _fail _loc "Could not find tag %1 (sha %2) in repository", $tag, $tag_sha;
    }
    
    if( $type eq 'promote' ) {
        my $first_sha = $by_pos{1};
        _warn _loc "Tag %1 (sha %2) is already on top", $tag, $tag_sha if $first_sha eq $tag_sha;
        $top_rev = $shas{ $first_sha };
    }
    elsif( $type eq 'static' ) {
        my $first_sha = $by_pos{1};
        $top_rev = $shas{ $first_sha };
    }
    elsif( $type eq 'demote' ) {
        my $last_sha = $by_pos{ scalar @sorted };
        if( my $before_last = $git->exec( 'rev-parse', $last_sha . '~1' ) ) {
            _warn _loc "Tag %1 (sha %2) is already at the bottom", $tag, $tag_sha if $before_last eq $tag_sha;
            $top_rev = $shas{ $last_sha } // do {
                BaselinerX::CI::GitRevision->new( sha=>$before_last, name=>$tag, repo=>ci->new($self) );
            };
        } else {
            _warn _loc "Trying to demote all revisions in a repository, can't set tag %1 before %2", $tag, substr($last_sha,0,7);
            $top_rev = undef;
        }
    }
    
    if ( $top_rev &&  $check_history ) {
        my ($orig, $dest) = $type eq 'demote'
           ? ($top_rev->{sha}, $tag_sha)
           : ($tag_sha, $top_rev->{sha});


        _debug _loc("Looking for common history between %1 and %2", $orig, $dest);
        
        try {
            $git->exec( 'merge-base', '--is-ancestor', $orig, $dest);
        } catch {
            _fail _loc("Cannot %1 commit [%2] to %3 since they don't have common history and doing that may cause regressions.  You probably need to merge branches", _loc($type), substr($top_rev->{sha},0,6),$tag);
        };

        my $valid = 1;
        for my $rev ( @revisions ) {
            my $sha = $rev->{sha};

            try {
                $git->exec( 'merge-base', '--is-ancestor', $sha, $dest);
            } catch {
                _error _loc("Revision [%1] is not in the top revision's history", substr($sha,0,6));
                $valid = 0;
            };
        }
        if ( !$valid ) {
            _fail _loc("Not all commits are in [%1] history.  You probably need to merge branches", substr($dest,0,6) );
        }
    }
    return $top_rev;
}

sub checkout {
    my ( $self, %p ) = @_;
    
    my $dir  = $p{dir} // _fail 'Missing parameter dir'; 
    my $tag  = $p{tag} // _fail 'Missing parameter tag'; 
    #my $path = $self->path;
    my $git = $self->git;

    if( !-e $dir ) {
        _mkpath $dir;
        _fail _loc "Could not find or create directory %1: %2", $dir, $!
            unless -e $dir;
    }
    # get dir listing
    my @ls = $git->exec(qw/ls-tree -r -t -l --abbrev=7/, $tag );
    if( !@ls ) {
        return { ls=>[], output=>Util->_loc('No files for ref %1 in repository. Skipping', $tag) };
    }
    # save curr dir, chdir to repo, archive only works from within (?)
    my $cwd = Cwd::cwd;
    chdir $dir;  
    my $out = $git->exec( "archive '$tag' | tar x", { cmd_unquoted=>1 } );
    _log _loc "*Git*: checkout of repository %1 (%2) into `%3`", $self->repo_dir, $tag, $dir;
    chdir $cwd;
    { ls=>\@ls, output=>$out }
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

method update_baselines( :$revisions, :$tag, :$type, :$ref=undef ) {
    my $git = $self->git;

    my $top_rev = $ref // $self->top_revision( revisions=>$revisions, type=>$type, tag=>$tag , check_history => 0 );
    
    if( $type eq 'static' ) {
        _log( _loc "*Git* repository baselines not updated. Static job." );
        return;
    }

    $top_rev = $top_rev->{sha} if ref $top_rev;
    
    my $tag_sha = $git->exec( 'rev-parse', $tag );
    
    my $out='';
    if( $type eq 'promote' ) {
        _debug( _loc "Promote baseline $tag to $top_rev: tag -f $tag $top_rev" );
        $out = $git->exec( qw/tag -f/, $tag, $top_rev );
        _log _loc( "Promoted baseline %1 to %2", $tag, $top_rev);
    }
    elsif( $type eq 'demote' ) {
        $top_rev = $top_rev . '~1';  # one less 
        _debug( _loc "Demote baseline $tag to $top_rev: tag -f $tag $top_rev" );
        $out = $git->exec( qw/tag -f/, $tag, $top_rev );
        _log _loc( "Demoted baseline %1 to %2", $tag, $top_rev), data=>$out;
    }
    elsif( $type eq 'static' ) {
        _debug( _loc "Updating baseline $tag to $top_rev: tag -f $tag $top_rev" );
        $out = $git->exec( qw/tag -f/, $tag, $top_rev );
        _log _loc( "Updated baseline %1 to %2", $tag, $top_rev);
    }
    
    my $previous = BaselinerX::CI::GitRevision->new( sha => $tag_sha, name => $tag );
    return {
        current  => $top_rev,
        previous => $previous,  
        output   => $out
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

    _debug $self;

    my @changes;

    my $repo = Girl::Repo->new( path => $repo_dir );    # TODO combine repos

    my @heads = $repo->heads;    # git local branches
                                 #$p{bl} and @heads = grep { $_->name =~ /^$p{bl}/ } @heads;
    push @changes, map {

        BaselinerX::GitBranch->new(
            {
                head      => $_,
                repo_dir  => $repo_dir,
                name      => $_->name,
                repo_name => $repo_name,
                project   => $project,
                repo_mid  => $self->mid,
            }
        );
    } @heads;

    return @changes;
} ## end sub list_branches

method commits_for_branch( :$tag=undef, :$branch ) {
    my $git = $self->git;
    $tag //= [ grep { $_ ne '*' } map { $_->bl } sort { $a->seq <=> $b->seq } BaselinerX::CI::bl->search_cis ]->[0];
    # check if tag exists
    my $bl_exists = $git->exec( 'rev-parse', $tag, { on_error_empty=>1 });
    Util->_fail( Util->_loc('Error: could not find tag %1 in repository. Repository tags are configured?', $tag) ) unless $bl_exists;
    my @rev_list = $git->exec( 'rev-list', '--pretty=oneline', '--right-only','--max-count=30', $tag."...".$branch );
    # rgo - we need merges too - my @rev_list = $git->exec( 'rev-list', '--no-merges', '--pretty=oneline', '--right-only','--max-count=30', $tag."...".$branch );
    # @rev_list = $git->exec( 'rev-list', '--no-merges', '--pretty=oneline', '--right-only','--max-count=30', $branch );
    return @rev_list;
}

1;
