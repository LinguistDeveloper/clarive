package BaselinerX::Service::GenerateFileLists;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Data::Dumper;

with 'Baseliner::Role::Service'; 

register 'service.generate.file.lists' => {name    => 'Generate File Lists',
                                           handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job    = $c->stash->{job};
  my $log    = $job->logger;
  my $job_id = $job->{jobid};
  my $path   = $job->job_stash->{path};
  my $kv     = $job->job_stash->{kv};
  my $win_tar_elements  = $job->job_stash->{win_tar_elements}  || q{};
  my $unix_tar_elements = $job->job_stash->{unix_tar_elements} || q{};

  my @tar_paths;
  my @del_elements;

  if (keys %{$win_tar_elements}) {
    $log->debug("Generating list of new windows elements");
    my $data = $self->generate({path => $path,
                                os   => 'win',
                                type => 'new',
                                map  => $win_tar_elements});
    push @tar_paths, @{$data}, if @{$data}; 

    my $del = $self->generate({path => $path
                              ,os   => 'win'
                              ,type => 'old'
                              ,map  => $win_tar_elements});
    push @del_elements, @{$del} if @{$del}; }
 
  if (keys %{$unix_tar_elements}) {
    $log->debug("Generating list of new unix elements");

    my $data = $self->generate({path => $path,
                                os   => 'unix',
                                type => 'new',
                                map  => $unix_tar_elements});
    push @tar_paths, @{$data} if @{$data}; 

    my $del = $self->generate({path => $path
                              ,os   => 'unix'
                              ,type => 'old'
                              ,map  => $unix_tar_elements});
    push @del_elements, @{$del} if @{$del}; }

  $job->job_stash->{tar_list}     = \@tar_paths;
  $job->job_stash->{del_elements} = \@del_elements;

  return }

sub generate {
  my ($self, $args) = @_;
  my $path = $args->{path};
  my $type = $args->{type};
  my $os   = $args->{os};
  my %map  = %{$args->{map}};
  my $file = "${type}_elements";
  my @tar_paths;
  for my $key (keys %map) {                               # for every hash ref...
    for my $ref (@{$map{$key}}) {                         # iterate each key (which is also the origin path)
      unless ($self->exists_list({path     => $path,      # Do we already have a file? If so, do nothing
                                  filename => $file})) {  #   otherwise...
        open my $fh, '>', "$path/$key/$file";             # Open file
        push @tar_paths, 
             { os        => $os,
             , path_from => "$path/$key",
             , path_to   => $ref->{path}    || q{}
             , user      => $ref->{user}    || q{}
             , group     => $ref->{group}   || q{}
             , host      => $ref->{host}    || q{}
             , staging   => $ref->{staging} || q{}
             , mask      => $ref->{mask}
             };
        for my $element (@{$ref->{elements}}) {           # Iterate elements
          print {$fh} "$element\n" } } } }                #   and print onto file
  \@tar_paths }

sub exists_list {
  # Returns 1 if a given file is found in a given path.
  my ($self, $args) = @_;
  my $path      = $args->{path};
  my $filename  = $args->{filename};
  my $ls_output = `ls $path`;
  $ls_output =~ m/$filename/i ? 1 : 0 }

1
