package Baseliner::Role::CI::Agent;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/ci/agent.png' }

use Moose::Util::TypeConstraints;

requires 'put_file';
requires 'get_file';
requires 'put_dir';
requires 'get_dir';
requires 'mkpath';
requires 'rmpath';
requires 'chmod';

requires 'execute';

=head2 os

Operating system of the file system.

Values: Unix o Win32

Default: Unix

=cut
has os => qw(default Unix lazy 1 required 1 is rw isa), enum [qw(Win32 Unix)];

=head2 mkpath_on

Create full path to file/dir if it doesn't exist.

Default: true

=cut
has mkpath_on    => qw(is ro isa Bool default 1);

=head2 overwrite_on

Overwrite remote files. Replace full directories. 

Default: true

=cut
has overwrite_on => qw(is ro isa Bool default 1);

has copy_attrs => qw(is ro isa Bool default 0);

1;


