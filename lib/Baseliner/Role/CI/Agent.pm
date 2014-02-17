package Baseliner::Role::CI::Agent;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/ci/agent.png' }

use Moose::Util::TypeConstraints;

has user        => qw(is rw isa Str);
has password    => qw(is rw isa Str);

has server => qw(is rw isa CI required 1),
    traits => ['CI'],
    handles=>[qw(remote_temp remote_perl remote_tar hostname)];
    
around rel_type => sub {
    { 
        server => [ to_mid => 'server_agent' ] ,
    };
};
has timeout => qw(is rw isa Maybe[Num|Str] default 0);  # timeout for executes, send_file, etc., disabled by default

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
has os => qw(default unix lazy 1 required 1 is rw isa), enum [qw(unix win mvs)];

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

sub is_win { $_[0]->os eq 'win' }
sub is_unix { $_[0]->os eq 'unix' }
sub is_mvs { $_[0]->os eq 'mvs' }

sub normalize_path {
    my($self,$path) = @_;
    return "$path" if !length $self->os || $self->is_unix;
    my $p = Util->_file( $path );
    return ''.$p->as_foreign('Win32') if $self->is_win;
    return "$path";  # mvs?
}

sub tuple {
    my ($self)=@_;
    { ret=>$self->ret, output=>$self->output, rc=>$self->rc };
}

sub tuple_str {
    my ($self)=@_;
    my $t = $self->tuple;
    delete $t->{ret} if $t->{ret} eq $t->{output};
    sprintf "RC=%s\nRET: %s\nOUTPUT:\n%s\n", $t->{rc}, $t->{ret}, $t->{output} ;
}

sub _quote_cmd {
    my $self = shift;
    map { ref $_ eq 'SCALAR' ? $$_ : "'$_'"; } @_;
}

sub _double_quote_cmd {
    my $self = shift;
    map { ref $_ eq 'SCALAR' ? $$_ : "\"$_\""; } @_;
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


