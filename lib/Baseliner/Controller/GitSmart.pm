package Baseliner::Controller::GitSmart;
=head1 NAME

Baseliner::Controller::GitSmart - interface to Git Smart HTTP

=head1 DESCRIPTION

This controller manages all interagtions with git-http-backend

=cut
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Path::Class;

BEGIN { extends 'Catalyst::Controller::WrapCGI' }

sub begin : Private {  #TODO control auth here
     my ($self,$c) = @_;
     my $config = config_get 'config.git';
     _debug _dump $c->req->headers;
     $c->stash->{git_config} = $config;
     if( $config->{no_auth} ) {
         $c->stash->{auth_skip} = 1;
     } elsif( ! length $c->username ) {
         $c->stash->{auth_basic} = 1;
     } 
     _debug "GIT USER=" . $c->username;
}

sub git : Path('/git/') {
    my ($self,$c, @args ) = @_;
    my $p = $c->request->parameters;
    my $config = $c->stash->{git_config};
    my $cgi = $config->{gitcgi} or _throw 'Missing config.git.gitcgi';
    _throw _loc("File %1 does not exist", $cgi) unless -e $cgi;
    my $home = $config->{home} or _throw 'Missing config.git.repo';

    # extract reponame from url
    my $flag = 2;
    my @repo = grep {  
        $flag = 0 if $flag == 1;
        $flag-- if /\.git$/; # stop when name.git found in path  
        $flag;
    } @args;
    my $repo = "". _dir( @repo );

    # normalize paths
    my $fullpath = _file( $home, $repo ); # simulate it's a file
    $repo = $fullpath->basename;  # should be something.git
    my $project = $args[0];
    my $reponame = $args[1];
    my $repopath = join('/', @args );
    _debug ">>> GIT ARGS (repopath): " . $repopath;
    _debug ">>> GIT HOME: $home";
    _debug ">>> GIT CI PROJECT: $project";
    _debug ">>> GIT CI REPONAME: $reponame";
    _debug ">>> GIT URI: " . $c->req->uri;
    _debug ">>> PATH_INFO: " . $c->req->path;
    _debug ">>> GIT REPO: $repo";
    
    my ($ci_repo,$ci_prj);
    my ($uri_path, $filepath_info, $path_info);  # CGI ENV variables used by CI mode

    if( !$config->{force_authorization} && $repo =~ /\.git$/ ) {   # old style /git/repo.git, by default is off
        $home = $fullpath->dir->absolute;
        _log ">>> GIT USER: " . $c->username;
        _log ">>> GIT HOME REPO: $home"; 
    } elsif( length $project && length $reponame ) {
        ($ci_prj)  = ci->search_cis( '$or'=>[ {name=>$project}, {moniker=>$project} ], collection=>'project' );
        ($ci_repo) = ci->search_cis( '$or'=>[ {name=>$reponame}, {moniker=>$reponame}, {moniker=>lc($project)."_".$reponame} ], collection=>'GitRepository' );
        my $repo_dir = _dir( $ci_repo->repo_dir );
        $home = $repo_dir->parent;
        # build the CGI path needed
        if( $c->req->uri =~ m{^.*/git/$project/$reponame/(.*)$} ) {
            my $short_uri = $1;
            my $rest_uri = join('/', splice(@args,2) );
            $uri_path      = sprintf '/git/%s/%s', $repo_dir->basename, $short_uri;
            $filepath_info = sprintf '/gitsmart/git/%s/%s', $repo_dir->basename, $rest_uri; #  FILEPATH_INFO: /gitsmart/git/VT-FILES.git/info/refs
            $path_info = sprintf '/%s/%s', $repo_dir->basename, $rest_uri; # PATH_INFO: /VT-FILES.git/info/refs
        } else {
            $self->git_error( $c, 'internal error', _loc 'Could not parse git uri: %1', $c->req->uri );
            $c->response->status( 404 );
            return;
        }
        
        if( !defined $ci_prj ) {
            $self->git_error( $c, 'internal error', _loc("Invalid project name %1", $project) );
            $c->response->status( 404 );
            return;
        }
        if( !defined $ci_repo ) {
            $self->git_error( $c, 'internal error', _loc("Invalid repository name %1", $reponame) );
            $c->response->status( 404 );
            return;
        }
        _log _loc "Git: User %1 access to project %2 (mid=%3) repository %4 (mid=%5)", $c->username, $project, $ci_prj->mid,
            $reponame, $ci_repo->mid;
    } else {
        $self->git_error( $c, 'invalid repository', _loc("Invalid or unauthorized git repository path %1", $repopath ) );
        $c->response->status( 401 );
        return;
    }
    
    # Check permissions
    if( ! length $c->username ) {
        if( ! exists $c->req->params->{service} ) {  # first request has param 'service'
            $self->git_error( $c, 'access denied', 
                    _loc("Authentication failed for user '%1': %2", $c->stash->{login}, $c->stash->{auth_message} ) 
                );
            return;
        } elsif( $c->req->user_agent =~ /JGit/i ) {
            _debug "Unauthorized JGit";
            # This response forces JGIt to say "not authorized"
            $c->response->headers->push_header( 'WWW-Authenticate' => 'Basic realm="clarive"' );
            $c->response->body( _loc('Invalid User') );
            $c->response->status( 401 );
            return;
        } else {
            $self->git_error( $c, 'access denied', 
                    _loc("Authentication failed for user '%1': %2", $c->stash->{login}, $c->stash->{auth_message} ) 
                );
            $c->response->status( 401 );
            return;
        }
    } elsif( $ci_prj ) {
        if( !$ci_prj->user_has_action(username=>$c->username,action=>'action.git.repository_access') ) {
            $self->git_error( $c, _loc('User: %1 does not have access to the project %2', $c->username, $project ) );
            return;
        } 
    }

    # TODO - check if the user has "action.git.repo_new" :
    # $c->model('Git')->setup_new_repo( service=>$p->{service}, repo=>$repo, home=>$home );

    # parse request body, if any, to find the commit sha and branch (ref)
    my $sha;
    my $ref;
    my $ref_prev;
    if( ref ( my $fi = $c->req->body ) ) {
        my $msg = _file( $fi->filename )->slurp;  # TODO go line by line
        #open my $fin, '>/tmp/req'; 
        #binmode $fin;
        #print $fin $msg; 
        #_debug $c->req->body;
        #close $fin;
        my ($msg1) = $msg =~ /^(.*)\0/;
        if( $msg1 ) {
            my ($top,$com,$r) = split / /, $msg1;
            if( defined $com && $com =~ /^\w+$/ ) {
                _debug "GIT TOP=$top";
                _debug "GIT COMMIT SHA=$com";
                _debug "GIT REF=$r";
                $sha = $com;
                $ref = $r;
                $ref_prev = substr $top, 4;
                _debug "GIT REF_PREV=$ref_prev";
            }
        }
    }

    # run cgi
    my ($cgi_msg,$cgi_ret) = ('',0);
    $self->cgi_to_response($c, sub {
        #_debug \%ENV;
        #_debug $p;
        my $prjr = _file $home;
        $prjr = $prjr->dir . "";
        $ENV{GIT_HTTP_EXPORT_ALL} = 1;
        $ENV{GIT_PROJECT_ROOT} = "$home";
        $ENV{REMOTE_USER} ||= 'baseliner';
        $ENV{REMOTE_ADDR} ||= 'localhost';
        $ENV{REQUEST_URI} = $uri_path if length $uri_path; 
        $ENV{FILEPATH_INFO} = $filepath_info if length $filepath_info; 
        $ENV{PATH_INFO} = $path_info if length $path_info; 
        
        $cgi_ret = system $cgi;
        $cgi_msg = $self->res_msg();
        if ($? == -1) {
            die "failed to execute CGI '$cgi': $!";
        }
        elsif ($? & 127) {
            die sprintf "CGI '$cgi' died with signal %d, %s coredump",
                ($? & 127),  ($? & 128) ? 'with' : 'without';
        }
        else {
            my $exit_code = $? >> 8;
            return 0 if $exit_code == 0;
            die "CGI '$cgi' exited non-zero with: $exit_code";
        }
    }); 

    _debug "GIT RET: " . $cgi_ret;
    _debug "GIT CGI: " . $cgi_msg;
    #contains nasty chars: _debug "GIT OUT: " . $c->res->body;

    # now gather commit info and event it
    try {
        if( $sha ) {  
            my $g = Girl::Repo->new( path=>"$fullpath" );
            my $repo_doc = ci->GitRepository->find_one({ repo_dir=>qr/$fullpath/ });
            my $repo_id;
            if ($repo_doc) {
                $repo_id = $repo_doc->{mid};
            } else {
                master_new 'GitRepository' => {
                    name    => "$fullpath",
                    moniker => "$fullpath",
                    data    => {
                        repo_dir   => "$fullpath",
                        rel_path   => "/",
                    }
                    } => sub {
                        $repo_id = shift;
                    };
            }

            if ( $repo_id ) {

                my $commit = $g->commit( $sha );
                my $diff = $ref_prev eq 0 # ref_prev == 0 when it's a new repository
                    ? _format_diff(  join "\n", $g->exec( 'show', $sha ) )
                    : _format_diff( join "\n", $g->exec( 'log', '-p', '--full-diff', "$ref_prev..$sha" ) );
                _debug $diff;
                my $ref_short = [ split '/', $ref ]->[-1];
                _debug "GIT MESSAGE: " . $commit->message;
                my $title = $commit->message;
                event_new 'event.repository.update'
                    => { username=>$c->username, repository=>$repo, message=>$title, commit=>$commit, diff=>$diff, branch=>$ref_short, ref=>$ref, sha=>$sha }
                    => sub { 
                        my $mid;
                        my $master = ci->GitRevision->search_ci( sha=>$sha );
                        if( ! $master ) {
                            my $commit2 = substr( $sha, 0, 7 );
                            my $msg = substr( $commit->message, 0, 15 );
                            master_new 'GitRevision' => {
                                    name    => "[$commit2] $title",
                                    moniker => $commit2,
                                    data    => { sha => $sha, repo => $repo_id, branch => $ref_short }
                                } => sub {
                                    $mid = shift;
                                };

                        } else {
                            $mid = $master->mid;
                        }
                        { mid => $mid, title => $title };
                };
                _debug "GIT: evented SHA $sha";
            } else {
                _debug "GIT: repository not found";
            }
        } else {
            _debug "GIT: no sha defined to event operation";
        }
    } catch {
        _log "GIT: ERROR: Could not event git operation: " . shift();
    };

}

sub _format_diff {
    my ($diff, %p ) = @_;
    #my ($header, $rest ) = split /
    _html_escape( $diff );
}

sub res_msg {
    my $self = shift;
    my $msg = join("\n", @_) || "(no message)";
    $msg = $msg . "\n";
    my $s;
    # 0005 + length
    $s .= sprintf "%04x\x2", 5 + length( $msg );
    $s .= $msg;
    $s .= pack 'H*', '30303336026572726f723a20686f6f6b206465636c696e656420746f2075706461746520726566732f68656164732f6d61737465720a303033650130303065756e7061636b206f6b0a303032376e6720726566732f68656164732f6d617374657220686f6f6b206465636c696e65640a3030303030303030';
    return $s;
}

sub git_error {
    my ($self, $c, $msg, $err ) = @_;
    _error( _loc('Git error: %1 %2 (user=%3)', $msg, $err, $c->username ) );
    $c->res->content_type( 'application/x-git-upload-pack-result' );
    $c->res->body(
        $self->res_msg( sprintf("\nCLARIVE ERROR: %s",$msg), $err)
    );
}
1;
