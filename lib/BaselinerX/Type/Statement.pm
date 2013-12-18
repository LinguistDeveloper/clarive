package BaselinerX::Type::Statement;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Registrable';

register_class 'statement' => __PACKAGE__;
sub service_noun { 'statement' }

has id             => ( is => 'rw', isa => 'Str', default => '' );
has text           => ( is => 'rw', isa => 'Str' );
has type           => ( is => 'rw', isa => 'Str' );
has holds_children => ( is => 'rw', isa => 'Bool', default => 1 );
has nested         => ( is => 'rw', isa => 'Bool', default => 0 );
has dsl            => ( is => 'rw', isa => 'CodeRef', required => 1 );
has form           => ( is => 'rw', isa => 'Str', default => '' );
has data           => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has config         => ( is => 'rw', isa => 'Str' );
has icon           => ( is => 'rw', isa => 'Str' );

1;
