package Clarive::Cmd;
use Mouse;

has app => qw(is ro required 1);

has opts   => qw(is ro isa HashRef default), sub{ +{} };

has home       => qw(is rw default) => sub { $ENV{CLARIVE_HOME} // '.' };
has debug      => qw(is rw default) => sub { 0 };
has trace      => qw(is ro default) => sub { 0 };
has lang       => qw(is ro default) => sub { 'en_US.UTF-8' };
has nls_lang   => qw(is ro default) => sub { 'AMERICAN_AMERICA.UTF8' };

sub BUILD {
    my $self = shift;
    
    # LANG to UTF-8
    $ENV{LANG} = $ENV{BASELINER_LANG} || $self->lang;
    $ENV{NLS_LANG} = $ENV{BASELINER_NLS_LANG} || $self->nls_lang;

    # debug ? 
    #
    
    if( defined $self->opts->{d} || $ENV{BASELINER_DEBUG} ) {
        $self->debug(1);
    }
}

1;
