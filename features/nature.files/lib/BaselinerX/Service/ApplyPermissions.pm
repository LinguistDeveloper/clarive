package BaselinerX::Service::ApplyPermissions;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.apply.permissions' => {name    => 'Apply Permissions',
                                         handler => \&main};

sub main
{
    my ($self, $c, $config) = @_;
    my $job = $c->stash->{job};
    my $log = $job->logger;
    unless (exists $job->job_stash->{permission_files})
    {
        $log->debug("There are no files whose permissions are to be changed.");
        return;
    }
    my @destinations = @{$job->job_stash->{permission_files}};
    for my $dest (@destinations)
    {
        my $balix = balix_unix($dest->{host});
        for my $path (keys %{$dest->{files}})
        {
            for my $file (@{$dest->{files}->{$path}})
            {
                my $cmd = qq|chmod $dest->{mask} $path/$file|;
                $log->debug("cmd: $cmd");
                $balix->executeas($dest->{user}, $cmd);
            }
        }
    }
    return;
}

# sub main {
#   my ($self, $c, $config) = @_;
#   my $job = $c->stash->{job};
#   my $log = $job->logger;
#   unless (exists $job->job_stash->{permission_files}) {
#     $log->debug("There are no files whose permissions are to be changed.");
#     return;
#   }
#   my @p_files = @{$job->job_stash->{permission_files}};
#   $log->debug('@p_files => ' . Data::Dumper::Dumper \@p_files);
#   for my $ref (@p_files) {
#     my $balix = balix_unix $ref->{host};
#     for my $file (@{$ref->{files}}) {
#       $log->debug(
#         $self->chown(
#           balix => $balix,
#           user  => $ref->{user},
#           group => $ref->{group},
#           file  => $file
#         )
#       );
#       $log->debug(
#         $self->chmod(
#           balix => $balix,
#           user  => $ref->{user},
#           file  => $file,
#           mask  => $ref->{mask}
#         )
#       );
#     }
#   }
#   return;
# }
 
# sub chown {
#   my $self    = shift;
#   my %p       = @_;
#   my $user    = $p{user};
#   my $group   = $p{group};
#   my $command = "chown ${user}:${group} $p{file}";
#   my ($rc, $ret) = $p{balix}->executeas($p{user}, $command);
#   _throw "ERROR: $command" if $rc;
#   $command;
# }
 
# sub chmod {
#   my $self    = shift;
#   my %p       = @_;
#   my $command = "chmod $p{mask} $p{file}";
#   my ($rc, $ret) = $p{balix}->executeas($p{user}, $command);
#   _throw "ERROR: $command" if $rc;
#   $command;
# }
 
1;
