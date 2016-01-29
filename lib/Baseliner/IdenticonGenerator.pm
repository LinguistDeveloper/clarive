package Baseliner::IdenticonGenerator;
use Moose;

use Try::Tiny;
use Image::Identicon;
use Baseliner::Utils qw(_debug);

has default_icon => qw(is ro);

sub identicon {
    my $self = shift;
    my ($username) = @_;

    my $user = ci->user->find_one( { username => $username } );

    if ($user) {
        _debug "Generating and saving avatar";

        my $png = try {
            $self->_generate;
        }
        catch {
            my $user_png = $self->default_icon;
            $user_png->slurp;
        };

        my $user_instance = ci->new( $user->{mid} );
        $user_instance->update( avatar => $png );

        #$user->update(avatar => $png);
        return $png;
    }
    else {
        _debug "User not found, avatar generated anyway";

        return $self->_generate;
    }
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
