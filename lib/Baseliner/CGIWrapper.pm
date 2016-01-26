package Baseliner::CGIWrapper;
use Moose;

has env => qw(is ro isa HashRef);

use URI ();
use URI::Escape;
use HTTP::Request::Common;
use Baseliner::Utils qw(_debug);

sub run {
    my $self = shift;
    my ($c, $cgi) = @_;

    my $retval = 0;
    my $error  = '';

    $self->_wrap_cgi_stream(
        $c,
        sub {
            foreach my $key ( keys %{ $self->env } ) {
                $ENV{$key} = $self->env->{$key};
            }

            # TODO use system $cgi in CygWin?
            $retval = $self->_run_forked( $c, $cgi );
        },
        sub {
            my $err = shift;

            $retval = -1;
            $error  = $err;
        }
    );

    return {
        is_success => $retval == 0 ? 1 : 0,
        $error ? ( error => $error ) : ()
    };
}
 
sub _wrap_cgi_stream {
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

sub _run_forked {
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

1;
