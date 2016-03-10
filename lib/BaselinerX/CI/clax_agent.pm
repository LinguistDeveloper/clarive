package BaselinerX::CI::clax_agent;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _file _dir);
use HTTP::Tiny;
use File::Basename qw(basename dirname);
use URI;
use String::CRC32 ();

has user => qw(is rw isa Str);

has auth_username => qw(is rw isa Str);
has auth_password => qw(is rw isa Str);
has
  port    => qw(is rw isa Num),
  default => sub {
    return Baseliner->model('ConfigStore')->get( 'clax_port', value => 1 )
      || 11801;
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

sub execute {
    my $self = shift;

    my $options = ref $_[0] eq 'HASH' ? shift : {};
    my ($cmd, @args) = @_;

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
    $remote = $self->normalize_path( $remote );

    my $ua = $self->_build_ua();

    open my $fh, '<', $local or _fail( _loc( "clax get_file: could not open local file '%1': %2", $local, $! ) );
    binmode $fh;

    if ($self->os eq 'win') {
        $remote =~ s{\\}{/}g;
    }

    my $basename = basename $local;
    my $dir = dirname $remote;
    $dir = '' if $dir eq '/' || $dir eq '.';

    my @alpha = ('0' .. '9', 'a' .. 'z', 'A' .. 'Z');
    my $boundary = '------------clax';
    $boundary .= $alpha[rand($#alpha)] for 1 .. 20;

    my $first_header = qq{--$boundary\r\nContent-Disposition: form-data; name="file"; filename="$basename"\r\n\r\n};
    my $last_header  = qq{\r\n--$boundary--\r\n};

    my $first_header_sent = 0;
    my $last_header_sent = 0;

    my $url = $self->_build_url("/tree/$dir");

    my %query;
    if ($self->copy_attrs) {
        my @stat = stat $local;
        $query{time} = $stat[9];
    }
    $query{crc} = $self->_crc32_from_file($local);

    $url->query_form(%query) if %query;

    my $response = $ua->post(
        $url => {
            headers => {
                'Content-Type'   => qq{multipart/form-data; boundary=$boundary},
                'Content-Length' => length($first_header) + ( -s $fh ) + length($last_header)
            },
            content => sub {
                my $rcount = read $fh, my $buffer, 8192;

                die "error reading from file: $!" unless defined $rcount;

                if ($rcount == 0) {
                    if (!$last_header_sent) {
                        $last_header_sent++;

                        return $last_header;
                    }

                    close $fh;
                    return;
                }

                if (!$first_header_sent) {
                    $buffer = $first_header . $buffer;
                    $first_header_sent++;
                }

                return $buffer;
            }
        }
    );

    if (!$response->{success}) {
        _fail( _loc( "clax put_file: error while sending remote file") );
    }

    return $self->tuple;
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

    if (my $exp_crc32 = $response->{headers}->{'x-clax-crc32'}) {
        my $got_crc32 = $self->_crc32_from_file($local);

        if ($exp_crc32 ne $got_crc32) {
            unlink $local;
            _fail( _loc( "clax get_file: crc32 check failed") )
        }
    }

    return $self->tuple;
}

method remote_eval( $code ) {
}

sub _crc32_from_file {
    my $self = shift;
    my ($file ) = @_;

    open my $fh, '<', $file or die $!;
    binmode $fh;
    my $crc = String::CRC32::crc32($fh);
    close $fh;

    return sprintf '%x', $crc;
}

sub _build_url {
    my $self = shift;
    my ($path) = @_;

    my $url = $self->server->hostname . ':' . $self->port;
    return URI->new("http://$url$path");
}

sub _build_ua {
    my $self = shift;

    return HTTP::Tiny->new;
}

1;
