package Baseliner::Controller::GitSmart;
use Moose;

use Baseliner::Core::Registry ':dsl';
use Baseliner::Model::Permissions;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::GitSmartParser;
use Cwd qw(realpath);
use Try::Tiny;
use Path::Class;
use experimental 'smartmatch';

BEGIN { extends 'Catalyst::Controller::WrapCGI' }

sub begin : Private {  #TODO control auth here
     my ($self,$c) = @_;
     my $config = config_get 'config.git';
     $c->stash->{git_config} = $config;
     if( $config->{no_auth} ) {
         $c->stash->{auth_skip} = 1;
     } elsif( ! length $c->username ) {
         $c->stash->{auth_basic} = 1;
         $c->stash->{api_key_authentication} = 1;
     } 
     _debug "GIT USER=" . ( $c->username // '');
}

sub git : Path('/git/') {
    my ($self,$c, @args ) = @_;
    my $config = $c->stash->{git_config};
    my $cgi = $config->{gitcgi} or _throw 'Missing config.git.gitcgi';
    if( ! -e $cgi ) {
        $self->process_error( $c, 'internal error', _loc("File %1 does not exist", $cgi) );
        return;
    }
    my $home = $config->{home} or do{
        $self->process_error( $c, 'internal error', 'Missing config.git.repo' );   
        return;
    };

    my $repo = $self->_extract_repo(@args);

    # normalize paths
    my $fullpath = _file( $home, $repo ); # simulate it's a file

    unless ($fullpath && -d $fullpath) {
        $self->git_error( $c, 'internal error', 'Repository does not exist' );
        $c->response->status( 404 );
        return;
    }

    $repo = $fullpath->basename;  # should be something.git
    my $project = $args[0] // '';
    my $reponame = $args[1] // '';
    my $lastarg = $args[-1];
    $c->stash->{git_lastarg} = $lastarg;
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
        unless( $ci_prj ) {
            $self->git_error( $c, 'internal error', _loc('Project `%1` not found', $project) );
            $c->response->status( 404 );
            return;
        }
        ($ci_repo) = ci->search_cis( '$or'=>[ {name=>$reponame}, {moniker=>$reponame}, {moniker=>lc($project)."_".$reponame} ], collection=>'GitRepository' );
        unless( $ci_repo ) {
            $self->git_error( $c, 'internal error', _loc('Repository `%1` not found for project `%2`', $reponame, $project) );
            $c->response->status( 404 );
            return;
        }
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
            $self->process_error( $c, 'internal error', _loc 'Could not parse git uri: %1', $c->req->uri );
            $c->response->status( 404 );
            return;
        }
        
        if( !defined $ci_prj ) {
            $self->process_error( $c, 'internal error', _loc("Invalid project name %1", $project) );
            $c->response->status( 404 );
            return;
        }
        if( !defined $ci_repo ) {
            $self->process_error( $c, 'internal error', _loc("Invalid repository name %1", $reponame) );
            $c->response->status( 404 );
            return;
        }
        _log _loc "Git: User %1 access to project %2 (mid=%3) repository %4 (mid=%5)", $c->username, $project, $ci_prj->mid,
            $reponame, $ci_repo->mid;
    } else {
        $self->process_error( $c, 'invalid repository', _loc("Invalid or unauthorized git repository path %1", $repopath ) );
        $c->response->status( 401 );
        return;
    }
    # Check permissions
    if( ! length $c->username ) {
        if( ! exists $c->req->params->{service} ) {  # first request has param 'service'
            $self->process_error( $c, 'access denied', 
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
            $self->process_error( $c, 'access denied', 
                    _loc("Authentication failed for user '%1': %2", $c->stash->{login}, $c->stash->{auth_message} ) 
                );
            $c->response->status( 401 );
            return;
        }
    } elsif( $ci_prj ) {
        my $id_project = $ci_prj->{mid};
        my @project_ids = Baseliner->model('Permissions')->user_projects_ids(username=>$c->username);
        if( !$ci_prj->user_has_action(username=>$c->username,action=>'action.git.repository_access') || (!$id_project ~~ @project_ids) ) {
            $self->process_error( $c, _loc('User: %1 does not have access to the project %2', $c->username, $project ) );
            return;
        } 
    }

    # TODO - check if the user has "action.git.repo_new" :
    # $c->model('Git')->setup_new_repo( service=>$p->{service}, repo=>$repo, home=>$home );

    # get git service 
    my $service = $c->req->params->{service};
    $service=$lastarg if !$service && $lastarg =~ /^git-/;  # last arg is service then? ie. git/prj/repo/git-upload-pack
    $service //= $c->session->{git_last_service} // 'git-upload-pack';
    $c->session->{git_last_service} //= $service;
    $c->stash->{git_service} = $service;
    _debug ">>> GIT SERVICE=$service";
    
    my $fh = $c->req->body;

    my @changes = $self->_build_parser()->parse_fh($fh);

    # parse request body, if any, to find the commit sha and branch (ref)
    my $bls = join '|', grep { $_ ne '*' } map { $_->bl } ci->bl->search_cis;

    # Check BL tags
    foreach my $change (@changes) {
        my $ref = $change->{ref};

        if ($bls && $ref =~ /refs\/tags\/($bls)/) {
            my $tag      = $1;
            my $can_tags = Baseliner::Model::Permissions->new->user_has_action(
                username => $c->username,
                action   => 'action.git.update_tags',
                bl       => $tag
            );
            if (!$can_tags) {
                $self->process_error($c, 'Push Error',
                    _loc('Cannot update internal tag %1', $tag));
                return;
            }
        }
    }

    $fullpath = realpath $fullpath;

    my $error;
    foreach my $change (@changes) {
        my $sha = $change->{new};
        my $ref = $change->{ref};

        my $ref_short = [ split '/', $ref ]->[-1];

        event_new
          'event.repository.update' => {
            username   => $c->username,
            repository => $repo,
            branch     => $ref_short,
            ref        => $ref,
            sha        => $sha,
            _steps     => ['PRE']
          },
          sub { }, sub {
            my ($err) = @_;

            $error = $err;
          };
    }

    if ($error) {
        $self->process_error( $c, 'GIT ERROR', $error );
        return;
    }

    $self->cgi_to_response(
        $c,
        sub {
            local $ENV{GIT_HTTP_EXPORT_ALL} = 1;
            local $ENV{GIT_PROJECT_ROOT}    = "$home";

            local $ENV{REMOTE_USER} ||= $c->username;
            local $ENV{REMOTE_ADDR} ||= 'localhost';

            local $ENV{REQUEST_URI}  = $uri_path if $uri_path;
            local $ENV{FILEPATH_INFO}= $filepath_info if $filepath_info;
            local $ENV{PATH_INFO}    = $path_info if $path_info;

            system($cgi);
        }
    );

    my $repo_id = $self->_create_or_find_repo($fullpath);
    my $g = Girl::Repo->new( path => "$fullpath" );

    foreach my $change (@changes) {
        my $sha       = $change->{new};
        my $ref_prev  = $change->{old};
        my $ref       = $change->{ref};
        my $ref_short = [ split '/', $ref ]->[-1];

        my $commit    = $g->commit($sha);
        my $diff      = $self->_diff( $g, $ref_prev, $sha );
        my $title     = $commit->message;

        my $rev_mid = $self->_create_or_find_rev( $sha, $repo_id, $commit, $ref_short );

        event_new 'event.repository.update' => {
            username   => $c->username,
            repository => $repo,
            message    => $title,
            diff       => $diff,
            branch     => $ref_short,
            ref        => $ref,
            sha        => $sha,
            _steps     => ['POST'],
          } => sub {
            return { mid => $rev_mid, title => $title };
          };
    }
}

