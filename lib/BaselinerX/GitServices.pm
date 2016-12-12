package BaselinerX::GitServices;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::GitElement;
use Scalar::Util qw(blessed);
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture);
use Git;
use Try::Tiny;

#with 'Baseliner::Role::Namespace::Create';
with 'Baseliner::Role::Service';

register 'action.git.close_branch' => {name => _locl("User can close branches")};
register 'action.git.repository_access' => {name => _locl("Access git repository for pull/push")};
register 'action.git.repository_read' => {name => _locl("Access git repository for pull")};
register 'action.git.update_tags' => {name => _locl("Can update system tags in repositories")};

register 'config.git' => {
    metadata => [
        { id=>'gitcgi', label=>_locl('Path to git-http-backend'), default=>'/usr/local/libexec/git-core/git-http-backend' },
        { id=>'no_auth', label=>_locl('Allow unauthenticated users to access the repository URL'), default=>0 },
        { id=>'force_authorization', label=>_locl('Check Auth Always'), default=>1 },
        #{ id=>'gitcgi', label=>_locl('Path to git-http-backend'), default=>'/usr/local/Cellar/git/1.7.6/libexec/git-core/git-http-backend' },
        { id=>'home', label=>_locl('Path to git repositories'), default=>File::Spec->catdir($ENV{CLARIVE_HOME},'etc','repo')  },
        { id=>'path', label=>_locl('Path to git binary'), default=>'/usr/bin/git'  },
        { id=>'show_changes_in_tree', label=>_locl('Show tags in the Lifecycle tree'), default=>'1' },
        { id=>'hide_used_commits', label=>_locl('Hide commits already added to changeset'), default=>'1' },
        { id=>'max_diff_size', label=>_locl('Truncate diff if its length exceeds this number'), default=>500 * 1024 },
    ]
};

register 'service.git.newjob' => {
    name    =>_locl('Create a Git Revision Job'),
    icon    => '/static/images/icons/service-git-newjob.svg',
    handler =>  \&newjob,
};

register 'service.git.checkout' => {
    name    =>_locl('Checkout a Git Revision'),
    icon    => '/static/images/icons/service-git-checkout.svg',
    job_service => 1,
    handler =>  \&checkout,
};

register 'service.git.job_elements' => {
    name    =>_locl('Fill job_elements'),
    icon    => '/static/images/icons/service-git-job.svg',
    job_service => 1,
    handler =>  \&job_elements,
};

register 'service.git.link_revision_to_topic' => {
    name    =>_locl('Link a git revision to the changesets in title'),
    icon    => '/static/images/icons/service-git-link.svg',
    job_service => 1,
    handler =>  \&link_revision,
    form => '/forms/link_revision.js'
};

register 'service.git.create_tag' => {
    name    => _locl('Create a tag in a Git repository'),
    icon    => '/static/images/icons/service-git-tag.svg',
    form    => '/forms/git_create_tag.js',
    handler => \&create_tag,
};

register 'service.git.create_branch' => {
    name    => _locl('Create a branch in a Git repository'),
    icon    => '/static/images/icons/service-git-branch.svg',
    form    => '/forms/git_create_branch.js',
    handler => \&create_branch,
};

register 'service.git.delete_reference' => {
    name    => 'Delete a reference in a Git repository',
    icon    => '/static/images/icons/service-git-delete.svg',
    form    => '/forms/git_delete_reference.js',
    handler => \&delete_reference,
};

register 'service.git.merge' => {
    name    => 'Merge a branch in a Git repository',
    icon    => '/static/images/icons/service-git-merge.svg',
    form    => '/forms/git_merge_branch.js',
    handler => \&merge_branch,
};

register 'service.git.rebase' => {
    name    => 'Rebase a branch in a Git repository',
    icon    => '/static/images/icons/service-git-rebase.svg',
    form    => '/forms/git_rebase_branch.js',
    handler => \&rebase_branch,
};

sub create_tag {
    my ( $self, $c, $p ) = @_;

    my $repo_mids = $p->{repo} || _fail( _loc("Missing repo") );
    my $tag       = $p->{tag}  || _fail( _loc("Missing tag name") );
    my $sha       = $p->{sha}  || _fail( _loc("Missing sha") );
    my $force     = $p->{force};

    for my $repo_mid ( Util->_array_or_commas($repo_mids) ) {
        my $repo = $self->_load_repo($repo_mid);
        my $git  = $repo->git;

        _debug "Creating tag '$tag' in '$repo_mid'";

        $git->exec( 'tag', $force ? ('-f') : (), $tag, $sha );
    }

    return;
}

