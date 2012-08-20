package Baseliner::Role::Namespace::Package;
use Moose::Role;

with 'Baseliner::Role::Namespace::Tag';
with 'Baseliner::Role::Approvable';
with 'Baseliner::Role::Transition';
with 'Baseliner::Role::Baselined';

requires 'created_on';
requires 'created_by';

has 'icon_on'  => ( is=>'rw', isa=>'Str', default=> '/static/images/scm/package.gif' ); 
has 'icon_off' => ( is=>'rw', isa=>'Str', default=> '/static/images/scm/package_off.gif' );

=head1 DESCRIPTION

Just like a tag, but that can be promoted, demoted, approved, etc..

=cut

1;
