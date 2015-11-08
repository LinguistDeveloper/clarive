package Baseliner::Role::Palette;
use Moose::Role;

has id             => ( is => 'rw', isa => 'Str', default => '' );
has text           => ( is => 'rw', isa => 'Str' );
has type           => ( is => 'rw', isa => 'Str' );
has holds_children => ( is => 'rw', isa => 'Bool', default => 1 );
has show_in_palette=> ( is => 'rw', isa => 'Bool', default => 1 );
has nested         => ( is => 'rw', isa => 'Bool', default => 0 );
has dsl            => ( is => 'rw', isa => 'CodeRef', required => 1 );
has form           => ( is => 'rw', isa => 'Str', default => '' );
has data           => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has config         => ( is => 'rw', isa => 'Str' );
has icon           => ( is => 'rw', isa => 'Str' );
has on_drop_js     => ( is => 'rw', isa => 'Str' );
has on_drop        => ( is => 'rw', isa => 'CodeRef' );
has sub_name       => ( is => 'rw', isa => 'Str' );
has sub_mode       => ( is => 'rw', isa => 'Str', default=>'none' );
has has_shortcut   => ( is => 'rw', isa => 'Bool', default=>0 );
has data_gen    => ( is => 'rw', isa => 'CodeRef');

1;
