package Baseliner::Controller::GitTree;
use Moose;
use Baseliner::Utils;
use Try::Tiny;
use namespace::clean;
use Baseliner::Sugar;

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
    my $hide_used = config_get('config.git')->{hide_used_commits};
    if (  $hide_used ) {    
        ###########################################################;
        my $no_ci_commits;
        my $all_commits;
        my @gitRevisions = mdb->master_doc->find({ collection=>'GitRevision', repo=>$repo_mid})->fields({sha=>1, mid=>1, _id=>0})->all;
        map { $no_ci_commits->{$_->{sha}} = 1 } @gitRevisions;
        map { $all_commits->{$_->{sha}} = $_->{mid} } @gitRevisions;
        ###########################################################
        my $used_commits;
        my @inCsRevisions = mdb->master_rel->find({ to_mid => mdb->in( map {$_->{mid}} @gitRevisions), rel_type => 'topic_revision'})->fields({to_mid=>1, _id=>0})->all;
        map { $used_commits->{$_->{to_mid}} = 1 } @inCsRevisions;
        ###########################################################
        
        @rev_list = 
        grep { 
            my ( $rev_sha, $rev_txt )= $_ =~ /^(.+?) (.*)/; 
            my $not_exists = !$no_ci_commits->{$rev_sha}; 
            my $not_used = $all_commits->{$rev_sha} && !$used_commits->{ $all_commits->{$rev_sha} };
            $not_exists || $not_used;
        } @rev_list;
        ###########################################################
    }
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


#########################################################################
#########################################################################
####### FINISH ########
sub view_file : Local {
    my ($self, $c ) = @_;
    my $node = $c->req->params;
    my $g = Girl::Repo->new( path=>$node->{repo_dir} );
    $c->stash->{json} = try {
        my $out = join("\n", _array $g->git->exec( 'cat-file', '-p', $node->{sha}));
        { success=>\1, msg=> _loc( "Success viewing file<->"), file_content=> _to_utf8 ($out), rev_num=>$node->{sha} };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error viewing file: %1", "$err" ) };
    };
    $c->forward('View::JSON');
}


sub get_file_revisions : Local {
    my ($self, $c ) = @_;
    my $node = $c->req->params;
    my $g = Girl::Repo->new( path=>$node->{repo_dir} );
    my @commits;
    map { push @commits, $1 if $_=~ /^commit ([a-f0-9]{40})/} $g->git->exec( 'log', $node->{bl}, '--', $node->{filename});
    my @res = map { my $sha_version = $g->git->exec( 'rev-list', '--objects', $_.':'.$node->{filename}); {name=>substr($sha_version, 0,8)} } @commits;
    $c->stash->{json} = try {
        \@res;
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error viewing file revisions: %1", "$err" ) };
    };
    $c->forward('View::JSON');    
}

sub get_file_blame : Local{
    my ($self, $c) = @_;
    my $node = $c->req->params;
    my $g = Girl::Repo->new( path=>$node->{repo_dir} );
    my @commits;
    map { push @commits, $1 if $_=~ /^commit ([a-f0-9]{40})/} $g->git->exec( 'log', $node->{bl}, '--', $node->{filename});
    my $find_commit = {};
    map { my $sha_version = $g->git->exec( 'rev-list', '--objects', $_.':'.$node->{filename}); $find_commit->{substr($sha_version, 0,8)} = $_; } @commits;
    $c->stash->{json} = try {
        my $out = join("\n", _array $g->git->exec( 'blame', $find_commit->{$node->{sha}}, '--', $node->{filename}));
        { success=>\1, msg=> $out, suported=>\1 };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading file blame: %1", "$err" ) };
    };    
    $c->forward('View::JSON');
}

