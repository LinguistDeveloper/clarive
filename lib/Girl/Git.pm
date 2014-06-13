package Girl::Git;
use Any::Moose;
#use Git::Repository;
use Encode qw( decode_utf8 encode_utf8 is_utf8 );
use namespace::autoclean;
use Baseliner::Utils;

has dir  => qw(is ro isa Path::Class::Dir required 1);
has bare => qw(is ro isa Bool required 1);
has git  => qw(is ro isa Git::Wrapper required 1),
            handles => [qw/command/];

around BUILDARGS => sub {
    use Path::Class;
    my $orig = shift;
    my $self = shift;
    my %args = @_;
    if( my $gdir = delete $args{git_dir} ) {
        #$args{git} = Git::Repository->new( git_dir => $gdir );
        $args{git} = Git::Wrapper->new( $gdir );
        $args{dir} = dir( $gdir );
        $args{bare} = 1;
    }
    elsif( my $wdir = delete $args{work_tree} ) {
        #$args{git} = Git::Repository->new( work_tree => $wdir );
        $args{git} = Git::Wrapper->new( $wdir );
        $args{dir} = dir( $wdir );
        $args{bare} = 0;
    }
    $self->$orig( %args );
};

sub refs {
    my $self = shift;
    map {
        my @f = split /\s+/, substr $_, 1; # throw away the first column
        +{ name=>$f[1], id=>$f[2] }
    } $self->exec( qw/branch --no-abbrev -v/, @_ );
}

=head2 exec

Runs a command, dies on error. Chomps lines on success. 
Returns a list.

=cut
sub exec {
    my $self = shift;
    my $git_cmd = ( defined $ENV{GIT_WRAPPER_GIT} ) ? $ENV{GIT_WRAPPER_GIT} : 'git';
    my $opts = ref $_[ $#_ ] ? pop @_ : {};

    # TODO set work-tree  
    my $cmd;
    if( $opts->{cmd_unquoted} ) {
        $cmd = sprintf q{"%s" --git-dir '%s' %s}, $git_cmd,$self->dir, join ' ', @_;
    } else {
        my $quoted = join ' ', map { my $s = $_; $s =~ s/"/\\"/g; '"'.$s.'"' } @_; 
        $cmd = sprintf q{"%s" --git-dir '%s' %s}, $git_cmd,$self->dir, $quoted;
    }
    _debug "Running GIT command ".$cmd;
    #my @lines = `$cmd`;
    require IO::CaptureOutput;
    my ($stdout,$stderr);
    my $rc;
    IO::CaptureOutput::capture( sub {
        system $cmd;
        $rc = $?;
    }, \$stdout, \$stderr );
    #my @lines = $self->git->_cmd( @_ );
    my @lines = split /\n/, $stdout; 
    #chomp @lines unless $opts->{no_chomp};
    if( $rc ) {
        my $err_msg = sprintf "Error running git command %s: %s", $cmd, $stderr . "\n" . join('',@lines );
        return () if $opts->{on_error_empty};
        Carp::confess( $err_msg );
    }
    @lines = map { _to_utf8_git( $_ ) } @lines unless $opts->{no_encode};
    return wantarray ? @lines : ( @lines > 1 ? \@lines : $lines[0] );
}

sub run {
    my ($self, $cmd, @parms) = @_;
    $cmd =~ s/-/_/g;
    return map { _to_utf8_git($_) } $self->git->$cmd( @parms ); 
}

sub _to_utf8_git {
    my $str = shift;
    return undef unless defined $str;
    my $fallback_encoding = 'latin1';
    if ( utf8::valid($str) ) {
        utf8::decode($str);
        return $str;
    } else {
        return Encode::decode( $fallback_encoding, $str, Encode::FB_DEFAULT );
    }
}

1;
