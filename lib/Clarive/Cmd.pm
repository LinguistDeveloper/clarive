package Clarive::Cmd;
use Mouse;

has app => qw(is ro required 1), handles=>['lang', 'env', 'home', 'debug'];

has opts   => qw(is ro isa HashRef required 1);

sub BUILD {
    my $self = shift;
    
    # LANG to UTF-8
    $ENV{LANG} = $self->lang;

    # debug ? 
    #
    
    if( defined $self->opts->{d} || $ENV{BASELINER_DEBUG} ) {
        $self->debug(1);
    }
}

1;
