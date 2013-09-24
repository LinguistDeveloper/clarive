package Baseliner::Role::CI::Agent;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/ci/agent.png' }

use Moose::Util::TypeConstraints;

has user        => qw(is rw isa Str);
has password    => qw(is rw isa Str);
has os          => qw(is rw isa Str default unix);
has remote_temp => qw(is rw isa Any lazy 1), default => sub {
    my $self = shift;
    return $self->os eq 'win' ? 'C:\TEMP' : '/tmp';
};
has remote_perl => qw(is rw isa Str default perl);

with 'Baseliner::Role::ErrorThrower';

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

sub tuple {
    my ($self)=@_;
    { ret=>$self->ret, output=>$self->output, rc=>$self->rc };
}

sub tuple_str {
    my ($self)=@_;
    my $t = $self->tuple;
    sprintf "RET=%s\nRC=%s\nOUTPUT:\n%s\n", $t->{ret}, $t->{rc}, $t->{output} ;
}

sub _quote_cmd {
    my $self = shift;
    join ' ', map {
        ref $_ eq 'SCALAR' ? $$_ : "'$_'";
    } @_;
}

sub fatpack_perl_code {
    my ($self, $code)=@_;
    my $claw_file = Baseliner->path_to( 'bin/cla-worker' );
    my $claw = scalar $claw_file->slurp;
    if( my ($fp) = $claw =~ /^(.*END OF FATPACK CODE).*$/s ) {
        return $fp . "\n\n" . $code;         
    } else {
        Util->_fail( Util->_loc( 'Error trying to fatpack perl code. Could not find fatpack code in `%1`', $claw_file) );
    }
}

1;