sub _extract_repo {
    my $self = shift;
    my (@parts) = @_;

    my @repo;
    foreach my $part (@parts) {
        push @repo, $part;

        last if $part =~ m/\.git$/;
    }

    return "". _dir( @repo );
}

sub process_error {
    my ($self,$c,$type,$err) = @_;
    my $msg = _loc( "CLARIVE: %1: %2", $type, "$err\n" );

    # client version parse
    require version;
    my ($git_ver) = $c->req->user_agent =~ /git\/([\d\.]+)/;
    $git_ver =~ s/\.$//g if $git_ver; # ie. 2.1.0.GIT => 2.1.0.
    $git_ver = try { version->parse($git_ver) } catch { version->parse('1.8.0') };

    my $service = $c->stash->{git_service}; 
    _debug ">>> GIT VERSION=$git_ver";
    _error( $msg );
    if( $c->stash->{git_lastarg} eq 'git-receive-pack' ) {
        #my $m2 = 'refs/tags/CERT hook declined';
        $msg = sprintf 
        "%04x\002%s".
        #"0033\002error: hook declined to update refs/tags/CERT\n".
        #"003b\001000eunpack ok\n".
        #"0024ng refs/tags/CERT hook declined\n".
        #"%04x\001000eunpack ok\n".
        #"%04xng %s\n".
        "00000000\n", 5+length($msg),$msg; # ,31+length($m2),8+length($m2),$m2; 
        $c->res->status( 200 );
        $c->res->content_type( "application/x-git-receive-pack-result" );
        $c->res->headers->header( 'Cache-Control'=>'no-cache, max-age=0, must-revalidate' );
        $c->res->headers->header( 'Pragma' => 'no-cache' );
        $c->res->headers->header( 'Expires'=>'Fri, 01 Jan 1980 00:00:00 GMT' );
        $c->res->write( $msg );
        $c->res->body( '' );
    } 
    elsif( !length($git_ver) || $git_ver < version->parse('1.8.3') ) {
        my $servtxt = sprintf "# service=%s\n",$service;
        my $errtxt = sprintf "ERR %s\n",$msg;
        $msg = sprintf "%04x%s0000%04x%s",4+length($servtxt),$servtxt,4+length($errtxt),$errtxt; #  "0036# service=git-receive-pack0000ERR This is a test\n";
        $c->res->status( 200 );
        $c->res->content_type( "application/x-$service-advertisement" );
        $c->res->body( $msg );
        return;
    } else {
        # >= 1.8.3 on can handle this error message style
        $c->res->status( 500 );
        $c->res->content_type( 'text/plain' );
        $c->res->body( $msg );
        return;
    }
}

