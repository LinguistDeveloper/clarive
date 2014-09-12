package BaselinerX::GitServices;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

#with 'Baseliner::Role::Namespace::Create';
with 'Baseliner::Role::Service';

register 'action.git.repository_access' => {name => "Access git repository for pull/push"};
register 'action.git.repository_read' => {name => "Access git repository for pull"};
register 'action.git.update_tags' => {name => "Can update system tags in repositories"};

register 'config.git' => {
    metadata => [
        { id=>'gitcgi', label=>'Path to git-http-backend', default=>'/usr/local/libexec/git-core/git-http-backend' },
        { id=>'no_auth', label=>'Allow unauthenticated users to access the repository URL', default=>0 },
        { id=>'force_authorization', label=>'Check Auth Always', default=>1 },
        #{ id=>'gitcgi', label=>'Path to git-http-backend', default=>'/usr/local/Cellar/git/1.7.6/libexec/git-core/git-http-backend' },
        { id=>'home', label=>'Path to git repositories', default=>File::Spec->catdir($ENV{BASELINER_HOME},'etc','repo')  },
        { id=>'path', label=>'Path to git binary', default=>'/usr/bin/git'  },
        { id=>'show_changes_in_tree', label=>'Show tags in the Lifecycle tree', default=>'1' },
    ]
};

register 'service.git.newjob' => {
    name    =>_loc('Create a Git Revision Job'),
    handler =>  \&newjob,
};

register 'service.git.checkout' => {
    name    =>_loc('Checkout a Git Revision'),
    icon    => '/gitweb/images/icons/git.png',
    job_service => 1,
    handler =>  \&checkout,
};

register 'service.git.job_elements' => {
    name    =>_loc('Fill job_elements'),
    job_service => 1,
    handler =>  \&job_elements,
};

register 'service.git.link_revision_to_topic' => {
    name    =>_loc('Link a git revision to the changesets in title'),
    job_service => 1,
    handler =>  \&link_revision,
    form => '/forms/link_revision.js'
};

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
        _log _loc "Adding namespace %1 to job", $_;
        my $item = Baseliner->model('Namespaces')->get( $_ );
        _throw _loc 'Could not find revision "%1"', $_ unless ref $item;
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
        $log->info( _loc "*Git*: cloning project %1 repository %2 (%3) into `%4`", $prj, $repo_name, $path, $dir );
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
            my $bl_to = $lc->bl_to( $bl ) or _throw _loc "No bl_to defined for bl %1", $bl;
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

package BaselinerX::GitElement;
use Moose;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;

with 'BaselinerX::Job::Element';

has mask => qw(is rw isa Str default /application/subapp/nature);
has sha => qw(is rw isa Str);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p = @_;

    if( ! exists $p{path} && ! exists $p{name} ) {
        if(  $p{ fullpath } =~ /^(.*)\/(.*?)$/ ) {
            ( $p{path}, $p{name} ) = ( $1, $2 );
        } 
        else {
            ( $p{path}, $p{name} ) = ( '', $p{fullpath} );
        }
    }
    $self->$orig( %p );
};

1;
