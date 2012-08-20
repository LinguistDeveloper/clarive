package BaselinerX::Service::Oracle::Distribute;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use Data::Dumper;

with 'Baseliner::Role::Service';

register 'service.oracle.distribute' => {name    => 'Oracle Prepare',
                                         handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job = $c->stash->{job};
  my $log = $job->logger;
  my $sql_elements = $job->job_stash->{elements}->{elements};

  my $env      = $job->job_data->{bl};
  my $env_name = substr($sql_elements->[0]->{package}, 0, 3);  # FIXME
  my $pass     = $job->job_data->{name};
  my $path     = $job->job_stash->{path};
  my $suffix   = 'ORACLE';
  my $packages = BaselinerX::Model::Distribution->job_package_list($job->{jobid});

  my $HarvestState = bl_statename($env);

  my %data = map +($_->{versiondataobjid} =>
                   { FileName        => $_->{fullpath} =~ /\/.+\/(.+)/
                   , ObjectName      => do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /(.+)\./; uc($1) }
                   , PackageName     => $_->{package}
                   , SystemName      => undef
                   , SubSystemName   => undef
                   , DSName          => 'INTERNA',  # TODO
                   , Extension       => do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /\./ ? do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /\.(.+)/ } : undef }
                   , ElementState    => $_->{tag}
                   , ElementVersion  => $_->{version}
                   , ElementPriority => ' '
                   , ElementPath     => $_->{path}
                   , ElementID       => $_->{versiondataobjid}
                   , ParCompIni      => ' '
                   , NewID           => undef
                   , HarvestProject  => $env_name
                   , HarvestState    => $HarvestState
                   , HarvestUser     => $_->{modifier}
                   , ModifiedTime    => $_->{modified_on}
                   }
                  ), @{$sql_elements};

  # $log->debug("Everything seems to be ok... distributing SQL Oracle files");
  _log "Everything seems to be ok... distributing SQL Oracle files";
  my $ora_dist = BaselinerX::Model::Oracle::Distribution->new(cam => $env_name, env => $env, log => $log);
  $ora_dist->sqlBuild(\%data, $pass, $path, $env_name, $env, $suffix, $packages);
  return;
}

1;
