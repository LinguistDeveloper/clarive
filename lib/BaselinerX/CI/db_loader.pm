package BaselinerX::CI::db_loader;
use Baseliner::Moose;
use Path::Class;
use namespace::clean;

has include    => qw(is ro isa ArrayRef), default => sub { [] };
has exclude    => qw(is ro isa ArrayRef), default => sub { [] };
has is_loaded  => qw(is rw isa Bool default 0);

with 'Baseliner::Role::CI::Loader';

sub run_load {
}
sub has_bl { 0 }


1;


