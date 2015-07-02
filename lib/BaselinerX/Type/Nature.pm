package BaselinerX::Type::Nature;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use utf8;
use experimental 'smartmatch';
with 'Baseliner::Role::Registrable';

register_class 'nature' => __PACKAGE__;

has 'id',   is => 'rw', isa => 'Str', default => '';
has 'name', is => 'rw', isa => 'Str';
has 'ns',   is => 'rw', isa => 'Str';
has 'icon',   is => 'rw', isa => 'Str', default => sub { shift->key };

sub can_i_haz_nature { # ArrayRef -> Bool
  my ($self, $elements) = @_;
  my @all_natures =
    keys %{{map { $_->{path} =~ /\/\w+\/(.\w+)/ => 1 } @{$elements}}};
  $self->name ~~ @all_natures ? 1 : 0;
}

1;
