package BaselinerX::Dist::Utils;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Memoize;
use Contextual::Return;
use List::Util qw( first );
use Exporter::Tidy default => [qw(balix
                                  balix_win
                                  balix_unix
                                  kill_duplicates
                                  windir
                                  )];

memoize 'balix';

sub balix {
  my ($host, $os) = @_;
  my $port = get_port($host, $os);
  BaselinerX::Comm::Balix->new(host => $host,
                               port => $port, 
                               key  => key_from_port($port)) }

sub balix_win {
  my $host = shift;
  balix($host, 'win') }
  
sub balix_unix {
  my $host = shift;
  balix($host, 'unix') }

sub key_from_port {
  my $port = shift;
  Baseliner->model('ConfigStore')->get('config.harax')->{$port} }

sub get_port {
  my ($host, $os) = @_;
  return 49164 if $os eq 'win';  # TODO
  my $table = $os eq 'win'  ? 'Inf::InfServerWin'
            : $os eq 'unix' ? 'Inf::InfServerUnix'
            :                 _throw 'wrong OS!';
  my $where = {server => $host};
  my $args  = {select => 'harax_port'};
  my $rs    = Baseliner->model($table)->search($where, $args);
  rs_hashref($rs);
  my $port = $rs->next->{harax_port};
  $port }

sub kill_duplicates {
  # [peanut butter jelly with peanut flavour]
  # => (peanut butter jelly with flavour) 
  my $list = shift;
  my @data;
  for (@{$list}) {
    push @data, $_ unless $_ ~~ @data }
  @data }

sub windir {
  return (LIST   { map   { $_ =~ s/\//\\/g; $_ } @_ }     # CHECK:
          SCALAR { first { $_ =~ s/\//\\/g; $_ } @_ }) }  # Is this lazy?

1
