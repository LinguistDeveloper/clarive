package Baseliner::Role::Namespace::Release;
use Moose::Role;

with 'Baseliner::Role::Namespace::Tag';
with 'Baseliner::Role::Approvable';
with 'Baseliner::Role::Transition';
with 'Baseliner::Role::Baselined';
with 'Baseliner::Role::Container';

requires 'created_on';
requires 'created_by';

has 'icon_on'  => ( is=>'rw', isa=>'Str', default=> '/static/images/scm/release.gif' ); 
has 'icon_off' => ( is=>'rw', isa=>'Str', default=> '/static/images/scm/release_off.gif' );

=head1 DESCRIPTION

Release works just like a package

=cut

requires 'locked';
requires 'locked_reason';

1;

