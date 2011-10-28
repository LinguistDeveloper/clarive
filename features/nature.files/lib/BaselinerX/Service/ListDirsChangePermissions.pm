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

  for my $ref (@{$tar_list}) {
    next if $ref->{os} =~ /win/;    # Permissions in Windows do not apply here

    my $balix = balix_unix $ref->{host};
    my $from  = $ref->{path_from};
    my $to    = $ref->{path_to};
    my @lines = @{$self->_read_file("${from}/new_elements")};

    my @paths = unique map { $_ =~ m/(.+)\// } @lines;

    my @data;    # The AoH to be inserted into the job stash.

    # Create the folders that will be distributed so the permissions apply.
    for my $path (@paths) {
      $path = "${to}/${path}";
      # $path =~ s/\/\//\//g;
      my $command = "mkdir -p $path";
      $log->debug($command);
      my ($rc, $ret) = $balix->executeas($ref->{user}, $command);
      if ($rc) {
        $log->debug("cmd output: $ret");
        my $err_msg = "Error during $command";
        $log->error($err_msg);
        _throw($err_msg);
      }
    }
    my @black_list = map { $_ =~ m/$to\/(.+)/ } @paths;

    for my $dir (@black_list) {
      if ($dir =~ m/\S/xi) {  # Don't do this for whitespace...
        my $command = "ls -la ${to}/${dir}";
        $log->debug("exec: $command");

        my ($rc, $ret) = $balix->executeas($ref->{user}, $command);

        #_throw("Something went wrong: $ret") if $rc;
        my @result = split('\n', $ret);

        for my $line (@result) {
          my ($permissions, $element) = 
            $line =~ m{
                       (.+?)     # Capture first element
                       \s.+\s    # Ignore everything in between
                       (.+)      # Capture last element
                      }x;
          # If it doesn't have 's' byte and is the father '.' ...
          if ($permissions !~ /'s'/ and $element eq '.') { 
            # my $cmd = "find $dir -type f";
            my $cmd = "find $to$dir -type f";
            $log->debug("exec: $cmd");
            ($rc, $ret) = q{};
            ($rc, $ret) = $balix->executeas($ref->{user}, $cmd);

            my @files = split('\n', $ret);
 
            my $href;
            for my $file (@files) {            # For every file
              if ($file =~ m/$dir\/(.+)/i) {   # | check if is being distributed
                unless ($1 =~ m/\//) {         # | and is not in a subfolder
                  $href->{user}  = $ref->{user};
                  $href->{group} = $ref->{group};
                  $href->{host}  = $ref->{host};
                  $href->{mask}  = $ref->{mask};
                  push @{$href->{files}}, "${to}${dir}/${1}";
                }
              }
            }
            push @data, $href;
          }
        }
      }
    }
    $log->debug('@data => ' . Dumper \@data);    # XXX
    $job->job_stash->{permission_files} = \@data;
  }
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
