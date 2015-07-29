package Baseliner::Controller::GitSmart;
use Moose;
=head1 NAME

BaselinerX::Controller::GitSmart - interface to Git Smart HTTP

=head1 DESCRIPTION

This controller manages all interagtions with git-http-backend

=cut
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Path::Class;
use experimental 'smartmatch';

#BEGIN { extends 'Catalyst::Controller::WrapCGI' }
BEGIN { extends 'Catalyst::Controller' }

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
     _debug "GIT USER=" . ( $c->username // '');
}

sub git : Path('/git/') {
    my ($self,$c, @args ) = @_;
    my $p = $c->request->parameters;
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
    
    # parse request body, if any, to find the commit sha and branch (ref)
    my $sha;
    my $ref;
    my $ref_prev;
    my $bls = join '|', grep { $_ ne '*' } map { $_->bl } ci->bl->search_cis;
    if( ref ( my $fi = $c->req->body ) ) {
        _debug "Checking BL tags in push $bls";
        while( <$fi> ) {
            # find SHA
            my ($top,$com,$r) = split / /, $_;
            if( defined $com && $com =~ /^\w+$/ ) {
                _debug "GIT TOP=$top";
                _debug "GIT COMMIT SHA=$com";
                _debug "GIT REF=$r" if $r || ($r||='');
                $sha = $com;
                $ref = $r;
                $ref_prev = substr $top, 4;
                _debug "GIT REF_PREV=$ref_prev";
            }
            # check BL tags
            if( /refs\/tags\/($bls)/ ) {
                my $tag = $1;
                my $can_tags = Baseliner->model("Permissions")->user_has_action(username=>$c->username,action=>'action.git.update_tags', bl=>$tag );
                if ( !$can_tags ) {
                    $self->process_error($c,'Push Error', _loc('Cannot update internal tag %1', $tag) );
                    return;
                }
            }
        }
        seek $fi,0,0;  # reset fh
    }


    # run cgi
    my ($cgi_msg,$cgi_ret) = ('',0);
    $self->wrap_cgi_stream($c, sub {
        #_debug \%ENV;
        #_debug $p;
        # my $prjr = _file $home;
        # $prjr = $prjr->dir . "";
        $ENV{GIT_HTTP_EXPORT_ALL} = 1;
        $ENV{GIT_PROJECT_ROOT} = "$home";
        $ENV{REMOTE_USER} ||= 'baseliner';
        $ENV{REMOTE_ADDR} ||= 'localhost';
        $ENV{REQUEST_URI} = $uri_path if length $uri_path; 
        $ENV{FILEPATH_INFO} = $filepath_info if length $filepath_info; 
        $ENV{PATH_INFO} = $path_info if length $path_info; 
        
        $cgi_ret = $self->run_forked( $c, $cgi );   # TODO use system $cgi in CygWin?
    },sub{
       my $err = shift;
       $self->process_error($c,'GIT ERROR', $err);
    }); 

    # now gather commit info and event it
    $self->event_this($c,$sha,$fullpath,$ref,$ref_prev,$repo);
}

sub run_forked {
    my ($self,$c,$cgi) = @_;
    
    # fork a child
    use POSIX ":sys_wait_h";
    pipe( my $stdoutr, my $stdoutw );
    pipe( my $stderrr, my $stderrw );
    pipe( my $stdinr,  my $stdinw );
    my $pid = fork();
    _fail("fork failed: $!") unless defined $pid;

    if ($pid == 0) { # child
        local $SIG{__DIE__} = sub {
            print STDERR @_;
            exit(1);
        };
        close $stdoutr;
        close $stderrr;
        close $stdinw;
        #require CGI::Emulate::PSGI;
        #local %ENV = (%ENV, CGI::Emulate::PSGI->emulate_environment($env));
        open( STDOUT, ">&=" . fileno($stdoutw) ) or _fail( "Cannot dup STDOUT: $!");
        open( STDERR, ">&=" . fileno($stderrw) ) or _fail( "Cannot dup STDERR: $!");
        open( STDIN, "<&=" . fileno($stdinr) ) or _fail( "Cannot dup STDIN: $!");
        #chdir(File::Basename::dirname($cgi));
        exec($cgi) or _fail( "exec: $!");
        exit(2);
    }
    close $stdoutw;
    close $stderrw;
    close $stdinr;
    
    my $siz = 0;
    # do some writing to process STDIN
    { 
        _debug( 'starting write' );
        local $/ = \10_485_760;
		if( my $fh = $c->req->body ) {
			while( my $in = <$fh> ) { #<STDIN> ) {
				_debug( sprintf 'write: %d (total=%s)', length $in, $siz+=length $in );
				syswrite($stdinw, $in ) if length $in;
            }
        }
    }
    # close STDIN so child will stop waiting
    close $stdinw;
    
    # now read git STDOUT
    $siz = 0;
    my $has_headers = 0;
    while (waitpid($pid, WNOHANG) <= 0) {
        my $out = do { local $/ = \10_485_760; <$stdoutr> } || '';
        _debug( sprintf 'read: %d (total=%s)', length $out, $siz+=length $out );
        if( !$has_headers && $out =~ m/^(.*?)\r\n\r\n(.*)$/s ) {
            my $head = $1;
            while( $head =~ m/^(.+): (.+)[\n\r]?/mg ) {
                $c->res->headers->header( $1 => $2 );
            }
            $out = $2;
            $has_headers = 1;
            _debug( 'finhead: ' . length $head );
            _debug( 'finread: ' . length $out );
            $c->res->finalize_headers($c);
        }
        $c->res->write( $out ) if length $out;
    }
    my $out = do { local $/; <$stdoutr> } || '';
    my $err = do { local $/; <$stderrr> } || '';
    _error( "ERROR FINAL git cgi: $err" ) if length $err;
    if( length $err ) {
        _fail $err;
    }
    _debug( sprintf 'readfin: %d (total=%s)', length $out, $siz+=length $out );
    $c->res->write( $out ) if length $out;
    $c->res->body( '' );
    return 0;
}

