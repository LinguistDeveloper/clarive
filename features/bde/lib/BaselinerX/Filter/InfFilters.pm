package BaselinerX::Filter::InfFilters;
use warnings;
use strict;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Ktecho::CamUtils;
use 5.010;

register 'config.harvest.path_in_elements' => {
    metadata => [
        { id=>'path_regex', label=>'Path Regex to check if its in the element stash. Returns true if found' }, 
    ],
};

register 'filter.harvest.path_in_elements' => {
    config  => 'config.harvest.filter.path_in_elements',
    handler => \&check_elements,
};

sub check_elements {
    my ($self, $c, $config ) = @_;
    my $job = $c->stash->{job};
    my $job_stash = $job->{job_stash};
    my $elements = $job_stash->{elements};
    my $re = $config->{path_regex} or _throw 'Missing filter config parameter path_regex';
    $re = qr/$re/;
    for my $element ( _array $elements ) {
        return 1 if $element->{path} =~ $re;
    }
    return 0;
}

register 'filter.inf.net_projects' => {
  name    => 'has new projects',
  config  => 'config.filter.has_net_projects',
  handler => \&has_net_projects, };

register 'filter.inf.public' => {
  name    => 'is public',
  config  => 'config.filter.is_public',
  handler => \&is_public, };

register 'config.filter.is_public' => {
  metadata => [ { id    => 'is_public',
                  label => 'Checks if the application is public', }, ], };

register 'config.inf.has_net_projects' => {
  metadata => [ { id    => 'net_projects',
                  label => 'Checks if the application has .NET projects', },
              ], };

sub has_net_projects {
  # Checks whether a given cam has .NET projects.
  my ( $self, $c, $config ) = @_;
  _log "hago algo";
  my @array = sub_apps $config->{cam}, 'net';
  return 1 if scalar(@array) > 1;
  return 0; }

sub is_public {
  # Is the application public?
  my ( $self, $c, $config ) = @_;
  my $cam = $config->{cam};
  my $inf = inf $cam;
  _log "hello world";
  # return $inf->is_public_bool; }
  return; }

1;
