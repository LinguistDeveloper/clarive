package BaselinerX::Service::RemoveItems;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Dist::Utils;
use Data::Dumper;

with 'Baseliner::Role::Service';

register 'service.remove.items' => {
  name    => 'Process Elements',
  handler => \&main
};

### main : Self Ref Ref -> Undef
sub main {
  my ($self, $c, $config) = @_;
  my $job = $c->stash->{job};
  my $log = $job->logger;

  exists $job->stash->{win_del_elements}
    ? $self->rem_win($job->stash->{win_del_elements}, $log)
    : $log->debug("No Windows elements to be deleted.");
    
  exists $job->stash->{unix_del_elements}
    ? $self->rem_unix($job->stash->{unix_del_elements}, $log)
    : $log->debug("No UNIX elements to be deleted.");

  return;
}

### win_elements : Self Int -> ArrayRef[HashRef]
sub win_elements {
  my ($self, $job) = @_;
  Baseliner->model('Distribution')->del_win_elements($job);
}

### unix_elements : Self Int -> ArrayRef[HashRef]
sub unix_elements {
  my ($self, $job) = @_;
  Baseliner->model('Distribution')->del_unix_elements($job);
}

### get_map : Self ArrayRef -> ArrayRef[HashRef]
sub get_map {
  my ($self, $l_elems) = @_;
  my @del_elements = @{$l_elems};
  my %kv           = %{Baseliner->model('Distribution')->get_maps()};
  my @data;

  for my $dir (keys %kv) {
    for my $mapping (@{$kv{$dir}}) {
      my @elements = map { $_->{fullpath} =~ m/$dir\/(.+)/ }
        grep($_->{fullpath} =~ m/^$dir/i, @del_elements);
      if (@elements) {
        my $hashref = {
          host => $mapping->{host},
          os   => $mapping->{os},
          path => $mapping->{path},
          stgn => $mapping->{staging},
          user => $mapping->{user}
        };
        push @{$hashref->{items}}, @elements;
        push @data, $hashref;
      }
    }
  }
  \@data;
}

### rem_win : Self ArrayRef[HashRef] Object -> Undef
sub rem_win {
  my ($self, $l, $log) = @_;
  my @elements = @{$l};
  for my $href (@elements) {
    my $balix = balix_win($href->{host});
    for my $item (windir(@{$href->{items}})) {
      my $cmd = "del /Q /F \"$href->{path}\\${item}\"";
      $log->debug($cmd);
      my ($rc, $ret) = $balix->execute($cmd);
      _throw "Error at $cmd : File not found!" if $rc;
    }
  }
  return;
}

### rem_unix : Self ArrayRef[HashRef] Object -> Undef
sub rem_unix {
  my ($self, $l, $log) = @_;
  my @elements = @{$l};

  for my $href (@elements) {
    my $balix = balix_unix($href->{host});
    for my $item (@{$href->{items}}) {
      $item = "$href->{path}/${item}";

      # Throw if element does not exist.
      my $cmd = "[ -f $item ] echo 0 || echo 1";
      my ($rc, $ret) = $balix->executeas($href->{user}, $cmd);
      _throw "Cannot delete. File $item not found" if $rc or $ret;

      # Delete file.
      $cmd = "rm -rf $item";
      $log->debug($cmd);
      $rc, $ret = $balix->executeas($href->{user}, $cmd);
      _throw "Cannot delete ${item}, unknow error." if $rc;
    }
  }
  return;
}

1