sub process_error {
    my ($self,$c,$type,$err) = @_;
    my $msg = _loc( "CLARIVE: %1: %2", $type, "$err\n" );
    
    # client version parse
    require version;
    my ($git_ver) = $c->req->user_agent =~ /git\/([\d\.]+)/;
    $git_ver =~ s/\.$//g; # ie. 2.1.0.GIT => 2.1.0.
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


sub event_this {
    my ($self,$c,$sha,$fullpath,$ref,$ref_prev,$repo)=@_;
    try {
        if( $sha ) {  
            my $g = Girl::Repo->new( path=>"$fullpath" );
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
                        my $rev = ci->GitRevision->find_one({ sha=>"$sha" });
                        if( ! $rev ) {
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
                            $mid = $rev->{mid};
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

# git_error deprecated, use process_error
sub git_error {
    my ($self, $c, $msg, $err ) = @_;
    _error( _loc('Git error: %1 %2 (user=%3)', $msg, $err, $c->username ) );
    $c->res->content_type( 'application/x-git-upload-pack-result' );
    $c->res->body(
        $self->res_msg( sprintf("\nCLARIVE ERROR: %s",$msg), $err)
    );
}

# rgo: my own CGI wrapper:  TODO maybe a Catalyst module somewhere?
use URI ();
use URI::Escape;
use HTTP::Request::Common;
open my $REAL_STDIN, "<&=".fileno(*STDIN);
open my $REAL_STDOUT, ">>&=".fileno(*STDOUT);
 
sub wrap_cgi_stream {
  my ($self, $c, $call, $call_err) = @_;
  my $req = HTTP::Request->new(
    map { $c->req->$_ } qw/method uri headers/
  );
  my $body = $c->req->body;
  my $body_content = '';
 
  $req->content_type($c->req->content_type); # set this now so we can override
 
  if (!$body) { # Slurp from body filehandle
    my $body_params = $c->req->body_parameters || {};
 
    if (%$body_params) {
      my $encoder = URI->new;
      $encoder->query_form(%$body_params);
      $body_content = $encoder->query;
      $req->content_type('application/x-www-form-urlencoded');
      $req->content($body_content);
      $req->content_length(length($body_content));
    }
  }
 
  my $username_field = $self->{CGI}{username_field} || 'username';
  my $username = (($c->can('user_exists') && $c->user_exists)
               ? eval { $c->user->obj->$username_field }
                : '');
  $username ||= $c->req->remote_user if $c->req->can('remote_user');
 
  my $path_info = '/'.join '/' => map {
    utf8::is_utf8($_) ? uri_escape_utf8($_) : uri_escape($_)
  } @{ $c->req->args };
 
  my $env = HTTP::Request::AsCGI->new(
              $req,
              ($username ? (REMOTE_USER => $username) : ()),
              PATH_INFO => $path_info,
# eww, this is likely broken:
              FILEPATH_INFO => '/'.$c->action.$path_info,
              SCRIPT_NAME => $c->uri_for($c->action, $c->req->captures)->path
            );
 
  {
    my $saved_error;
 
    local %ENV = %{ $self->_filtered_env(\%ENV) };
 
    $env->setup;
    eval { $call->() };
    $saved_error = $@;
    #$env->restore;
 
    if( $saved_error ) {
        if( $call_err ) {
            $call_err->($saved_error);
        } else {
            die $saved_error if ref $saved_error;
            Catalyst::Exception->throw(
                message => "CGI invocation failed: $saved_error"
               );
        }
    }
  }
 
  #return $env->response;
 return ;
}
my $DEFAULT_KILL_ENV = [qw/
  MOD_PERL SERVER_SOFTWARE SERVER_NAME GATEWAY_INTERFACE SERVER_PROTOCOL
  SERVER_PORT REQUEST_METHOD PATH_INFO PATH_TRANSLATED SCRIPT_NAME QUERY_STRING
  REMOTE_HOST REMOTE_ADDR AUTH_TYPE REMOTE_USER REMOTE_IDENT CONTENT_TYPE
  CONTENT_LENGTH HTTP_ACCEPT HTTP_USER_AGENT
/];
 
sub _filtered_env {
  my ($self, $env) = @_;
  my @ok;
 
  my $pass_env = $self->{CGI}{pass_env};
  $pass_env = []            if not defined $pass_env;
  $pass_env = [ $pass_env ] unless ref $pass_env;
 
  my $kill_env = $self->{CGI}{kill_env};
  $kill_env = $DEFAULT_KILL_ENV unless defined $kill_env;
  $kill_env = [ $kill_env ]  unless ref $kill_env;
 
  if (@$pass_env) {
    for (@$pass_env) {
      if (m!^/(.*)/\z!) {
        my $re = qr/$1/;
        push @ok, grep /$re/, keys %$env;
      } else {
        push @ok, $_;
      }
    }
  } else {
    @ok = keys %$env;
  }
 
  for my $k (@$kill_env) {
    if ($k =~ m!^/(.*)/\z!) {
      my $re = qr/$1/;
      @ok = grep { ! /$re/ } @ok;
    } else {
      @ok = grep { $_ ne $k } @ok;
    }
  }
  return { map {; $_ => $env->{$_} } @ok };
}

1;
