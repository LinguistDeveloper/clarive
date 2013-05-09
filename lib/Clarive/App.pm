package Clarive::App;
use Mouse;

has env  => qw(is rw default) => sub { $ENV{CLARIVE_ENV} // $ENV{CLA_ENV} // 'local' };
has lang => qw(is ro default) => sub { $ENV{CLARIVE_LANG} // 'en_US.UTF-8' };
has home       => qw(is rw default) => sub { $ENV{CLARIVE_HOME} // '.' };
has debug      => qw(is rw default) => sub { 0 };
has trace      => qw(is ro default) => sub { 0 };

sub yaml {
    my $self=shift;
    require YAML::XS;
    YAML::XS::Dump( @_ );
}

sub json {
    my ($self, $data) = @_; 
    require JSON::XS;
    my $json = JSON::XS->new;
    $json->convert_blessed( 1 );
    $json->encode( $data );
}

around 'dump' => sub {
    my ($orig, $self, $data) = @_; 
    $data ? warn $self->yaml( $data ) : $self->$orig();
};

1;
