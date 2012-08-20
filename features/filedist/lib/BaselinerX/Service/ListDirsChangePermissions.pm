package BaselinerX::Service::ListDirsChangePermissions;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use File::Slurp;

with 'Baseliner::Role::Service'; 

register 'service.list.dirs.change.permissions' => 
           {name    => 'Change Permissions',
            handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my $tar_list = $job->job_stash->{tar_list};

  for my $ref (@{$tar_list}) {
    my $balix      = balix_unix $ref->{host};
    my $from       = $ref->{path_from};
    my $to         = $ref->{path_to};
    my @lines      = @{$self->read_file("${from}/new_elements")};
    my @paths      = kill_duplicates([map { $_ =~ m/(.+)\// } @lines]);
    my @data;      # The AoH to be inserted into the job stash.

    # Create the folders that will be distributed so the permissions apply.
    for my $path (@paths) { 
      $path = "${to}/${path}";
      my $command = "mkdir -p $path";
      my ($rc, $ret) = $balix->executeas($ref->{user}, $command);
      $log->debug($command);
      _throw ("Error during $command") if $rc; }

    my @black_list = map { $_ =~ m/$to\/(.+)/ } @paths;                  

    for my $dir (@black_list) {
      my $command = "ls -la ${to}/${dir}";
      my ($rc, $ret) = $balix->executeas($ref->{user}, $command);
      my @result     = split('\n', $ret);
      for my $line (@result) {
        my ($permissions 
           ,$element) = $line =~ m/
                                   (.+?)  # Capture first element
                                   \s.+\s # Ignore everything in between
                                   (.+)   # Capture last element
                                   /x;
        if ($permissions !~ /'s'/      # If it doesn't have 's' byte
              and $element eq '.') {   #   and is root...
          ($rc, $ret) = $balix->executeas($ref->{user}, "find $dir -type f");
          my @files = split('\n', $ret);
          for my $file (@files) {           # For every file
            if ($file =~ m/$dir\/(.+)/i) {  # | check if is being distributed
              unless ($1 =~ m/\//) {        # | and is not in a subfolder
                my $href;
                $href->{user}  = $ref->{user};
                $href->{group} = $ref->{group};
                $href->{host}  = $ref->{host};
                $href->{mask}  = $ref->{mask};
                push @{$href->{files}}, "${to}/${dir}/${1}";
                push @data, $href; } } } } } }

    $job->job_stash->{permission_files} = \@data; }
  return }

sub read_file {
  my ($self, $file) = @_;
  open (F, $file) || _throw "Could not open $file: $!";
  my @lines = <F>;
  close F;
  \@lines }

1
