package BaselinerX::Service::Eclipse::Prepare;
use 5.010;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use Data::Dumper;
use utf8;

has 'suffix', is => 'ro', isa => 'Str', default => sub { 'ECLIPSE' };

with 'Baseliner::Role::Service';

register 'service.eclipse.prepare' => {
  name    => 'Eclipse Prepare',
  handler => \&main
};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $bl       = $job->job_data->{bl};
  my $log      = $job->logger;
  my $suffix   = $self->suffix;
  my @elements = $self->ECLIPSE_elements($job->job_stash->{elements}->{elements});
  my $packages = BaselinerX::Model::Distribution->job_package_list($job->{jobid});
  my $env_name = substr($job->job_stash->{elements}->{elements}->[0]->{package}, 0, 3);
  my $env      = $job->job_data->{bl};
  my $pass     = $job->job_data->{name};
  my $path     = $job->job_stash->{path};

  if (scalar @elements) {
    $log->debug("Listado elementos de pase ECLIPSE:\n" . 
                join("\n", map($_->{fullpath},
                               grep($_->{fullpath} =~ /$suffix/i, 
                                    @elements))));
  }
  else { 
	  _throw "No existen elementos ECLIPSE";
  }

  scalar @$packages
    ? $log->debug("Listado de paquetes del pase:\n" . join("\n", @$packages))
    : _throw "No hay paquetes!";

  my $HarvestState = bl_statename($env);
  # Nota: Copiar de J2EE.
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
                  ), @elements;

  my $dist = BaselinerX::Model::ECLIPSE::Dist->new(pase => $pass);

  $dist->eclipseDist($pass, \%data, $path, $env_name, $env, 'ECLIPSE', $packages);

  return 1;
}

sub eclipse_elements {
  my ($self, $ls) = @_;
  filter_elements(elements => $ls, 
                  suffix   => $self->suffix);
}

1;

__END__

=head1 Description

This is the first step for the ECLIPSE distribution.

=head1 Usage

  $c->launch('service.eclipse.prepare');

Or basically do nothing since the runner is the one supossed to run it.

=cut