sub view_diff_file : Local{
    my ($self, $c) = @_;
    my $node = $c->req->params;
    my $file = $node->{file};
    my $repo = $node->{repo_dir};
    my $file_sha = $node->{sha};
    my $bl = $node->{bl};
    my $g = Girl::Repo->new( path=>$repo );
    my @commits;
    map { push @commits, $1 if $_=~ /^commit ([a-f0-9]{40})/} $g->git->exec( 'log', $bl, '--', $file);
    my $find_commit = {};
    map { my $sha_version = $g->git->exec( 'rev-list', '--objects', $_.':'.$file); $find_commit->{substr($sha_version, 0,8)} = $_; } @commits;
    my $actual_commit = $find_commit->{$file_sha};
    my $previous_commit = '-1';
    my $total_commits = scalar @commits;
    my $i = 0;
    map { $previous_commit = $commits[$i+1] if $actual_commit eq $_ && $i < $total_commits-1; $i++; } @commits; 
    $previous_commit = $actual_commit if $previous_commit eq '-1';
    my $commit_info;
    my @lines = $g->git->exec( 'log','-1', $actual_commit);
    $lines[0] =~ /commit ([a-f0-9]+)/;
    $commit_info->{revision} = substr($1, 0,8);
    my $offset = 0;
    if($lines[1] =~ /^Merge/){
        $offset = 1;
    }
    $lines[1+$offset] =~ /Author: (.+)/;
    $commit_info->{author} = $1;
    $lines[2+$offset] =~ /Date: (.+)/;
    $commit_info->{date} = $1;
    $commit_info->{comment} = join("\n", @lines[4+$offset..$#lines]);
    my @diff_lines = _array $g->git->exec( 'diff', $previous_commit.'..'.$actual_commit, '--', $file);
    my $diff = join("\n", @diff_lines[4..$#diff_lines]);
    my @changes;
    my @parts;
    map { push @parts, $_ if $_ } split /(.*)(@@ .+ @@[ |\n].+)/s, $diff;
    my @code_chunks;
    foreach(@parts){
        $_ =~ /@@ (?<stats>.+) @@[ |\n](?<code>.*)/sg;
        my $stats = $+{stats};
        my $code = _to_utf8 $+{code};
        push @code_chunks, { stats=>$stats, code=>$code };
    }
    push @changes, { path=> $file, revision1=>substr($previous_commit, 0,8), revision2=>substr($actual_commit, 0,8), code_chunks=>\@code_chunks };
    $c->stash->{json} = try {
        { success=>\1, msg=> _loc( "Success loading file diff"), changes=> \@changes, commit_info=>$commit_info };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading file diff: %1", "$err" ) };
    };    
    $c->forward('View::JSON');
}

######################




sub view_diff : Local {
    my ($self, $c ) = @_;
    my $node = $c->req->params;
    my $branch = $node->{branch};
    my $changeset_node = $node->{rev_num};
    my $path = $node->{repo_dir};
    my @parts = split '@', $path;
    my @changes;
    my $cmd;
    $c->stash->{json} = try {
        require Text::Diff;
        my $commit_info;
        $cmd = "cm find \"changesets where ChangesetId=$changeset_node on repository '$path'\" --nototal --format={changesetid}#-#{date}#-#{comment}#-#{owner}#-#{Parent}";
        my @info_changeset = split '#-#', `$cmd`;
        $commit_info->{author}   = _to_utf8 $info_changeset[3];
        $commit_info->{date}     = $info_changeset[1];
        $commit_info->{revision} = $info_changeset[0];
        $commit_info->{comment}  = _to_utf8 $info_changeset[2];
        my $parent_changeset = $info_changeset[4];
        $parent_changeset =~ s/\n//;
        $cmd = "cm ls --tree=$changeset_node\@$path -r --format={fullpath}#-#{revid}#-#{changeset}#-#{itemid}#-#{type}";
        my @all_files_actual = `$cmd`;
        $cmd = "cm ls --tree=$parent_changeset\@$path -r --format={fullpath}#-#{revid}#-#{changeset}#-#{itemid}#-#{type}";
        my @all_files_parent = `$cmd`;
        my $old_files;
        foreach(@all_files_parent) {
            my @info = split '#-#', $_;
            my $type = $info[4];
            $type =~ s/\n//;
            next if $type eq 'dir';
            my $itemid = $info[3];
            $itemid=~ s/\n//;
            $old_files->{$itemid}=$info[1]; 
        }
        foreach(@all_files_actual){
            my ($fullpath, $revid, $changeset, $itemid, $type) = split '#-#', $_;
            $type =~ s/\n//;
            next if $type eq 'dir';
            $cmd = "cm cat revid:$revid\@"."rep:$parts[0]\@"."repserver:$parts[1]";
            my $actual_content = `$cmd`;
            my $old_content;
            if($old_files->{$itemid}){
                $cmd =  "cm cat revid:$old_files->{$itemid}\@"."rep:$parts[0]\@"."repserver:$parts[1]";
                $old_content = `$cmd`;
            }else{
                $old_content = '';   
            }
            my $diff = _to_utf8 Text::Diff::diff(\$old_content, \$actual_content, { STYLE => 'Unified' });
            next if $diff eq '';
            my @parts;
            map { push @parts, $_ if $_ } split /(.*)(@@ .+ @@\n.+)/s, $diff;
            my @code_chunks;
            foreach(@parts){
                $_ =~ /@@ (?<stats>.+) @@\n(?<code>.*)/sg;
                my $stats = $+{stats};
                my $code = _to_utf8 $+{code};
                push @code_chunks, { stats=>$stats, code=>$code };
            }
            push @changes, { path=> $fullpath, revision1=>$parent_changeset, revision2=>$changeset_node, code_chunks=>\@code_chunks, revid=>$revid };
        }
        @changes = reverse(@changes);
        { success=>\1, msg=> _loc( "Success loading diffs"), changes=> \@changes, commit_info=>$commit_info };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading diffs: %1", "$err" ) };
    };
    $c->forward('View::JSON');
}


sub get_commits_history : Local {
    my ($self, $c ) = @_;
    my $node = $c->req->params;
    $c->stash->{json} = try {
        my @commits = $self->get_log_history({url=>"$node->{repo_dir}$node->{branch}"});
        { success=>\1, msg=> _loc( "Success loading commits history"), commits=>\@commits, totalCount=>scalar @commits };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading commits history: %1", "$err" ) };
    };    
    $c->forward('View::JSON');
}


sub get_log_history {
    my ($self, $args) = @_;
    my $url = $args->{url};
    my @parts = split '/', $url;
    my $branch = join '/',@parts[1..scalar @parts-1];
    my $cmd = "cm find \"changesets where branch='/$branch' on repository '$parts[0]'\" --nototal --format={owner}#-#{date}#-#{changesetid}#-#{comment}";
    my $out = `$cmd`;
    my @lines = split '\n', $out;
    my @commits;
    foreach(@lines){
        my @parts = split '#-#', $_;
        my $date = $parts[1];
        $date = Util->parse_date('MM/dd/yyyy',$date);
        $date =~ s/T/ /;
        my $ago = Util->ago($date);
        my $comment = _to_utf8  $parts[3];
        push @commits, {author=>$parts[0],ago=>$ago,revision=>$parts[2],comment=>$comment};
    }
    reverse @commits;
}



sub get_file_history : Local{
    my ($self, $c) = @_;
    my $node = $c->req->params;
    my $repo = $node->{filepath};
    my $file = $node->{filename};
    my $rev_num = $node->{rev_num};
    my $revid = $node->{revid};
    my @res;
    $c->stash->{json} = try {
        my $cmd = "cm find \"revision where id=$revid on repository '$repo'\" --nototal --format={itemid}";
        my $itemid = `$cmd`;
        $itemid =~ s/\n//g;
        $cmd = "cm find \"revisions where itemid=$itemid on repository '$repo'\" --nototal --format={owner}#-#{date}#-#{changeset}#-#{comment}";
        my @history = `$cmd`;
        foreach(reverse @history){
            my ($author, $date, $revision) = split '#-#', $_;
            $cmd = "cm find \"changeset where changesetid=$revision on repository '$repo'\" --nototal --format={comment}";
            my $comment = `$cmd`;
            $comment =~ s/\n/ /g;
            push @res, [$author, $date, $revision, _to_utf8 $comment];
        }
        { success=>\1, msg=> _loc( "Success loading file history"), history=>\@res, totalCount=>scalar @res };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading file history: %1", "$err" ) };
    };    
    $c->forward('View::JSON');
}

#########################################################################
#########################################################################
1;
