package BaselinerX::Type::Provider;
use Moose;
use Baseliner::Core::Registry ':dsl';
with 'Baseliner::Role::Registrable';

register_class 'provider' => __PACKAGE__;

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'name' => ( is=> 'rw', isa=> 'Str' );
has 'desc' => ( is=> 'rw', isa=> 'Str' );
has 'list' => ( is=> 'rw', isa=> 'CodeRef' );
has 'config' => ( is=> 'rw', isa=> 'Str' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 DESCRIPTION

Class for a registerable namespace provider.

=cut
