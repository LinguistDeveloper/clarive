package Baseliner::IdenticonGenerator;
use Moose;

use Try::Tiny;
use Image::Identicon;
use Baseliner::Utils qw(_file);

has default_icon => qw(is ro required 1);

sub identicon {
    my $self = shift;

    return try {
        $self->_generate;
    }
    catch {
        my $user_png = _file( $self->default_icon );
        $user_png->slurp;
    };
}

sub _generate {
    my $self = shift;

    my $salt = '1234';
    my $identicon = Image::Identicon->new( { salt => $salt } );
    my $image =
      $identicon->render( { code => int( rand( 2**32 ) ), size => 32 } );
    return $image->{image}->png;
}

1;
