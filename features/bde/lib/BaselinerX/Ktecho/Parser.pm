package BaselinerX::Ktecho::Parser;
use strict;
use warnings;
use English;
use Exporter::Tidy default => [ qw{ parse
                                    get_config } ];

my @config_files = ( qw{ config.bde
                         config.harvest } );

my @is = ( qw{ is 
               =
               ==
               equals } );

my @isnt = ( qw{ isnt
                 <>
                 !=
                 differs } );

sub parse {
  # Translates the pseudo-sql into a Perl condition.
  my $string = shift;
  for my $cond (@is)   { $string =~ s/\s$cond\s/ eq /xig }  # @is to 'eq'
  for my $cond (@isnt) { $string =~ s/\s$cond\s/ ne /xig }  # @isnt to 'ne'
  $string =~ s/"/'/xig;                                     # " to '
  $string =~ s/(\band\b|\bor\b)/\L$1/xig;                   # lowercase AND OR
  $string =~ s/\n//xig;                                     # no line breaks
  $string =~ s/(\S+)\s+(\bne|eq|in|like\b)/\$\L$1 $2/xig;   # lc operators
  $string =~ s/\s+/ /g;                                     # trim whitespace
  $string =~ s/\bin\b\s(\w+)/~~ \@$1/xig;                   # IN...
  $string =~ s/(\S+)\s~~\s(\S+)/( $1 ~~ $2 )/xig;           # IN...
  $string =~ s/(\S+)\slike\s(\S+)/( $1 =~ m\/\$$2\/i )/xig; # LIKE...
  $string =~ s/m\/\$'(%)(\S+)(%)'/m\/$2/xig;                # %LIKE%
  $string =~ s/\$'(\S+)(%)'/\${\^POSTMATCH}$1/xig;          # LIKE%
  $string =~ s/\$'(%)(\S+)'/\${\^PREMATCH}$2/xig;           # %LIKE
  $string =~ s/m\/\$'(\S+)'/m\/$1/xig;                      # LIKE
  $string =~ s/\$(\w+)/\$data->{\L$1}/xig;                  # $data->{$value}
  $string =~ s/\@(\S+)/\@{ \$data->{\L$1} }/xig;            # @$data->{$value}
  $string }

sub get_config {
  # Loads a hash with all parameters from config.* (see above). Will also load
  # values from stash (highest priority).
  my %data = ();
  for my $config (@config_files) {
      my %temp_hash = %{ Baseliner->model('ConfigStore')->get($config) };
      while ( my ( $key, $val ) = each %temp_hash ) {
          $data{$key} = ( $val =~ m/,/x )
                      ? to_array_hash($val)
                      : $val; } }
  %data }

sub trim_beginning_whitespace {
  my $string = shift;
  $string =~ s/^\s+//xig;
  $string }

sub trim_ending_whitespace {
  my $string = shift;
  $string =~ s/\s+$//xig;
  $string }

sub to_array_hash {
  # Arrays are cooler and more maintenable than joined values.
  my $val = shift;
  my @temps = split ',', $val;
  for my $trim_me (@temps) {
      $trim_me = trim_beginning_whitespace($trim_me);
      $trim_me = trim_ending_whitespace($trim_me) }
  \@temps }

1;
