package BaselinerX::Dist::Utils;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Contextual::Return;
use Data::Dumper;
use List::Util qw( first );
use Exporter::Tidy default => [qw(balix
                                  balix_win
                                  balix_unix
                                  kill_duplicates
                                  windir
                                  filter_elements
                                  key_from_port
                                  _balix
                                  )];

{ 
  package BaselinerX::Dist::Utils::BalixPool;
  use BaselinerX::Dist::Utils;
  use Moose;

  has conns => qw/is rw isa HashRef/;

  sub purge {
    my $self = shift;
    my $conns = $self->conns;
    $_->end foreach values %$conns;
  }

  sub conn {
    my $self = shift;
    my $host = shift;
    my $conns = $self->conns;
    $conns->{$host} = balix_unix($host) unless exists $conns->{$host};
    $conns->{$host}; 
  }

  sub conn_port {
    my ($self, $host, $port) = @_;
    my $conns = $self->conns;
    my $hash_key = "${host}${port}";
    $conns->{$hash_key} = _balix(host => $host, port => $port)
      unless exists $conns->{$hash_key};
    $conns->{$hash_key};
  }
}

sub _balix { # :host :port & :os :timeout -> Object
  my %p = @_;
  $p{key} ||= key_from_port($p{port});
  BaselinerX::Comm::Balix->new(%p);
}

sub balix { # Str Str -> Object
  my ($host, $os) = @_;
  _balix(host => $host, port => get_port($host, $os));
}

sub balix_win { # Str -> Object
  my $host = shift;
  balix($host, 'win');
}
  
sub balix_unix { # Str -> Object
  my $host = shift;
  balix($host, 'unix');
}

sub key_from_port { # Str -> Str
  my $port = shift;
  my $key = Baseliner->model('ConfigStore')->get('config.harax')->{$port};
  $key;
}

sub get_port { # Str Str -> Int
  my ($host, $os) = @_;
  _log "Getting port for host: '$host' in os: '$os'";
  return 49164 if $os eq 'win';    # TODO
  my $table = $os eq 'win'  ? 'Inf::InfServerWin'
            : $os eq 'unix' ? 'Inf::InfServerUnix'
            :                 _throw 'wrong OS!';
  my $where = {server => $host};
  my $args  = {select => 'harax_port'};
  my $rs = Baseliner->model($table)->search($where, $args);
  rs_hashref($rs);
  _throw "ERROR: No data for $host in $table" unless scalar $rs->all;
  my $port = $rs->next->{harax_port};
  _log "port: $port";
  $port;
}

sub kill_duplicates { # ArrayRef[Str] -> Defined|ArrayRef[Str]
  # [peanut butter jelly with peanut flavour]
  # => (peanut butter jelly with flavour)
  my $list = shift;
  my @data;
  for (@{$list}) {
    push @data, $_ unless $_ ~~ @data;
  }
  wantarray ? @data : \@data;
}

sub windir { # Undef -> Str|Array
  return (LIST   { map   { $_ =~ s/\//\\/g; $_ } @_ }
          SCALAR { first { $_ =~ s/\//\\/g; $_ } @_ });
}

sub filter_elements { # HashRef[Str] -> Defined|ArrayRef[HashRef]
  my %p = @_;
  my @ls = grep(_pathxs($_->{fullpath}, 2) eq $p{suffix}, 
                @{$p{elements}});
  wantarray ? @ls : \@ls;
}

1;
