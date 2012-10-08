package BaselinerX::Job::Service::MakeLdifBackups;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.baseliner.bde.make-ldif-backups' => {
  name    => 'Manages and creates backups for ldif files',
  handler => \&make_backups
};

sub logf { 
  _log "MakeLdifBackups :: ", @_;
  `$_[0]`;
}

sub make_backups {
  my ($self, $c, $config) = @_;
  my $backup_home = $config->{backup_home};
  my $files_home  = $config->{files_home};
  my @filenames   = @{$config->{filenames}};
  my $init        = 0;
  my $limit       = 5;
  try {
  	create_dirs($backup_home, $init, $limit);
  }
  catch {
  	notify_ldif_error "Ldif Backups :: Error al crear directorios.";
  };
  try {
    move_forward($backup_home, $limit, $init, $limit);	
  }
  catch {
  	notify_ldif_error "Ldif Backups :: Error al rotar ficheros de backup entre directorios";
  };
  # Backup files to newest version.
  logf $_ for map { "mv $files_home/$_ $backup_home/.last/" } @filenames;
  return;
}

sub create_dirs {
  # Creates as many directories from <current> to <init>.
  my ($backup_home, $current, $limit) = @_;
  return if $current > $limit;
  my $dir = transform_backup_dir($backup_home, ".last$current");
  my $cmd = "mkdir -p $dir";
  logf $cmd;
  create_dirs($backup_home, $current + 1, $limit);
}

sub move_forward {
  # Moves the files from .last{n} to .last{n + 1} and deletes files
  # from .last{<init>} and .last{<end>}.
  my ($backup_home, $current, $init, $limit) = @_;
  return if $current < $init;
  my $next = sub { move_forward($backup_home, $current - 1, $init, $limit) };
  my $backup_dir = transform_backup_dir($backup_home, ".last$current");
  $next->() unless dir_has_files_p $backup_dir;  # nothing to do here
  if ($current != $limit) {
  	my $next_dir = increase_dir($backup_dir);
  	my $cmd      = "mv $backup_dir/* $next_dir/";
  	logf $cmd;
  }
  if ($current == $init || $current == $limit) {
  	delete_files_in_dir($backup_dir);
  }
  $next->();
}

sub transform_backup_dir { # Array[Str] -> Str
  # Builds up the directory and gets rid of the zero in .last0
  my $dir = join '/', @_;
  $dir =~ s/0$//;
  $dir;
}

sub increase_dir { # Str -> Str
  # Returns the given directory version increased by one.
  my ($dir) = @_;
  my $last_char = substr($dir, length($dir) - 1, 1);
  return "${dir}1" unless intp $last_char;
  substr($dir, 0, length($dir) - 1) . ($last_char + 1);
}

sub delete_files_in_dir { # Str -> Undef
  # Deletes all the files from the given directory.
  my ($dir) = @_;
  my $cmd = "rm -rf $dir/*";
  logf $cmd;
  return;
}

1;

__END__

=head1 USAGE

  $c->launch('service.baseliner.bde.make-ldif-backups',
  	         data => {backup_home => '/home/apst/scm/ldif_backup_files',
  	                  files_home  => '/home/apst/scm/ldif_files',
  	                  filenames   => [qw/a.ext b.ext c.ext etc/]});

=head2 transform_backup_dir

  transform_backup_dir '/home/apst/scm', '.last0';
  #=> /home/apst/scm/.last
  
  transform_backup_dir '/home/apst/scm', '.last2';
  #=> /home/apst/scm/.last2

=head2 increase_dir

  increase_dir 'home/apst/backup/.last';
  #=> home/apst/backup/.last1
  
  increase_dir 'home/apst/backup/.last2';
  #=> home/apst/backup/.last3
  
=cut