sub create_branch {
    my ( $self, $c, $p ) = @_;

    my $repo_mids = $p->{repo}   || _fail( _loc("Missing repo") );
    my $branch    = $p->{branch} || _fail( _loc("Missing branch name") );
    my $sha       = $p->{sha}    || _fail( _loc("Missing sha") );
    my $force     = $p->{force};

    my @revisions;
    for my $repo_mid ( Util->_array_or_commas($repo_mids) ) {
        my $repo = $self->_load_repo($repo_mid);
        my $git  = $repo->git;

        _debug "Creating branch '$branch' in '$repo_mid'";

        $git->exec( 'branch', $force ? ('-f') : (), $branch, $sha );
        my $sha = $git->exec( 'rev-parse', $branch );

        my $revision = BaselinerX::CI::GitRevision->new(
            name    => $branch,
            repo    => $repo_mid,
            sha     => $branch,
            moniker => $sha
        );
        $revision->save;
        push @revisions, $revision->mid;
    }

    return \@revisions;
}

sub delete_reference {
    my ( $self, $c, $p ) = @_;

    my $repo_mids = $p->{repo} || _fail( _loc("Missing repo") );
    my $type      = $p->{type} || _fail( _loc("Missing type") );
    my $sha       = $p->{sha}  || _fail( _loc("Missing sha") );

    for my $repo_mid ( Util->_array_or_commas($repo_mids) ) {
        my $repo = $self->_load_repo($repo_mid);

        my $git = Git->repository( Directory => $repo->repo_dir );

        my $resolved_type = $type;

        if ( $resolved_type eq 'any' ) {
            my @refs = $git->command( 'show-ref', $sha );
            if ( grep { m#refs/heads/# } @refs ) {
                $resolved_type = 'branch';
            }
            else {
                $resolved_type = 'tag';
            }
        }

        _debug "Deleting '$sha' from '$repo_mid'";

        if ( $resolved_type eq 'tag' ) {
            $git->command( 'tag', '-d', $sha );
        }
        elsif ( $resolved_type eq 'branch' ) {
            $git->command( 'branch', '-D', $sha );
        }
    }
}

sub merge_branch {
    my ( $self, $c, $p ) = @_;

    my $repo_mids    = $p->{repo}         || _fail( _loc("Missing repo") );
    my $topic_branch = $p->{topic_branch} || _fail( _loc("Missing topic_branch") );
    my $into_branch  = $p->{into_branch}  || _fail( _loc("Missing into_branch") );
    my $no_ff        = $p->{no_ff};
    my $message      = $p->{message};
    $message =~ s{"}{\\"}g if defined $message;

    for my $repo_mid ( Util->_array_or_commas($repo_mids) ) {
        my $repo = $self->_load_repo($repo_mid);

        my $tempdir = tempdir( CLEANUP => 1 );

        _debug "Merging '$topic_branch' into '$into_branch' of '$repo_mid'";

        capture {
            Git::command( 'clone', $repo->repo_dir, $tempdir );

            my $git = Git->repository( Directory => $tempdir );

            $git->command( 'checkout', $topic_branch );
            $git->command( 'checkout', $into_branch );

            my $output = '';
            try {
                my ( $fh, $c ) = $git->command_output_pipe(
                    'merge',
                    $no_ff ? ('--no-ff') : (),
                    $message ? ( '--no-log', '-m', $message ) : (),
                    '--no-edit', $topic_branch
                );
                while (<$fh>) {
                    $output .= $_;
                }

                $git->command_close_pipe( $fh, $c );
            }
            catch {
                my $error = shift;

                die "Merge failed: $error$output";
            };

            $git->command('push');
        };
    }
}

sub rebase_branch {
    my ( $self, $c, $p ) = @_;

    my $repo_mids = $p->{repo}     || _fail( _loc("Missing repo") );
    my $branch    = $p->{branch}   || _fail( _loc("Missing from") );
    my $upstream  = $p->{upstream} || _fail( _loc("Missing upstream") );

    for my $repo_mid ( Util->_array_or_commas($repo_mids) ) {
        my $repo = $self->_load_repo($repo_mid);

        my $tempdir = tempdir( CLEANUP => 1 );

        _debug "Rebasing '$branch' on top of '$upstream' of '$repo_mid'";

        capture {
            Git::command( 'clone', $repo->repo_dir, $tempdir );

            my $git = Git->repository( Directory => $tempdir );

            $git->command( 'checkout', $upstream );
            $git->command( 'checkout', $branch );

            my $output = '';
            try {
                my ( $fh, $c ) = $git->command_output_pipe( 'rebase', $upstream );
                while (<$fh>) {
                    $output .= $_;
                }

                $git->command_close_pipe( $fh, $c );
            }
            catch {
                my $error = shift;

                die "Rebase failed: $error$output";
            };

            $git->command( 'push', '-f' );
        };
    }
}

sub link_revision {
    my ($self, $c, $p) = @_;

    my $title = $p->{title} // _fail(_loc("Parameter title missing"));
    my $rev = $p->{rev} // _fail(_loc("Parameter rev missing"));
    my $field = $p->{field} // _fail(_loc("Parameter field missing"));
    my $username = $p->{username} // 'clarive';

    my @tokens = split(/\s/, $title );

    my @topics = map { $_ =~ /^\#(.*)/; $1 }grep { $_ =~ /^\#(.*)/ } @tokens;


    for (@topics) {
        my $topic = mdb->topic->find_one({ mid => "$_" });
        my @revs = _array($topic->{$field});
        push @revs, $rev;
        @revs = _unique(@revs);
        if ( $topic ) {
            Baseliner->model('Topic')->update(
                {
                    topic_mid => $_,
                    action => 'update',
                    username => $username,
                    $field => \@revs
                }
            );
            _log _log("Revision $rev linked to topic $_");
        } else {
            _log _log("Topic $_ does not exist");
        }
    }
}

sub newjob {
    my ($self, $c, $p ) = @_;
    my $bl = $p->{bl} or _throw 'Missing bl';
    #local *STDERR = *STDOUT;  # send stderr to stdout to avoid false error msg logs
    #_debug $p;
    # revision: TAG0001@prjname:reponame
    _throw _loc('Missing parameter revision') unless defined $p->{revision};
    #_throw _loc('Missing parameter project') unless defined $p->{project};
    #my $nsid = sprintf 'git.revision/%s@%s', $p->{revision}, $p->{project};

    # TODO check if rev has lineal history to bl (DEV)

    my @contents = map {
        _log _loc("Adding namespace %1 to job", $_);
        my $item = Baseliner->model('Namespaces')->get( $_ );
        _throw _loc('Could not find revision "%1"', $_) unless ref $item;
        $item;
    } _array $p->{revision};

    _debug \@contents;

    my $job_type = $p->{job_type} || 'static';

    my $job = $c->model('Jobs')->create(
        bl       => $bl,
        type     => $job_type,
        username => $p->{username} || `whoami`,
        runner   => $p->{runner} || 'service.job.chain.simple',
        comments => $p->{comments},
        items    => [ @contents ]
    );
    $job->update;

    # store parameters for later use
    #$p->{to_state} = Encode::encode_utf8( $p->{to_state} );

    #my $stash = _load $job->stash;
    #$stash->{harvest_data} = $p;
    #$job->stash( _dump $stash );
    #$job->update;

    $self->log->info( _loc("Created job %1 of type %2 ok.", $job->name, $job->type) );
}

sub checkout {
    my ($self, $c, $config ) = @_;
    my $job = $c->stash->{job};
    my $log = $job->logger;
    my $stash = $job->job_stash;
    my $bl = $job->bl;

    my %contents = map { $_->{item} => $_ } _array $stash->{contents}, $stash->{content_deps};

    for my $item ( values %contents ) {
        _log "REV: " . _dump $item;
        my $ns = ns_get $item->{item};
        next unless $ns->ns_type eq 'git.revision';

        # git object
        require Girl;
        my $repo = $ns->{ns_data}->{repo};
        my $git  = $repo->git;

        _log $_ for $git->exec(qw/tag/);

        my ( $rev, $prj, $repo_name ) = $ns->project;

        #Fix for SQA
        my $bl_def = $rev eq 'DESA'? 'master':$bl;
        my $rev_def = $rev eq 'DESA'? 'master':$rev;

        # cloning
        my $path = $repo->path;
        _log $job->root;
        _log "Project=$prj, Repo=$repo_name, RepoDir=$path, Rev=$rev";
        my $prjdir =  _dir $prj, $repo_name;
        my $dir = _dir $job->root, $prjdir;
        $log->info( _loc("*Git*: cloning project %1 repository %2 (%3) into `%4`", $prj, $repo_name, $path, $dir ) );
        _rmpath $dir if -e $dir;
        _mkpath $dir;
        #$git->run( qw/clone/, $repo->path, "$dir" );  # not working, ignores $dir
        system( qw(git clone), $repo->path, "$dir" );

        # checkout tag/branch
        my $repo_job = Girl::Repo->new( path=>"$dir" );

        # when static, merge theirs overrides us
        my $checkout_and_merge = 0;  # put it in a config key TODO
        if( $checkout_and_merge && $job->job_type eq 'static' ) {
            # checkout a bl, then merge-force the rev into it
            #  problem: the job element list comes out untrue
            my $lc = Baseliner->model('LCModel')->lc;
            my $bl_to = $lc->bl_to( $bl ) or _throw _loc("No bl_to defined for bl %1", $bl);
            $repo_job->git->exec( qw/checkout/, $bl );
            $repo_job->git->exec( qw/merge -s recursive -X theirs/, $rev );
        }
        else {
            $repo_job->git->exec( qw/checkout/, $rev );
        }
    }
}

sub job_elements {
    my ($self, $c, $config ) = @_;
    my $job = $c->stash->{job};
    my $log = $job->logger;
    my $stash = $job->job_stash;
    my $bl = $job->bl;
    for my $item ( _array $stash->{contents} ) {
        _log "REV: " . _dump $item;
        my $ns = ns_get $item->{item};
        next unless $ns->ns_type eq 'git.revision';

        # git object
        require Girl;
        my $repo = $ns->{ns_data}->{repo};
        my $git  = $repo->git;

        _log $_ for $git->exec(qw/tag/);

        my ( $rev, $prj, $repo_name ) = $ns->project;

        #Fix for SQA
        my $bl_def = $rev eq 'DESA'? 'master':$bl;
        my $rev_def = $rev eq 'DESA'? 'master':$rev;

        # cloning
        my $path = $repo->path;
        _log $job->root;
        _log "Project=$prj, Repo=$repo_name, RepoDir=$path, Rev=$rev";
        my $prjdir =  _dir $prj, $repo_name;
       # checkout tag/branch
        my $repo_job = Girl::Repo->new( path=>"$path" );

        # elements
        #$ENV{GIT_DIR} = "$dir";
        my @elems;

        #Load rev & bl sha
        my $rev_sha;
        my $bl_sha;

        if ( $job->stash->{$repo_name.$rev}->{git_rev_sha} && $job->stash->{$repo_name.$rev}->{git_bl_sha}  ) {
            $rev_sha = $job->stash->{$repo_name.$rev}->{git_rev_sha};
            $bl_sha = $job->stash->{$repo_name.$rev}->{git_bl_sha};
        } else {
            $rev_sha = $repo_job->git->exec( qw/rev-parse/, $rev_def );
            $bl_sha = $repo_job->git->exec( qw/rev-parse/, $bl_def );
            $job->stash->{$repo_name.$rev}->{git_rev_sha} = $rev_sha;
            $job->stash->{$repo_name.$rev}->{git_bl_sha} = $bl_sha;
        }

        # job elements
        if ( $job->job_type eq 'demote' || $job->rollback ) {
            @elems = $git->exec( qw/diff --name-status/, $bl_sha, $rev_sha."~1" );
        } else {
            if ( $rev_sha ne $bl_sha ) {
               $log->debug("BL and REV distinct");
               @elems = $git->exec( qw/diff --name-status/, $bl_sha, $rev_sha);
            } else {
                $log->debug("BL and REV equal");
                @elems = $git->exec( qw/ls-tree -r --name-status/, $bl_sha );
                @elems = map {
                    my $item = 'M   '.$_;
                } @elems;
            }
        }

        $log->debug("Elements in tree", data => join "\n", @elems);
        my $count = scalar @elems;
        $log->info( _loc( "*Git* Job Elements %1", $count ), data=>join"\n",@elems );
        @elems = map {
            my ($status, $path ) = /^(.*?)\s+(.*)$/;
            my $fullpath = _dir "/", $prjdir, $path;
            BaselinerX::GitElement->new( fullpath=> "$fullpath", status=>$status, version=>1 );
        } @elems;
        my $e = $job->job_stash->{elements} || BaselinerX::Job::Elements->new;
        $e->push_elements( @elems );
        $job->job_stash->{elements} = $e;
    }
}

sub _load_repo {
    my $self = shift;
    my ($mid) = @_;

    if ( ref $mid ) {
        if ( blessed($mid) ) {
            return $mid;
        }

        $mid = $mid->{mid};
    }

    return ci->new($mid);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
