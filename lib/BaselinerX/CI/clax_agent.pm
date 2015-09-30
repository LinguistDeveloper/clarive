package BaselinerX::CI::clax_agent;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _file _dir);
use HTTP::Tiny;

has user => qw(is rw isa Str);

has auth_username => qw(is rw isa Str);
has auth_password => qw(is rw isa Str);
has
  port    => qw(is rw isa Num),
  default => sub {
    return Baseliner->model('ConfigStore')->get( 'clax_port', value => 1 )
      || 11800;
  };

with 'Baseliner::Role::CI::Agent';

sub BUILD {
   my $self = shift;

   $self->os($self->server->os);
};

sub error;
sub rmpath;

method mkpath ( $path ) {
}

method chmod ( $mode, $path ) {
}

method chown ( $perms, $path ) {
}

method execute( $options, $cmd, @args ) {
    my $exit_code = 255;
    my $output = '';

    my $ua = $self->_build_ua;
    my $url = $self->_build_url("/command");

    if (@args) {
        $cmd = join ' ', $cmd, $self->_quote_cmd(@args);
    }

    my $response = $ua->post_form(
        $url,
        { command => $cmd, chdir => $options->{chdir}, user => $self->user },
        {
            data_callback => sub {
                my ($chunk) = @_;

                $output .= $chunk;
            }
        }
    );

    if (!$response->{success}) {
        _fail( _loc( "clax get_file: error while executing a command") );
    }

    $exit_code = $response->{headers}->{'x-clax-exit'};

    $self->rc( $exit_code );
    $self->ret( $output );
    $self->output( $output );

    return $self->tuple;
}

method put_dir( :$local, :$remote, :$group='', :$files=undef, :$user=$self->user  ) {
}

method get_dir( :$local, :$remote, :$group='', :$files=undef, :$user=$self->user  ) {
}

method is_remote_dir( $dir ) {
}

method file_exists( $file_or_dir ) {
}

method check_writeable( $file_or_dir ) {
}

method is_writeable( $file_or_dir ) {
}

method put_file( :$local, :$remote, :$group='', :$user=$self->user  ) {
}

method get_file( :$local, :$remote, :$group = '', :$user = $self->user ) {
    $remote = $self->normalize_path( $remote );

    my $ua = $self->_build_ua();

    open my $fh, '>', $local or _fail( _loc( "clax get_file: could not open local file '%1': %2", $local, $! ) );
    binmode $fh;

    my $url      = $self->_build_url("/tree/$remote");
    my $response = $ua->get(
        $url => {
            data_callback => sub {
                my ( $chunk, $response ) = @_;

                print $fh $chunk;
            }
        }
    );

    if (!$response->{success}) {
        if ($response->{status} eq '404') {
            _fail( _loc( "clax get_file: remote file '%1' does not exit", $remote) );
        }
        else {
            _fail( _loc( "clax get_file: error while getting remote file") );
        }
    }

    close $fh;

    return $self->tuple;
}

method remote_eval( $code ) {
}

sub _build_url {
    my $self = shift;
    my ($path) = @_;

    my $url = $self->server->hostname . ':' . $self->port;
    return "http://$url$path",
}

sub _build_ua {
    my $self = shift;

    return HTTP::Tiny->new;
}

1;
