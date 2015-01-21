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
            my $sha8 = substr( $rev_sha, 0, 8 );
            #my $text = length( $rev_txt ) > 20?"[$sha6] ".substr( $rev_txt, 0, 20 ).'...':"[$sha6] $rev_txt";
            my $text = "[$sha8] $rev_txt";
            +{ 
                text =>  $text, 
                icon   => '/static/images/icons/commit.gif',
                data => {
                    click => {
                        url      => '/comp/view_diff.js',
                        repo_dir => $p->{repo_dir},
                        repo_mid => $p->{repo_mid},
                        title    => 'Commit ' . $sha8,
                        type     => 'comp',
                        action   => 'edit',
                        load     => \1
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
                            rev_num => $rev_sha,
                            sha => $rev_sha,
                        }
                    },
                    sha      => $rev_sha,
                    repo_dir => $p->{repo_dir},
                    rev_num  => $rev_sha,
                    branch   => $p->{branch},
                    repo_mid => $p->{repo_mid},
                    controller => 'gittree'
                },
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
                #+{ 
                #    text => "$fname",
                #    leaf => \1,
                #    data => {
                #        click => {
                #            #url      => '/gitpage/show_file/' . $sha,
                #            #type     => 'html',
                #            # url      => sprintf( '/gitweb.cgi?p=%s;a=blob;f=%s;h=%s;hb=%s', $node->{repo_dir}, $f, $node->{branch}, $sha ),
                #            url      => sprintf( '/gitweb.cgi?p=%s;a=blob;f=%s;h=%s;hb=%s', $node->{repo_dir}, $f, $sha, $node->{branch} ),
                #            type     => 'iframe',
                #            title    => sprintf("%s:%s", $node->{branch}, $fname),
                #        },
                #        tab_icon => '/static/images/icons/leaf.gif',
                #        file     => "$f",
                #        repo_dir => $node->{repo_dir},
                #    },
                # }

                +{ 
                    text => "$fname",
                    leaf => \1,
                    data => {
                        click => {
                             url      => '/comp/view_file.js',
                             title    => sprintf("%s: %s", $node->{branch}, $fname),
                             type     => 'comp',
                             action   => 'edit',
                             load     => \1,
                        },
                        repo_mid => $node->{repo_mid},
                        branch   => $node->{branch},
                        tab_icon => '/static/images/icons/leaf.gif',
                        file     => "$f",
                        repo_dir => $node->{repo_dir},
                        rev_num  => $sha,  
                        controller => 'gittree',

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

sub is_binary_file : {
    my ($self, %params ) = @_;
    my $g = $params{gitApi};
    my $commit_file = $params{commit_file};
    my $filename = $params{filename};
    my @diff = _array $g->git->exec( 'diff-tree', '--minimal', '-p', $commit_file, '--', $filename);
    my $i = 0;
    my $isBinary = 0;
    foreach(@diff){
        if($_ =~ /Binary files/){
            $isBinary = 1;
            last;
        }
        $i++;
        last if $i>6;
    }
    return $isBinary;
}

sub view_file : Local {
    my ($self, $c ) = @_;
    my $node = $c->req->params;
    my $g = Girl::Repo->new( path=>$node->{repo_dir} );
    my $commit_file;
    my $type = $g->git->exec( 'cat-file', '-t', $node->{sha});
    if($type eq 'commit'){
        $commit_file = $node->{sha};
        my $rev_list = $g->git->exec( 'rev-list', '--objects', $node->{sha}.":$node->{filename}");
        $node->{sha} = $self->return_sha8($rev_list);
    }elsif($type eq 'tree'){
        my @commits;
        my $label = $node->{bl} ? $node->{bl} : $node->{branch};
        my @logs = $g->git->exec( 'log', $label, '--', $node->{filename});
        map { push @commits, $1 if $_=~ /^commit ([a-f0-9]{40})/} @logs;
        for my $commit (@commits){
            my @sha_version = _array $g->git->exec( 'rev-list', '--objects', $commit.':'.$node->{filename});
            if($sha_version[0] =~ /^$node->{sha}/){
                $commit_file = $commit;
                last;
            }
        }
    }else{
        my @commits;
        my $label = $node->{bl} ? $node->{bl} : $node->{branch};
        my @logs = $g->git->exec( 'log', $label, '--', $node->{filename});
        map { push @commits, $1 if $_=~ /^commit ([a-f0-9]{40})/} @logs;
        for my $commit (@commits){
            my $sha_version = $g->git->exec( 'rev-list', '--objects', $commit.':'.$node->{filename});
            if($sha_version =~ /^$node->{sha}/){
                $commit_file = $commit;
                last;
            }
        }
    }
    $c->stash->{json} = try {
        my $out;
        if($self->is_binary_file(gitApi=>$g, commit_file=>$commit_file, filename=>$node->{filename})){
            $out = 'It\'s a Binary file (view method not applicable)';
        }
        $out = join("\n", $g->git->exec( 'cat-file', '-p', $node->{sha})) if !$out;
        { success=>\1, msg=> _loc( "Success viewing file"), file_content=> _to_utf8 ($out), rev_num=>substr($commit_file,0,8) };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error viewing file: %1", "$err" ) };
    };
    $c->forward('View::JSON');
}


sub get_file_revisions : Local {
    my ($self, $c ) = @_;
    my $node = $c->req->params;
    my $label = $node->{bl} ? $node->{bl} : $node->{branch};
    my $g = Girl::Repo->new( path=>$node->{repo_dir} );
    my @logs;
    if($label){
        @logs = _array $g->git->exec( 'log', $label, '--', $node->{filename});
    }else{
        @logs = _array $g->git->exec( 'log', $node->{sha}, '--', $node->{filename});
    }
    my @commits;
    map { push @commits, $1 if $_=~ /^commit ([a-f0-9]{40})/} @logs;
    my @res = map { {name=>substr($_, 0,8)} } @commits;
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
    my $out; 
    my $rev_list = $g->git->exec( 'rev-list', '--objects', $node->{sha}.":$node->{filename}");
    # Know if the git object is a directory
    if(ref $rev_list eq 'ARRAY'){
        $out = "$node->{filename} is a directory, Blame method is not applicable...";
    }else{
        if($self->is_binary_file(gitApi=>$g, commit_file=>$node->{sha}, filename=>$node->{filename})){
            $out = 'It\'s a Binary file (blame method not applicable)';   
        }else{
            $out = join("\n", $g->git->exec( 'blame', $node->{sha}, '--', $node->{filename}));
            $out = _html_escape $out;
        }
    }
    $c->stash->{json} = try {
        { success=>\1, msg=> $out, suported=>\1 };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading file blame: %1", "$err" ) };
    };    
    $c->forward('View::JSON');
}


sub return_sha8 {
    my ($self, $rev_list) = @_;
    # If $rev_list is an array ref, then its a git directory
    if(ref $rev_list eq 'ARRAY'){
        my @revs = _array $rev_list;
        return substr($revs[0], 0, 8);
    }else{
        return substr($rev_list, 0, 8);
    }
}

sub view_diff_file : Local{
    my ($self, $c) = @_;
    my $node = $c->req->params;
    my $file = $node->{file};
    my $repo = $node->{repo_dir};
    my $actual_commit = $node->{sha};
    my $g = Girl::Repo->new( path=>$repo );
    my @commits;
    my @actual_log = $g->git->exec( 'log', $actual_commit, '--', $file);
    map { push @commits, $1 if $_=~ /^commit ([a-f0-9]{40})/} @actual_log;
    my $previous_commit = '-1';
    my $total_commits = scalar @commits;
    my $i = 0;
    map { $previous_commit = $commits[$i+1] if $_ =~ /^$actual_commit/ && $i < $total_commits-1; $i++; } @commits; 
    $previous_commit = $actual_commit if $previous_commit eq '-1';
    my $commit_info;
    my @lines = $g->git->exec( 'log','-1', $actual_commit);
    $lines[0] =~ /commit ([a-f0-9]+)/;
    $commit_info->{revision} = substr($1, 0,8);
    my $offset = 0;
    $offset = 1 if $lines[1] =~ /^Merge/;
    $lines[1+$offset] =~ /Author: (.+)/;
    $commit_info->{author} = _to_utf8 $1;
    $lines[2+$offset] =~ /Date: (.+)/;
    $commit_info->{date} = _to_utf8 $1;
    $commit_info->{comment} = _to_utf8 join("\n", @lines[4+$offset..$#lines]);
    my $diff;
    require Text::Diff;
    my $rev_list = $g->git->exec( 'rev-list', '--objects', $actual_commit.":$node->{file}");
    my $file_sha = $self->return_sha8($rev_list);
    my @code_chunks;
    my @changes;
    if($self->is_binary_file(gitApi=>$g, commit_file=>$actual_commit, filename=>$file)){
        push @code_chunks, { stats=>'-0,0 +0,0', code=>'It\'s a Binary file (diff method not applicable)' };
    }else{
        my @array_file_content = $g->git->exec( 'cat-file', '-p', $file_sha);
        $rev_list = $g->git->exec( 'rev-list', '--objects', $previous_commit.":$node->{file}");
        my $previous_file_sha = $self->return_sha8($rev_list);
        my $file_content = join("\n", @array_file_content );
        my @array_previous_file_content = $g->git->exec( 'cat-file', '-p', $previous_file_sha);
        my $previous_content = $previous_commit eq $actual_commit ? '' : join("\n", @array_previous_file_content);
        $diff = _to_utf8 Text::Diff::diff(\$previous_content, \$file_content, { STYLE => 'Unified' });
        my @parts;
        while ($diff ne ''){
            my @slides = split /(.*)(@@ .+ @@[ |\n].+)/s, $diff;
            push @parts, $slides[-1];
            $diff = $slides[1];
        }
        foreach(reverse @parts){
            $_ =~ /@@ (?<stats>.+) @@[ |\n](?<code>.*)/sg;
            my $stats = $+{stats};
            my $code = _to_utf8 $+{code};
            push @code_chunks, { stats=>$stats, code=>$code };
        }
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


sub get_file_history : Local{
    my ($self, $c) = @_;
    my $node = $c->req->params;
    my $history_limit = 200;
    my $file = $node->{file};
    my $repo = $node->{repo_dir};
    my $g = Girl::Repo->new( path=>$node->{repo_dir} );
    my @logs;
    my $i=0;
    foreach($g->git->exec( 'log', $node->{sha}, '--', $node->{filename})){
        push @logs, [$g->git->exec( 'log', '-1', $1)] if $_=~ /^commit ([a-f0-9]{40})/;
        $i++;
        last if $i>$history_limit;
    }
    my @res;
    for(@logs){
        my @log = _array $_;
        my $commit_info = {};
        $log[0] =~ /commit ([a-f0-9]+)/;
        $commit_info->{revision} = substr($1, 0,8);
        my $offset = 0;
        if($log[1] =~ /^Merge/){
            $offset = 1;
        }
        $log[1+$offset] =~ /Author: (.+)/;
        $commit_info->{author} = _to_utf8 $1;
        $log[2+$offset] =~ /Date: (.+)/;
        $commit_info->{date} = _to_utf8 $1;
        $commit_info->{comment} = _to_utf8 join("\n", @log[4+$offset..$#log]);
        push @res, [$commit_info->{author}, $commit_info->{date}, $commit_info->{revision}, $commit_info->{comment}];
    }
    $c->stash->{json} = try {
        { success=>\1, msg=> _loc( "Success loading file history"), history=>\@res, totalCount=>scalar @res };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading file history: %1", "$err" ) };
    };    
    $c->forward('View::JSON');
}


sub view_diff : Local {
    my ($self, $c ) = @_;
    my $node = $c->req->params;
    my $sha = $node->{sha};
    my $repo_dir = $node->{repo_dir};
    my $g = Girl::Repo->new( path=>$repo_dir );
    my @changes;
    $c->stash->{json} = try {
        my $commit_info;
        my @lines = $g->git->exec( 'log','-1', $sha);
        $lines[0] =~ /commit ([a-f0-9]+)/;
        $commit_info->{revision} = substr($1, 0,8);
        my $offset = 0;
        $offset = 1 if $lines[1] =~ /^Merge/;
        $lines[1+$offset] =~ /Author: (.+)/;
        $commit_info->{author} = _to_utf8 $1;
        $lines[2+$offset] =~ /Date: (.+)/;
        $commit_info->{date} = _to_utf8 $1;
        $commit_info->{comment} = _to_utf8 join("\n", @lines[4+$offset..$#lines]);
        my @array_show = $g->git->exec( 'show', $sha);
        my $show = join("\n", @array_show );
        my @parts;
        while ($show ne ''){
            my @slides = split /(.*)(diff --git .+)/s, $show;
            push @parts, $slides[-1];
            $show = $slides[1] // '';
        }
        pop @parts;
        my @changes;
        foreach(@parts){
            my $i = index($_, '@@');
            my $diff_info = substr($_, 0, $i);
            my ($path, $revision1, $revision2) = $diff_info =~ /diff --git a\/(.+) b\/.+index ([a-f0-9]{7})\.{2}([a-f0-9]{7})/s;
            my @code_chunks;
            if(!($diff_info =~ /Binary files/s)){
                my $diff_code = substr($_, $i);
                my @parts;
                while ($diff_code ne ''){
                    my @slides = split /(.*)(@@ .+ @@[ |\n].+)/s, $diff_code;
                    push @parts, $slides[-1];
                    $diff_code = $slides[1] // '';
                }
                foreach(reverse @parts){
                    $_ =~ /@@ (?<stats>.+) @@[ |\n](?<code>.*)/sg;
                    my $stats = $+{stats};
                    my $code = _to_utf8 $+{code};
                    push @code_chunks, { stats=>$stats, code=>$code };
                }
            }else{
                push @code_chunks, { stats=>'-0,0 +0,0', code=>'It\'s a Binary file (diff method not applicable)' };   
            }
            if($path){
                push @changes, { path=> $path, revision1=>$revision1, revision2=>$revision2, code_chunks=>\@code_chunks };
            }
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
    my $sort = $node->{sort} // '';
    my $dir = $node->{dir} // '';
    $c->stash->{json} = try {
        my @commits = $self->get_log_history({url=>$node->{repo_dir}, branch=>$node->{branch}, start=>$node->{start}, last=>$node->{start}+$node->{limit}, sort=>$sort, dir=>$dir  });
        my $g = Girl::Repo->new( path=>$node->{repo_dir} );
        my $totalCount = $g->git->exec( 'rev-list', $node->{branch}, '--count');
        { success=>\1, msg=> _loc( "Success loading commits history"), commits=>\@commits, totalCount=>$totalCount };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading commits history: %1", "$err" ) };
    };    
    $c->forward('View::JSON');
}

sub get_log_history {
    my ($self, $args) = @_;
    my $repo_dir = $args->{url};
    my $branch = $args->{branch};
    my $g = Girl::Repo->new( path=>$repo_dir );
    my @array_logs = $g->git->exec( 'log', $branch, '--skip='.$args->{start}, '-n', $args->{last} );
    my @commits;
    my $log = {};
    $log->{comment} = '';
    foreach(@array_logs){
        my $author;
        my $date;
        my $merge;
        my $commit;
        if( $_=~/^Author: (.+)/ ){
            $author = $1;
            $log->{author} = $author;
        }elsif( $_=~/^Date:\s*(.+)/){
            $date = $1;
            my $date_time = Time::Piece->strptime($date, "%c %z");
            my $date_str = $date_time->datetime;
            $log->{date} = $date_str;
            $log->{ago} = Util->ago($date_str);
        }elsif( $_=~/^Merge: (.+)/){
            $merge = $1;
        }elsif( $_=~/^commit (.+)/){
            if($log->{author}){
                push @commits, $log;
                $log = {};
                $log->{comment} = '';
            }
            $commit = $1;
            $log->{revision} = substr($commit,0,8);
        }else{
            $log->{comment} = $log->{comment}."\n".$_;
        }
    }
    push @commits, $log if $log->{author};
    @commits;
}


sub get_commits_search : Local {
    my ($self, $c ) = @_;
    my $node = $c->req->params;
    $c->stash->{json} = try {
        my @commits = $self->commit_search({repo_dir=>$node->{repo_dir}, branch=>$node->{branch}, query=>$node->{query} });
        { success=>\1, msg=> _loc( "Success loading commits history"), commits=>\@commits, totalCount=>scalar @commits };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error loading commits history: %1", "$err" ) };
    };    
    $c->forward('View::JSON');
}


sub commit_search {
    my ($self, $node ) = @_;
    my $repo_dir = $node->{repo_dir};
    my $g = Girl::Repo->new( path=>$repo_dir );
    my $query = $node->{query};
    my @array_logs;

    my @query_params;
    my @query_commit;
    push @query_params, "--since=\"$1\"" if $query =~ /--since="([^".]+)"/;
    push @query_params, "--until=\"$1\"" if $query =~ /--until="([^".]+)"/; # && $1 =~ /\d{4}-\d{2}-\d{2}/
    push @query_params, "--author=\"$1\"" if $query =~ /--author="([^".]+)"/;
    if($query =~ /--comment="([^".]+)"/){
        my $comment = $1;
        $comment =~ s/ /.*/g;
        push @query_params, "--grep=\"$comment\"";
    }
    push @query_commit, "\"$1\"", "-n", "1" if $query =~ /--commit="([^".]+)"/;
    push @array_logs, $g->git->exec( 'log', @query_params, '-i', { cmd_unquoted=>1 } ) if scalar @query_params;
    push @array_logs, $g->git->exec( 'log', @query_commit, { cmd_unquoted=>1 } ) if scalar @query_commit;

    my @commits;
    my $log = {};
    foreach(@array_logs){
        my $author;
        my $date;
        my $merge;
        my $commit;
        if( $_=~/^Author: (.+)/ ){
            $author = $1;
            $log->{author} = $author;
        }elsif( $_=~/^Date:\s*(.+)/){
            $date = $1;
            my $date_time = Time::Piece->strptime($date, "%c %z");
            my $date_str = $date_time->datetime;
            $log->{date} = $date_str;
            $log->{ago} = Util->ago($date_str);
        }elsif( $_=~/^Merge: (.+)/){
            $merge = $1;
        }elsif( $_=~/^commit (.+)/){
            if($log->{author}){
                push @commits, $log;
                $log = {};
                $log->{comment} = '';
            }
            $commit = $1;
            $log->{revision} = substr($commit,0,8);
        }else{
            $log->{comment} = '' if !$log->{comment};
            $_ = '' if !$_;
            $log->{comment} = $log->{comment}."\n".$_;
        }
    }
    push @commits, $log if $log->{author};
    @commits;
}
######################
1;
