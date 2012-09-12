use strict;
use warnings;
use 5.010;
use FindBin;
use Data::Dumper;
use lib "$FindBin::Bin/../lib";
require Baseliner;
use Baseliner::Utils;
use Baseliner::Plug;
use BaselinerX::BdeUtils;
use DateTime;

### harvest.job.new
### --bl DESA
###	--job_type promote
###	--username "[user]"
###	--project "[project]"
###	--from_state "[state]"
###	--to_state "[state]"
###	--packages ["package"]
my ($bl, $job_type, $username, $project, $to_state, @packages) = @ARGV;

say "bl: $bl";
say "job_type: $job_type";
say "username: $username";
say "project: $project";
say "to_state: $to_state";
say "packages:\n" . (join '\n', @packages);

my @natures = packagenames_to_natures @packages;

# Get the calendar ids for this data:
my @calendar_ids = do {
  my $model = Baseliner->model('Baseliner::BaliCalendar');
  my $where = {bl => $bl, ns => [map { "harvest.nature/$_" } @natures]};
  my $rs    = $model->search($where, {select => 'id'});
  rs_hashref($rs);
  map { $_->{id} } $rs->all;
};

my $kind_of_window = current_distribution_type merge_calendars $date->day_of_week, @calendar_ids;

given ($kind_of_window) {
  when ('G') { 
      say "No hay ventana horaria. Consulte los calendarios de las siguientes subaplicaciones: " . (join ', ', @natures) . ".";
  }
  when ('N') { 
    my $cmd = "baliw_udp harvest.job.new --bl $bl --job_type \"$job_type\" --username \"$username\" --project \"$project\" --package " . . " --to_state \"$to_state\"";
    say $cmd;
  }
  when ('U') { 
      say "Ventana horaria urgente.";
  }
  default {
      die "Something went wrong. Window is not in {G N U}.";
  }
}

say "Done!";
