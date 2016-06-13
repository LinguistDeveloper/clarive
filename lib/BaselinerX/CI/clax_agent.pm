package BaselinerX::CI::clax_agent;
use Baseliner::Moose;

use URI;
use HTTP::Tiny;
use File::Basename qw(basename dirname);
use String::CRC32 ();
use IO::Socket::SSL;
use Try::Tiny;
use BaselinerX::Type::Model::ConfigStore;
use Baseliner::Utils qw(:logging _file _dir _array);
use BaselinerX::Type::Model::ConfigStore;

has
  port    => qw(is rw isa Str),
  default => sub {
    return BaselinerX::Type::Model::ConfigStore->new->get( 'clax_port', value => 1 )
      || 11801;
  };
has timeout => qw(is rw isa Str);
has
  hops    => qw(is ro isa ArrayRef lazy 1),
  default => sub {
    my $self = shift;
    $self->_calculate_hops;
  };

has basic_auth_enabled  => qw(is rw isa BoolCheckbox coerce 1 default 0);
has basic_auth_username => qw(is rw isa Str);
has basic_auth_password => qw(is rw isa Str);

has ssl_enabled => qw(is rw isa BoolCheckbox coerce 1 default 0);
has ssl_verify  => qw(is rw isa BoolCheckbox coerce 1 default 0);
has ssl_ca      => qw(is rw isa Str);
has ssl_cert    => qw(is rw isa Str);
has ssl_key     => qw(is rw isa Str);

has_ci 'proxy';

with 'Baseliner::Role::CI::Agent';

sub BUILD {
   my $self = shift;

   $self->os($self->server->os);
   $self->proxy($self->server->proxy) if $self->server->proxy;
};

sub error;

method ping {
    my $ua = $self->_build_ua( timeout => 15 );

    my $url = $self->_build_url('/');

    my $response = $ua->get( $url );

    if ( !$response->{success} ) {
        _fail _loc('Ping failed: %1', $self->_parse_reason($response));
    }

    my $content = try { JSON::decode_json( $response->{content} ) };
    die 'Unknown response from agent' unless $content->{message} && $content->{message} =~ m/Hello, world!/;

    $self->rc( 0 );
    $self->ret( '' );
    $self->output( $response->{content} );

    return $self->tuple;
}

