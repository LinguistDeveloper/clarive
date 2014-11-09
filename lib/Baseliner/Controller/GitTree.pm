package Baseliner::Controller::GitTree;
use Moose;
use Baseliner::Utils;
use Try::Tiny;
use namespace::clean;

require Git::Wrapper;
require Girl;

BEGIN { extends 'Catalyst::Controller' }

sub branch : Local {
    my ( $self, $c ) = @_;
    my $node = $c->req->params;
    my $data = [
        # {
        #     url  => '/gittree/tasks_tree',
        #     data => {
        #         branch   => $node->{name},
        #         repo_dir => $node->{repo_dir},
        #     },
        #     text       => _loc('Issues'),
        #     icon       => '/static/images/icons/tasks.gif',
        #     leaf       => \0,
        #     expandable => \1
        # },
        {
            url  => '/gittree/branch_tree',
            data => {
                branch   => $node->{name},
                repo_dir => $node->{repo_dir},
            },
            text       => _loc('tree'),
            icon       => '/static/images/icons/lc/tree.gif',
            leaf       => \0,
            expandable => \1
        },
        {   url  => '/gittree/branch_changes',
            data => {
                branch   => $node->{name},
                repo_dir => $node->{repo_dir}
            },
            text       => _loc('changes'),
            icon       => '/static/images/icons/lc/changes.gif',
            leaf       => \0,
            expandable => \1
        },
        {   url  => '/gittree/branch_commits',
            text => _loc('revisions'),
            icon       => '/gitweb/images/icons/commite.png',
            data => {
                branch   => $node->{name},
                repo_dir => $node->{repo_dir},
                repo_mid => $node->{repo_mid},
            },
            leaf       => \0,
            expandable => \1
        },
    ];
    $c->stash->{json} = $data;
    $c->forward('View::JSON');
} ## end sub branch :

sub branch_commits : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $repo_mid = $p->{repo_mid};
    
    my $err;
    my @rev_list = try { 
        ci->new( $repo_mid )->commits_for_branch( branch=>$p->{branch} );
    } catch {
        $err = shift;
    };
    if( $err ) {
        $c->stash->{json} = { msg=>$err, success=>\0 };   
        $c->res->status( 500 );
        $c->forward('View::JSON');
        return;
    }
    ###########################################################
    my $used_commits;
    my @svnRevisions = ci->SvnRevision->search_cis();
    foreach(@svnRevisions){
        if($_->{repo}->{mid} eq $repo_mid){
            $used_commits->{$_->{sha}} = 1;
        }
    }
    @rev_list = grep { my ( $rev_sha, $rev_txt )= $_ =~ /^(.+?) (.*)/; !$used_commits->{$rev_sha};} @rev_list;
    ###########################################################
    my $data = [
        map {
            my ( $rev_sha, $rev_txt )= $_ =~ /^(.+?) (.*)/;
            my $sha6 = substr( $rev_sha, 0, 6 );
            #my $text = length( $rev_txt ) > 20?"[$sha6] ".substr( $rev_txt, 0, 20 ).'...':"[$sha6] $rev_txt";
            my $text = "[$sha6] $rev_txt";
            +{ 
                text =>  $text, 
                icon   => '/static/images/icons/commit.gif',
                data => {
                    click => {
                        # url      => '/gitpage/commit/' . $rev_sha,
                        url      => sprintf( '/gitweb.cgi?p=%s;a=commitdiff;h=%s', $p->{repo_dir}, $rev_sha ),
                        repo_dir => $p->{repo_dir},
                        repo_mid => $p->{repo_mid},
                        # type     => 'html',
                        type     => 'iframe',
                        title    => 'Commit ' . $sha6,
                    },
                    ci       => {
                        name     => $text, 
                        class    => 'GitRevision',
                        role     => 'Revision',
                        ns       => "git.revision/$rev_sha",
                        data     => {
                            ci_pre => [
                                {
                                    class    => 'GitRepository', 
                                    ns       => "git.repository/$p->{repo_dir}",
                                    name     => $p->{repo_dir},
                                    mid      => $p->{repo_mid},
                                    data=>{ repo_dir => $p->{repo_dir} },
                                }
                            ],
                            repo => 'ci_pre:0',
                            branch  => $p->{branch},
                            sha => $rev_sha,
                        }
                    },
                    sha      => $rev_sha,
                    repo_dir => $p->{repo_dir},
                },
                # menu => [
                #     {  
                #         text => 'Create Tag...',
                #         icon => '/static/images/icons/tag.gif',
                #         eval => { url => '/comp/git/tag_commit.js', title => 'Create Tag...' }
                #     },
                # ],
                leaf => \1,
             }
        } @rev_list
    ];
    $c->stash->{json} = $data;
    $c->forward('View::JSON');
} ## end sub branch_commits :

