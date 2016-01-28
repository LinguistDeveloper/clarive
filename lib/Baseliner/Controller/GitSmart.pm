package Baseliner::Controller::GitSmart;
use Moose;
BEGIN { extends 'Catalyst::Controller::WrapCGI' }

use Cwd qw(realpath);
use Try::Tiny;
use Path::Class;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Model::Permissions;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::GitSmartParser;

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

    my $original_path = join '/', @args;

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
    my $path_info;

    my $project;
    my $repo;
    my $fullpath;

    $c->{stash}->{git_lastarg} = $args[-1] // '';

    if( !$config->{force_authorization} && $original_path =~ m{\.git} ) {
        my $repo_name = $self->_extract_repo(@args);
        $fullpath = _file( $home, $repo_name ); # simulate it's a file
        $home = $fullpath->dir->absolute;

        $path_info = "/$original_path";
    }
    else {
        my $project_name = $args[0] // '';
        my $repo_name = $args[1] // '';

        unless ($project_name && $repo_name) {
            $self->process_error(
                $c,
                'invalid repository',
                _loc( "Invalid or unauthorized git repository path %1", join( '/', @args ) )
            );
            $c->response->status( 401 );
            return;
        }

        $project = ci->search_ci(
            '$or'      => [ { name => $project_name }, { moniker => $project_name } ],
            collection => 'project'
        );
        unless( $project ) {
            $self->git_error( $c, 'internal error', _loc('Project `%1` not found', $project_name) );
            $c->response->status( 404 );
            return;
        }

        $repo = ci->search_ci(
            '$or' => [
                { name => $repo_name }, { moniker => $repo_name }, { moniker => lc($project_name) . "_" . $repo_name }
            ],
            collection => 'GitRepository'
        );
        unless ($repo) {
            $self->git_error(
                $c,
                'internal error',
                _loc( 'Repository `%1` not found for project `%2`', $repo_name, $project_name )
            );
            $c->response->status(404);
            return;
        }

        $fullpath = $repo->repo_dir;
        my $repo_dir = _dir( $repo->repo_dir );
        $home = $repo_dir->parent;

        shift @args;
        shift @args;
        $path_info = join('/', $repo_dir, @args);
        $path_info =~ s{^$home}{};
    }

    return unless $self->access_granted($c, $project);

    # TODO - check if the user has "action.git.repo_new" :
    # $c->model('Git')->setup_new_repo( service=>$p->{service}, repo=>$repo, home=>$home );

    # get git service 
    my $lastarg = $c->stash->{git_lastarg};
    my $service = $c->req->params->{service};
    $service=$lastarg if !$service && $lastarg =~ /^git-/;  # last arg is service then? ie. git/prj/repo/git-upload-pack
    $service //= $c->session->{git_last_service} // 'git-upload-pack';
    $c->session->{git_last_service} //= $service;
    $c->stash->{git_service} = $service;
    #_debug ">>> GIT SERVICE=$service";
    
    my $fh = $c->req->body;

    my @changes = $self->_build_parser()->parse_fh($fh);

    return unless $self->bl_change_granted($c, \@changes);

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
            local $ENV{PATH_INFO} = $path_info;

            system($cgi);
        }
    );

    my $repo_id = $self->_create_or_find_repo("$fullpath");
    my $g = Girl::Repo->new( path => "$fullpath" );

    foreach my $change (@changes) {
        my $new_sha   = $change->{new};
        my $old_sha   = $change->{old};
        my $ref       = $change->{ref};
        my $ref_short = [ split '/', $ref ]->[-1];

        next if $new_sha eq ('0' x 40);

        my $commit = $g->commit($new_sha);
        my $diff   = $self->_diff( $g, $old_sha, $new_sha );
        my $title  = $commit->message;

        my $rev_mid = $self->_create_or_find_rev( $new_sha, $repo_id, $commit, $ref_short );

        event_new 'event.repository.update' => {
            username   => $c->username,
            repository => $repo,
            message    => $title,
            diff       => $diff,
            branch     => $ref_short,
            ref        => $ref,
            sha        => $new_sha,
            _steps     => ['POST'],
          } => sub {
            return { mid => $rev_mid, title => $title };
          };
    }
}

sub bl_change_granted {
    my $self = shift;
    my ($c, $changes) = @_;

    my $bls = join '|', grep { $_ ne '*' } map { $_->bl } ci->bl->search_cis;

    foreach my $change (@$changes) {
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

    return 1;
}

sub access_granted {
    my $self = shift;
    my ($c, $project) = @_;

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
    } elsif( $project ) {
        my $id_project = $project->{mid};
        my @project_ids = Baseliner::Model::Permissions->new->user_projects_ids(username=>$c->username);

        my $is_user_project = (grep { $_ && $_ eq $id_project } @project_ids) ? 1 : 0;
        my $user_has_action =
          $project->user_has_action( username => $c->username, action => 'action.git.repository_access' );

        unless ($is_user_project && $user_has_action) {
            $self->process_error( $c, _loc('User: %1 does not have access to the project %2', $c->username, $project->name ) );
            $c->response->status( 401 );
            return;
        } 
    }

    return 1;
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
    $err //= '';
    my $msg = _loc( "CLARIVE: %1: %2", $type, "$err\n" );

    # client version parse
    require version;
    my ($git_ver) = $c->req->user_agent =~ /git\/([\d\.]+)/;
    $git_ver =~ s/\.$//g if $git_ver; # ie. 2.1.0.GIT => 2.1.0.
    $git_ver = try { version->parse($git_ver) } catch { version->parse('1.8.0') };

    my $service = $c->stash->{git_service} // ''; 
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

    $fullpath = realpath $fullpath;

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

    my $zero_sha = '0' x 40;

    my $diff = ($ref_prev eq $zero_sha || $sha eq $zero_sha)
        ? _format_diff( join "\n", $git->exec( 'show', $sha ) )
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

sub _build_parser {
    my $self = shift;

    return Baseliner::GitSmartParser->new;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