sub _create_or_find_repo {
    my $self = shift;
    my ($fullpath) = @_;

    my $repo_row = ci->GitRepository->find_one({ repo_dir=>"$fullpath" }); 
    my $repo_id;
    if ($repo_row) {
        $repo_id = $repo_row->{mid};
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

    return $repo_id;
}

sub _create_or_find_rev {
    my $self = shift;
    my ( $sha, $repo_id, $commit, $ref_short ) = @_;

    my $mid;

    my $rev = ci->GitRevision->find_one( { sha => "$sha" } );
    if ($rev) {
        $mid = $rev->{mid};
    }
    else {
        my $title     = $commit->message;
        my $commit2 = substr( $sha,             0, 7 );
        my $msg     = substr( $commit->message, 0, 15 );
        master_new 'GitRevision' => {
            name    => "[$commit2] $title",
            moniker => $commit2,
            data    => { sha => $sha, repo => $repo_id, branch => $ref_short }
          } => sub {
            $mid = shift;
          };
    }

    return $mid;
}

sub _diff {
    my $self = shift;
    my ($git, $ref_prev, $sha) = @_;

    # ref_prev == 0 when it's a new repository
    my $diff = $ref_prev eq ('0' x 40)
        ? _format_diff(  join "\n", $git->exec( 'show', $sha ) )
        : _format_diff( join "\n", $git->exec( 'log', '-p', '--full-diff', "$ref_prev..$sha" ) );

    return $diff;
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

# git_error deprecated, use process_error
sub git_error {
    my ($self, $c, $msg, $err ) = @_;
    _error( _loc('Git error: %1 %2 (user=%3)', $msg, $err, $c->username ) );
    $c->res->content_type( 'application/x-git-upload-pack-result' );
    $c->res->body(
        $self->res_msg( sprintf("\nCLARIVE ERROR: %s",$msg), $err)
    );
}

sub _build_cgi_wrapper {
    my $self = shift;

    return Baseliner::CGIWrapper->new(@_);
}

sub _build_parser {
    my $self = shift;

    return Baseliner::GitSmartParser->new;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