method mkpath ( $path ) {
    my $ua = $self->_build_ua;

    my $url        = $self->_build_url("/tree/");
    my $ua_options = $self->_build_options;

    my $response = $ua->post_form( $url, { dirname => $path }, $ua_options );

    if ( !$response->{success} ) {
        _fail _loc( 'Error while creating a directory: %1', $self->_parse_reason($response) );
    }

    $self->rc(0);
    $self->ret('');
    $self->output('');

    return $self->tuple;
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

    my $url     = $self->_build_url("/command");
    my $ua_options = $self->_build_options;

    if (@args) {
        $cmd = join ' ', $cmd, $self->_quote_cmd(@args);
    }

    my $env = join "\n", _array $options->{env};

    my $response = $ua->post_form(
        $url,
        {
            command => $cmd,
            $env ? ( env => $env ) : (),
            chdir => ( $options->{chdir} // '' ),
            user  => ( $self->user       // '' )
        },
        {
            data_callback => sub {
                my ($chunk) = @_;

                $output .= $chunk;
            },
            %$ua_options
        }
    );

    if ( !$response->{success} ) {
        _fail _loc('Error while executing a command: %1', $self->_parse_reason($response));
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
    my $ua = $self->_build_ua;

    my $url        = $self->_build_url("/tree/$file_or_dir");
    my $ua_options = $self->_build_options;

    my $response = $ua->head( $url, $ua_options );

    if ( $response->{success} ) {
        return 1;
    }
    else {
        return 0;
    }
}

method check_writeable( $file_or_dir ) {
}

method is_writeable( $file_or_dir ) {
}

method put_file( :$local, :$remote, :$group='', :$user=$self->user  ) {
    $remote = $self->normalize_path( $remote );

    my $ua = $self->_build_ua();

    open my $fh, '<', $local or _fail( _loc( "Could not open local file `%1`: %2", $local, $! ) );
    binmode $fh;

    if ($self->os eq 'win') {
        $remote =~ s{\\}{/}g;
    }

    my $remote_basename = basename $remote;
    my $remote_dir = dirname($remote);

    if ($remote_dir eq '/' || $remote_dir eq '.') {
        $remote_dir = '' ;
    } else {
        $remote_dir .= '/';
    }

    my @alpha = ('0' .. '9', 'a' .. 'z', 'A' .. 'Z');
    my $boundary = '------------clax';
    $boundary .= $alpha[rand($#alpha)] for 1 .. 20;

    my $first_header = qq{--$boundary\r\nContent-Disposition: form-data; name="file"; filename="$remote_basename"\r\n\r\n};
    my $last_header  = qq{\r\n--$boundary--\r\n};

    my $first_header_sent = 0;
    my $last_header_sent = 0;

    my $url = $self->_build_url("/tree/$remote_dir");
    my $ua_options = $self->_build_options;

    my %query;
    if ($self->copy_attrs) {
        my @stat = stat $local;
        $query{time} = $stat[9];
    }
    $query{crc} = $self->_crc32_from_file($local);

    $url->query_form( map { $_ => $query{$_} } sort keys %query ) if %query;

    my $response = $ua->post(
        $url => {
            headers => {
                'Content-Type'   => qq{multipart/form-data; boundary=$boundary},
                'Content-Length' => length($first_header) + ( -s $fh ) + length($last_header),
                %{delete $ua_options->{headers} || {}}
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
            },
            %$ua_options
        }
    );

    if (!$response->{success}) {
        my $reason = $response->{reason};

        _fail _loc('Error while sending a file: %1', $self->_parse_reason($response));
    }

    return $self->tuple;
}

method get_file( :$local, :$remote, :$group = '', :$user = $self->user ) {
    $remote = $self->normalize_path( $remote );

    my $ua = $self->_build_ua();

    open my $fh, '>', $local or _fail( _loc( "Could not open local file `%1`: %2", $local, $! ) );
    binmode $fh;

    my $url = $self->_build_url("/tree/$remote");
    my $ua_options = $self->_build_options;
    my $response = $ua->get(
        $url => {
            data_callback => sub {
                my ( $chunk, $response ) = @_;

                print $fh $chunk;
            },
            %$ua_options
        }
    );

    if (!$response->{success}) {
        if ($response->{status} eq '404') {
            _fail( _loc( "Remote file `%1` does not exist", $remote) );
        }

        _fail _loc('Error while receiving a file: %1', $self->_parse_reason($response));
    }

    close $fh;

    if (my $exp_crc32 = $response->{headers}->{'x-clax-crc32'}) {
        my $got_crc32 = $self->_crc32_from_file($local);

        if ($exp_crc32 ne $got_crc32) {
            unlink $local;

            _fail _loc('CRC32 check failed');
        }
    }

    return $self->tuple;
}

sub rmpath {
    my $self = shift;
    my ($path) = @_;

    return $self->delete_file(remote => $path, recursive => 1);
}

sub delete_file {
    my $self = shift;
    my (%params) = @_;

    my $remote = $params{remote};
    if ($self->os eq 'win') {
        $remote =~ s{\\}{/}g;
    }

    my $ua = $self->_build_ua();

    my $url = $self->_build_url("/tree/$remote");
    if ( $params{recursive} ) {
        $url->query_form( recursive => 1 );
    }

    my $response = $ua->delete($url);

    if ( !$response->{success} ) {
        if ( $response->{status} eq '404' ) {
            _fail _loc( "Remote file `%1` does not exist", $remote );
        }

        _fail _loc('Error while removing a file: %1', $self->_parse_reason($response));
    }

    return $self->tuple;
}

method remote_eval( $code ) {
}

method sync_dir { _throw 'sync_dir not supported' }

sub _parse_reason {
    my $self = shift;
    my ( $response ) = @_;

    my $reason = $response->{content};
    $reason //= $response->{reason};

    return $reason;
}

sub _crc32_from_file {
    my $self = shift;
    my ($file ) = @_;

    open my $fh, '<', $file or die $!;
    binmode $fh;
    my $crc = String::CRC32::crc32($fh);
    close $fh;

    return sprintf '%08x', $crc;
}

sub _build_url {
    my $self = shift;
    my ( $path ) = @_;

    my $auth = '';
    if ( $self->basic_auth_enabled ) {
        $auth = join ':', $self->basic_auth_username, $self->basic_auth_password;
        $auth .= '@';
    }

    my $url = $self->server->hostname . ':' . $self->port;

    my $hops = $self->hops;

    if (@$hops) {
        $url = $hops->[0];
    }

    my $schema = 'http';
    if ($self->ssl_enabled) {
        $schema .= 's';
    }

    return URI->new("$schema://$auth$url$path");
}

sub _calculate_hops {
    my $self = shift;

    my $agent = $self;

    my @hops;
    push @hops, join( ':', $self->hostname, $self->port );
    my %hops_seen = ( $hops[0] => 1 );

    while ( $agent->proxy && !$agent->proxy->isa('BaselinerX::CI::Empty') ) {
        $agent = $agent->proxy->connect;

        die 'Proxy configuration only supported in Clax' unless $agent->isa('BaselinerX::CI::clax_agent');

        my $proxy = join ':', $agent->hostname, $agent->port;
        if ( $hops_seen{$proxy} ) {
            die 'Recursive proxy configuration in ' . $self->mid;
        }

        $hops_seen{$proxy}++;
        unshift @hops, $proxy;
    }

    return \@hops;
}

sub _build_options {
    my $self = shift;

    my $options = {};

    my $hops = $self->hops;

    if ($hops && @$hops) {
        shift @$hops;

        if (@$hops) {
            $options->{headers}->{'X-Hops'} = join ',', @$hops;
        }
    }

    return $options;
}

sub _build_ua {
    my $self = shift;
    my (%params) = @_;

    my $timeout = $params{timeout} ? $params{timeout} : $self->timeout ? $self->timeout : undef;

    return HTTP::Tiny->new(
        timeout => $timeout,
        $self->ssl_enabled
        ? (
            SSL_verify => $self->ssl_verify ? 1 : 0,
            SSL_options => {
                SSL_ca_file   => $self->ssl_ca,
                SSL_cert_file => $self->ssl_cert,
                SSL_key_file  => $self->ssl_key,
            }
          )
        : ()
    );
}

1;
