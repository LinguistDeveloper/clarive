package Baseliner::Role::UserPassword;
use Moose::Role;
use Baseliner::Utils qw(_fail _md5);

has user => qw(is rw isa Str required 1);
has password => qw(is rw isa Str required 1);

sub _gen_user_key {
    my ($self, $user) = @_;
    my $key = Baseliner->decrypt_key; 
    my $user_key = $key . _md5( join '', reverse( split //, $user // $self->user ) );
    return $user_key;
}

# save encrypted password to db
around save_data => sub {
    my $orig = shift;
    my $self = shift;
    my ($master_row, $data, $opts, $old ) = @_;
    if( my $pass = $data->{password} ) {
        my $user_key = $self->_gen_user_key( $data->{user} );
        my $enc_pass = Baseliner->encrypt( substr(_md5(),0,10) . $pass . substr(_md5(),0,10), $user_key ); 
        $data->{password} = $enc_pass;
    }
    $self->$orig( @_ );
};

# decrypt password from db
after load_data => sub {
    my $class = shift;
    my ($mid, $data ) = @_;
    if( my $pass = $data->{password} ) {
        my $user_key = $class->_gen_user_key( $data->{user} );
        my $dec_pass = substr Baseliner->decrypt( $pass, $user_key ), 10, -10;
        $data->{password} = $dec_pass;
    }
};

1;

