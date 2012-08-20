package BaselinerX::Service::GenerateFileLists;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.generate.file.lists' => {name    => 'Generate File Lists',
                                           handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job               = $c->stash->{job};
  my $log               = $job->logger;
  my $job_id            = $job->{jobid};
  my $path              = $job->job_stash->{path};
  my $kv                = $job->job_stash->{kv};
  my $win_tar_elements  = $job->job_stash->{win_tar_elements}  || {};
  my $unix_tar_elements = $job->job_stash->{unix_tar_elements} || {};
  my $win_del_elements  = $job->job_stash->{win_del_elements}  || {};
  my $unix_del_elements = $job->job_stash->{unix_del_elements} || {};
  my @tar_paths;
  my @del_elements;
  my $map_log;

  if (keys %$win_tar_elements) {
    my $data = $self->generate({path => $path,
                                os   => 'win',
                                type => 'new',
                                map  => $win_tar_elements},
                               $log);
    push @tar_paths, @{$data}, if @{$data};
    $map_log .= "# Nuevos elementos Windows #\n\n";
    $map_log .= $self->build_log($win_tar_elements) . "\n\n";
  }
  else {
    $log->debug("No Windows elements to be distributed.");
  }

  if (keys %$win_del_elements) {
    my $del = $self->generate({path => $path,
                               os   => 'win',
                               type => 'old',
                               map  => $win_del_elements},
                              $log);
    push @del_elements, @{$del} if @{$del};
    $map_log .= "# Elementos Windows a borrar #\n\n";
    $map_log .= $self->build_log($win_del_elements) . "\n\n";
  }
  else {
    $log->debug("No Windows elements to be deleted.");
  }

  if (keys %$unix_tar_elements) {
    my $data = $self->generate({path => $path,
                                os   => 'unix',
                                type => 'new',
                                map  => $unix_tar_elements},
                               $log);
    push @tar_paths, @{$data} if @{$data};
    $map_log .= "# Nuevos elementos UNIX #\n\n";
    $map_log .= $self->build_log($unix_tar_elements) . "\n\n";
  }
  else {
    $log->debug("No UNIX elements to be distributed.");
  }

  if (keys %$unix_del_elements) {
    my $del = $self->generate({path => $path,
                               os   => 'unix',
                               type => 'old',
                               map  => $unix_del_elements},
                              $log);
    $map_log .= "# Elementos UNIX a borrar n\n";
    $map_log .= $self->build_log($unix_del_elements) . "\n\n";
    push @del_elements, @{$del} if @{$del};
  }
  else {
    $log->debug("No UNIX elements to be deleted.");
  }

  $log->info("Mapeo de ficheros a distribuir ==> ", $map_log);

  $job->job_stash->{tar_list}     = \@tar_paths;
  $job->job_stash->{del_elements} = \@del_elements;
  return;
}

sub generate {
  my ($self, $args, $log) = @_;
  my $path = $args->{path};
  my $type = $args->{type};
  my $os   = $args->{os};
  my %map  = %{$args->{map}};
  my $file = "${type}_elements";
  my @tar_paths;
  for my $key (keys %map) {                        # for every HashRef...
    for my $ref (@{$map{$key}}) {                  # iterate each key (which is also the origin path)
      unless ($self->exists_list($path, $file)) {  # Unless we have a file:
        open my $fh, '>', "$path/$key/$file";      # Open file
        push @tar_paths, 
             { os        => $os
             , path_from => "$path/$key"
             , path_to   => $ref->{path}    || q{}
             , user      => $ref->{user}    || q{}
             , group     => $ref->{group}   || q{}
             , host      => $ref->{host}    || q{}
             , staging   => $ref->{staging} || q{}
             , mask      => $ref->{mask}    || q{}
             };
        for my $element (@{$ref->{elements}}) {  # Iterate elements
          print {$fh} "$element\n";              # and print onto file

#          # Also log it, just in case...
#          $log->debug($type eq 'new' ? "Distribute: $element ($os)" 
#                                     : "Delete: $element ($os)");
        }
      }
    }
  }
  \@tar_paths;
}

sub exists_list { # Str Str -> Bool
  # Returns true if a given file is found in a given path.
  my ($self, $path, $filename) = @_;
  my $ls_output = `ls $path`;
  $ls_output =~ m/$filename/i ? 1 : 0;
}

sub build_log {  # HashRef -> Str
  my ($self, $data) = @_;
  my $log;
  for my $origin (keys %{$data}) {
    $log .= "Origen: $origin\n";
    for my $array_ref ($data->{$origin}) {
      for my $hash_ref (@{$array_ref}) {
        $log .= "Host de destino: $hash_ref->{host}\n";
        $log .= "Path: $hash_ref->{path}\n";
        $log .= "Staging: $hash_ref->{st}\n" if exists $hash_ref->{st};
        $log .= "Sistema operativo: ";
        $log .= $hash_ref->{os} eq 'win' ? "Windows\n" : "UNIX\n";
        $log .= "Usuario: $hash_ref->{user}\n" if exists $hash_ref->{user};
        $log .= "Grupo: $hash_ref->{group}\n" if exists $hash_ref->{group};
        $log .= "Permisos: $hash_ref->{mask}\n" if exists $hash_ref->{mask};
        $log .= "Elementos: \n";
        for my $element (@{$hash_ref->{elements}}) {
          $log .= "  - $element\n";
        }
      }
      $log .= "\n\n";
    }
  }
  return $log;
}


1;
