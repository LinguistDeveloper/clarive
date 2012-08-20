package Baseliner::Role::Namespace::PackageGroup;
use Moose::Role;

with 'Baseliner::Role::Namespace::Tag';
with 'Baseliner::Role::Transition';
with 'Baseliner::Role::Baselined';
with 'Baseliner::Role::Container';

requires 'created_on';
requires 'created_by';

requires 'bind';   # do they must travel together?

has 'icon_on'  => ( is=>'rw', isa=>'Str', default=> '/static/images/scm/packages.gif' ); 
has 'icon_off' => ( is=>'rw', isa=>'Str', default=> '/static/images/scm/packages_off.gif' );

=head1 DESCRIPTION

Something that groups packages together.

Tipically not approvable.

=cut

1;

