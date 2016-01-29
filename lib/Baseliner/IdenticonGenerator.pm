package Baseliner::IdenticonGenerator;
use Moose;

use Try::Tiny;
use Image::Identicon;
use Baseliner::Utils qw(_debug _file);

has default_icon => qw(is ro required 1);

sub identicon {
    my $self = shift;
    my ($username) = @_;

    my $user = ci->user->find_one( { username => $username } );

    if ($user) {
        _debug "Generating and saving avatar";

        my $png = $self->_generate_or_default;

        my $user_ci = ci->new( $user->{mid} );
        $user_ci->update( avatar => $png );

        return $png;
    }
    else {
        _debug "User not found, avatar generated anyway";

        return $self->_generate_or_default;
    }
}

sub _generate_or_default {
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
