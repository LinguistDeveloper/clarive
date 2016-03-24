package Baseliner::Controller::GitSmart;
use Moose;
BEGIN { extends 'Catalyst::Controller::WrapCGI' }

use Cwd qw(realpath);
use Try::Tiny;
use Path::Class;
use URI::Escape 'uri_unescape';
use Baseliner::Core::Registry ':dsl';
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_truncate _debug _error _throw _file _html_escape _loc);
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

    return unless $self->access_granted($c);

    foreach my $arg (@args){
        $arg = uri_unescape($arg);
    }

    my $path = join '/', @args;

    my $git_service;
    my @git_services = ( '/info/refs', '/git-receive-pack', '/git-upload-pack', '/multi-ack', '/multi-ack-detailed' );
    my $git_services_re = join '|', @git_services;
    if ($path =~ s{($git_services_re)$}{}) {
        $git_service = $1;
        $c->stash->{git_service} = $git_service;
    }
    else {
        $self->process_error( $c, 'internal error', 'Unknown request' );
        $c->response->status( 401 );
        return;
    }

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

    $c->{stash}->{git_lastarg} = $args[-1] // '';
    $c->session->{git_last_service} //= $git_service;

    my $repo = $self->_resolve_repo($c, $path);
    return unless $repo;

    my $changes = $self->_parse_changes($c,$path);
    return unless $changes;

    return unless $self->_run_pre_event($c, $repo, $changes);

    my $path_info = $repo->repo_dir;
    $path_info =~ s{^$home}{};
    $path_info .= $git_service;
    $path_info = "/$path_info" unless $path_info =~ m{^/};

    $self->_proxy_to_git_http($c, $cgi, $home, $path_info);

    $self->_run_post_event($c, $repo, $changes);

    return;
}

sub _parse_changes {
    my $self = shift;
    my ($c,$path) = @_;

    my $fh = $c->req->body;

    my @changes = $self->_build_parser()->parse_fh($fh);

    return unless $self->bl_change_granted($c, \@changes,$path);

    return \@changes;
}

