package ci;
use strict;
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my ($method) = reverse( split(/::/, $name));
    my $class = $method =~ /new|find|is_ci/ ? 'Baseliner::CI' : 'Baseliner::Role::CI';
    Clarive->load_class( $class ); 
    if( $class->can($method) ) {
        $method = $class . '::' . $method;
        @_ = ( $class, @_ );
        goto &$method;
    } else {
        my $cl = 'BaselinerX::CI::'.$method;
        Clarive->load_class( $cl ); 
        return $cl; 
    }
}

1;
