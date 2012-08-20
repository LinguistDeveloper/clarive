package BaselinerX::Filter::HasNatureFiles;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'filter.has.nature.files' => {
            name    => 'Has filter nature?',
            handler => \&nature_files_main };

sub nature_files_main {
  my ($self, $data, $config) = @_;
  my $job = $config->{jobid};
  Baseliner->model('Distribution')->has_nature($job, 'fich') }

sub nature_files_main_ibid {
  # Another way to do it.  This is less expensive to use outside the job 
  # chain but requires a path.
  my ($self, $data, $config) = @_;
  `ls $config->{path}/$config->{environmentname}` =~ m/fich/xi ? 1 : 0 }

1