=head2 branch_changes

Changes in comparison to what?

=cut
sub branch_changes : Local {
    my ( $self, $c ) = @_;
    my $node = $c->req->params;
    my $git  = Git::Wrapper->new( $node->{repo_dir} );

    # git show --pretty="format:" --name-only

    my $data = [
        map {
            my $file = $_;
            +{ 
                text       => $file,
                icon       => '/static/images/icons/lc/status-m.gif',
                leaf => \1,
             }
        }
        grep { length }
        map { s/^\s+//g; $_ }
        _utf8_on_all
        $git->show( { pretty => 'format:', name_only => 1 }, $node->{branch} )
    ];
    if( @$data > 40 ) {
        my $len = scalar @$data;
        $data =  [ splice( @$data,0,40 ) ];
        push @$data, { text=>_loc('(and %1 more...)', $len - 40), leaf=>\1 };
    }
    $c->stash->{json} = $data;
    $c->forward('View::JSON');
} 

sub branch_tree : Local {
    my ( $self, $c ) = @_;
    my $node = $c->req->params;
    my $git  = Git::Wrapper->new( $node->{repo_dir} );
    my $folder = $node->{folder};
    $folder and $folder .= '/';
    my $data = [
        map {
            my ( $mod, $type, $sha, $f ) = $_ =~ /^(.+)\s(.+)\s(.+)\t(.*)$/;
            if( $type eq 'tree' ) {   # it's a directory
                my $d = _dir( $f );
                my $fname = Girl->unquote($d->basename);
                +{ 
                    text => "$fname",
                    url  => '/gittree/branch_tree',
                    data => {
                        branch   => $node->{branch},
                        repo_dir => $node->{repo_dir},
                        folder   => $f,
                        sha => $sha,
                    },
                    leaf => \0,
                 }
            } 
            else {  # it's a file
                $f = _file( $f );
                my $fname = Girl->unquote($f->basename);
                +{ 
                    text => "$fname",
                    leaf => \1,
                    data => {
                        click => {
                            #url      => '/gitpage/show_file/' . $sha,
                            #type     => 'html',
                            # url      => sprintf( '/gitweb.cgi?p=%s;a=blob;f=%s;h=%s;hb=%s', $node->{repo_dir}, $f, $node->{branch}, $sha ),
                            url      => sprintf( '/gitweb.cgi?p=%s;a=blob;f=%s;h=%s;hb=%s', $node->{repo_dir}, $f, $sha, $node->{branch} ),
                            type     => 'iframe',
                            title    => sprintf("%s:%s", $node->{branch}, $fname),
                        },
                        tab_icon => '/static/images/icons/leaf.gif',
                        file     => "$f",
                        repo_dir => $node->{repo_dir},
                    },
                 }
            }
        } $git->ls_tree( $node->{branch}, $folder )
    ];
    $data = [ sort { ${$a->{leaf}} <=> ${$b->{leaf}} } @$data ];
    $c->stash->{json} = $data;
    $c->forward('View::JSON');
} ## end sub branch_tree :

sub newjob : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $ns = $p->{ns} or _throw 'Missing parameter ns';
    my $bl = $p->{bl} or _throw 'Missing parameter bl';

    $c->stash->{json} = try {
        my @contents = map {
            _log _loc "Adding namespace %1 to job", $_;
            my $item = Baseliner->model('Namespaces')->get( $_ );
            _throw _loc 'Could not find revision "%1"', $_ unless ref $item;
            $item;
        } ($ns);

        _debug \@contents;

        my $job_type = $p->{job_type} || 'static';

        my $job = $c->model('Jobs')->create(
            bl       => $bl,
            type     => $job_type,
            username => $c->username || $p->{username} || `whoami`,
            runner   => $p->{runner} || 'service.job.chain.simple',
            comments => $p->{comments},
            items    => [ @contents ]
        );
        $job->update;
        { success=>\1, msg=> _loc( "Job %1 created ok", $job->name ) };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error creating job: %1", "$err" ) };
    };
    $c->forward('View::JSON');
}

1;
