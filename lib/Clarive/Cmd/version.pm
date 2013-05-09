package Clarive::Cmd::version;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'report our version';

sub run {
    my ($self)=@_;
    my $v = $self->get_version_string;
    say sprintf "clarive version %s (sha %s)", @{ ref $v ? $v : [$v,$v] } ;
}

sub get_version_string {
    my $self = shift;
    my $v = eval { 
        require Git::Wrapper;
        my $git = Git::Wrapper->new( $self->home );
        my $x = ( $git->describe({ always=>1, tag=>1 }) )[0];
        $x =~ /^(.*)-(\d+)-(.*)$/ and $x=["$1_$2", substr($3,1,7) ];
        $x;
    };
    $@ ?  ['6.0','??'] : $v;
};


1;