sub _run_pre_event {
    my $self = shift;
    my ($c, $repo, $changes) = @_;

    my $error;
    foreach my $change (@$changes) {
        my $sha = $change->{new};
        my $ref = $change->{ref};

        my $ref_short = [ split '/', $ref ]->[-1];

        event_new
          'event.repository.update' => {
            username   => $c->username,
            repository => $repo->name,
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
        $self->git_error( $c, 'GIT ERROR', $error );
        return;
    }

    return 1;
}

sub _run_post_event {
    my $self = shift;
    my ($c, $repo, $changes) = @_;

    my $repo_id = $repo->mid;
    my $g = Girl::Repo->new( path => $repo->repo_dir );

    my $config = $c->stash->{git_config};
    my $max_diff_size = $config->{max_diff_size} // 500 * 1024;

    foreach my $change (@$changes) {
        my $new_sha   = $change->{new};
        my $old_sha   = $change->{old};
        my $ref       = $change->{ref};
        my $ref_short = [ split '/', $ref ]->[-1];

        # Skip removed references
        next if $new_sha eq ('0' x 40);

        my $commit = $g->commit($new_sha);
        my $diff   = $self->_diff( $g, $old_sha, $new_sha );

        $diff = _truncate($diff, $max_diff_size);

        my $title  = $commit->message;

        my $rev_mid = $self->_create_or_find_rev( $new_sha, $repo_id, $commit, $ref_short );

        event_new 'event.repository.update' => {
            username   => $c->username,
            repository => $repo->name,
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

sub _resolve_repo {
    my $self = shift;
    my ($c, $path) = @_;

    my $config = $c->stash->{git_config};
    my $home   = $config->{home};

    my $repo;
    if ( !$config->{force_authorization} && $path =~ m{\.git$} ) {
        $repo = $self->_resolve_repo_raw($home, $path);
        return unless $repo;
    }
    else {
        $repo = $self->_resolve_repo_project($c, $home, $path);
        return unless $repo;
    }

    return $repo;
}

sub _resolve_repo_raw {
    my $self = shift;
    my ($home, $path) = @_;

    my $fullpath = _file( $home, $path );
    $fullpath = realpath($fullpath);

    my $repo_id = $self->_create_or_find_repo("$fullpath");
    return ci->new($repo_id);
}

sub _resolve_repo_project {
    my $self= shift;
    my ($c, $home, $path) = @_;

    my ($project_name, $repo_name) = split '/', $path;

    unless ($project_name && $repo_name) {
        $self->process_error(
            $c,
            'invalid repository',
            _loc( "Invalid or unauthorized git repository path %1", $path )
        );
        $c->response->status( 401 );
        return;
    }

    my $project = ci->search_ci(
        '$or'      => [ { name => $project_name }, { moniker => $project_name } ],
        collection => 'project'
    );
    unless( $project ) {
        $self->git_error( $c, 'internal error', _loc('Project `%1` not found', $project_name) );
        $c->response->status( 404 );
        return;
    }

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

    my $repo = ci->search_ci(
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

    return $repo;
}

sub _proxy_to_git_http {
    my $self= shift;
    my ($c, $cgi, $home, $path_info) = @_;

    $self->cgi_to_response(
        $c,
        sub {
            local $ENV{GIT_HTTP_EXPORT_ALL} = 1;
            local $ENV{GIT_PROJECT_ROOT}    = "$home";

            local $ENV{REMOTE_USER} ||= $c->username;
            local $ENV{REMOTE_ADDR} ||= 'localhost';
            local $ENV{PATH_INFO} = $path_info;

            $self->_system($cgi);
        }
    );
}

sub bl_change_granted {
    my $self = shift;
    my ( $c, $changes, $path ) = @_;
    my ( $project_name, $repo_name ) = split '/', $path if ($path);
    my $my_project    = ci->search_ci( name => $project_name, collection => 'project' ) if ($project_name);
    my $my_repository = ci->search_ci( name => $repo_name,    collection => 'GitRepository' ) if ($repo_name);
    my @tags_modes = $my_repository->{tags_mode} ? ( split /,/, $my_repository->{tags_mode} ) : ();

    my $bls_project;
    my $bls_release;
    my $bls;

    $bls = join '|', grep { $_ ne '*' } map { $_->bl } ci->bl->search_cis;

    if ( grep { $_ eq 'project' } @tags_modes ) {

        $bls_project = $my_project->{moniker} . '-' . join '|' . $my_project->{moniker} . '-',
            grep { $_ ne '*' } map { $_->bl } ci->bl->search_cis;
        $bls = $bls . '|' . $bls_project;

    }
    if ( grep { $_ eq 'release' } @tags_modes ) {

        my @release_versions = BaselinerX::CI::GitRepository->_find_release_versions_by_projects($my_project);
        foreach my $version (@release_versions) {

            $bls_release = $version . '-' . join '|' . $version . '-',
                grep { $_ ne '*' } map { $_->bl } ci->bl->search_cis;

            $bls = $bls . '|' . $bls_release;
        }

    }
    foreach my $change (@$changes) {

        my $ref = $change->{ref};

        if ( $bls && $ref =~ /refs\/tags\/($bls)/ ) {
            my $tag      = $1;
            my $can_tags = Baseliner::Model::Permissions->new->user_has_action(
                username => $c->username,
                action   => 'action.git.update_tags',
                bl       => $tag
            );
            if ( !$can_tags ) {
                $self->process_error( $c, 'Push Error', _loc( 'Cannot update internal tag %1', $tag ) );
                return;
            }
        }
    }

    return 1;
}


sub access_granted {
    my $self = shift;
    my ($c) = @_;

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
    }

    return 1;
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

    my $git_service = $c->stash->{git_service} // ''; 
    _debug ">>> GIT VERSION=$git_ver";
    _error( $msg );
    if( $git_service eq 'git-receive-pack' ) {
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
        my $servtxt = sprintf "# service=%s\n",$git_service;
        my $errtxt = sprintf "ERR %s\n",$msg;
        $msg = sprintf "%04x%s0000%04x%s",4+length($servtxt),$servtxt,4+length($errtxt),$errtxt; #  "0036# service=git-receive-pack0000ERR This is a test\n";
        $c->res->status( 200 );
        $c->res->content_type( "application/x-$git_service-advertisement" );
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

    my $repo_row = ci->GitRepository->find_one( { repo_dir => "$fullpath" } );
    my $repo_id;
    if ($repo_row) {
        $repo_id = $repo_row->{mid};
    }
    else {
        master_new 'GitRepository' => {
            name     => "$fullpath",
            moniker  => "$fullpath",
            repo_dir => "$fullpath",
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

    my $rev = ci->GitRevision->find_one({sha => "$sha"});
    if ($rev) {
        $mid = $rev->{mid};
    }
    else {
        my $title   = $commit->message;
        my $commit2 = substr($sha, 0, 7);
        my $msg     = substr($commit->message, 0, 15);
        master_new 'GitRevision' => {
            name    => "[$commit2] $msg",
            moniker => $commit2,
            sha     => $sha,
            repo    => $repo_id,
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

# git_error deprecated, use process_error
sub git_error {
    my ($self, $c, $msg, $err ) = @_;
    _error( _loc('Git error: %1 %2 (user=%3)', $msg, $err, $c->username ) );
    $c->res->status(200);
    $c->res->content_type( 'application/x-git-upload-pack-result' );
    $c->res->body(
        $self->res_msg( sprintf("\nCLARIVE ERROR: %s",$msg), $err)
    );
}

sub res_msg {
    my $self = shift;

    my $msg = join( "\n", @_ ) || "(no message)";

    # 0005 + length
    my $s;
    $s .= sprintf "%04x\x2", 5 + length($msg);
    $s .= $msg;
    $s .= "0000";
    $s .= "0000";
    return $s;
}

sub _build_parser {
    my $self = shift;

    return Baseliner::GitSmartParser->new;
}

sub _system {
    my $self = shift;
    my ($command) = @_;

    return system($command);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
