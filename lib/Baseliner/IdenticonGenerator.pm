package Baseliner::IdenticonGenerator;
use Moose;
use Baseliner::Utils qw(_debug);
use Try::Tiny;

has default_icon => qw(is ro);

sub identicon {
    my ($self, $username)=@_;
    my $user = ci->user->find({ username=>$username })->next;
    my $generate = sub {
            # generate png identicon from random
            require Image::Identicon;
            my $salt = '1234';
            my $identicon = Image::Identicon->new({ salt=>$salt });
            my $image = $identicon->render({ code=> int(rand( 2 ** 32)), size=>32 });
            return $image->{image}->png;
    };
    if( ref $user ) {
        _debug "Generating and saving avatar";
        my $png = try { 
            $generate->();
        } catch {
            my $user_png = $self->default_icon;
            $user_png->slurp;
        };
        my $user_instance = ci->new($user->{mid});
        $user_instance->update(avatar => $png);
        #$user->update(avatar => $png);
        return $png;
    }
    else {
        _debug "User not found, avatar generated anyway";
        return $generate->();
    }
}

1;