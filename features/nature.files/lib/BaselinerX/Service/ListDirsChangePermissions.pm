package BaselinerX::Service::ListDirsChangePermissions;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use Data::Dumper;
use File::Slurp;

with 'Baseliner::Role::Service';

register 'service.list.dirs.change.permissions' => {
  name    => 'Change Permissions',
  handler => \&main
};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};

  my @data;    # The AoH to be inserted into the job stash.

  for my $ref (@{$tar_list}) {
    next if $ref->{os} =~ /win/;    # Permissions in Windows do not apply here

    my %files_for_host;

    my $balix = balix_unix $ref->{host};
    my $from  = $ref->{path_from};
    my $to    = $ref->{path_to};
    my @relative_paths = map { chomp($_); $_ } @{$self->_read_file("$from/new_elements")};
    my @absolute_paths = map { my $d = "$to/$_"; $d =~ s/\/\//\//g; $d } @relative_paths;

    # Build the hash dir_file, where the key is the directory and its values
    # are the files contained in an ArrayRef.
    my %dir_file;
    for my $path (@absolute_paths) {
      $path =~ m/(.+)\/(.+)/g;
      push @{$dir_file{$1}}, $2;
    }

    # For every directory contained in the hash (which is unique), let's
    # create it on host so the permissions are applied.
    $balix->executeas($ref->{user}, "mkdir -p $_") for keys %dir_file;

    # Now, iterate every directory and check whether it has this sticky bit
    # thingy...
    for my $dir (keys %dir_file) {
      my $cmd = qq|ls -la $dir|;
      my ($rc, $ret) = $balix->executeas($ref->{user}, $cmd);

      # Build a list out of the result.
      my @list = split('\n', $ret);

      my $href;
      for my $element (@list) {
        # Pick the permissions and the element name (either a directory or a
        # file).
        my ($permissions, $element) = 
          $element =~ m{
                        (.+?)     # Capture first element
                        \s.+\s    # Ignore everything in between
                        (.+)      # Capture last element
                       }x;

        # Check if the element is root '.' (the only one that matters) and
        # whether it has sticky bit...
        if ($element eq '.') {  # Less expensive than using &&.
          unless ($permissions =~ m/s|t/i) {  # It can be [s, S, t, T].

            # This means this directory doesn't have the sticky bit, therefore
            # we shall change its permissions.
            push @{$files_for_host{$dir}}, @{$dir_file{$dir}};
          }
        }
      }
    }

    # At the end of all this, if we have some files whose attributes are to be
    # changed, this means we can push onto the array of hashes (with as many
    # hashes as hosts) that the service for applying permissions will use.
    if (scalar keys %files_for_host) {
      push @data, {user  => $ref->{user},
                   group => $ref->{group},
                   host  => $ref->{host},
                   mask  => $ref->{mask},
                   files => \%files_for_host};
    }
  }
  $job->job_stash->{permission_files} = \@data;

  return;
}

sub _read_file {
  my ($self, $file) = @_;
  open(F, $file) || _throw "Could not open $file: $!";
  my @lines = <F>;
  close F;
  \@lines;
}

1;

__DATA__

=head2 Ejemplo de Output

  $VAR1 = [
            {
              'group' => 'gtsct',
              'files' => {
                           '/tmp/prueba' => [
                                              'RESTORE_UNIX_9.txt',
                                              'RESTORE_UNIX_8.txt',
                                              'RESTORE_UNIX_7.txt',
                                              'RESTORE_UNIX_6.txt',
                                              'RESTORE_UNIX_5.txt'
                                            ]
                         },
              'user' => 'vtsct',
              'mask' => '755',
              'host' => 'PRUSVC61'
            },
            {
              'group' => 'gtsct',
              'files' => {
                           '/home/grpt/sct/pruebaSINherencia' => [
                                                                   'RESTORE_UNIX_9.txt',
                                                                   'RESTORE_UNIX_8.txt',
                                                                   'RESTORE_UNIX_7.txt',
                                                                   'RESTORE_UNIX_6.txt',
                                                                   'RESTORE_UNIX_5.txt'
                                                                 ]
                         },
              'user' => 'vtsct',
              'mask' => '755',
              'host' => 'PRUSVC61'
            }
          ];

=cut

