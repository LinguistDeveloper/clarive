package BaselinerX::Type::Form;
use Moose;
use Baseliner::Core::Registry ':dsl';
with 'Baseliner::Role::Registrable';

register_class 'form' => __PACKAGE__;

has name 	=> ( is=> 'rw', isa=> 'Str' );
has desc 	=> ( is=> 'rw', isa=> 'Str' );
has metadata => ( is=> 'rw', isa=> 'ArrayRef' );  ##TODO this shall be a Moose subtype someday, an array of ConfigColumn
has formfu 	=> ( is=> 'rw', isa=> 'ArrayRef', default=> sub { [] } );
has 'plugin' => (is=>'rw', isa=>'Str', default=>'');
has 'id' => (is=>'rw', isa=>'Str', default=>'');

1;

=head1 SYNTAX

    register 'form.test.movies' => {
        table => 'tab',
        primary_key => 'formobjid',

    };

=cut
