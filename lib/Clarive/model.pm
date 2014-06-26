# model : shortcut to Baseliner->model
package model;
use strict;
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my ($method) = reverse( split(/::/, $name));
    return Baseliner->can('model')
        ? Baseliner->model($method) 
        : do {
         my $cn = 'Baseliner::Model::'.$method;
         eval "require $cn";
         $cn 
     };
}

1;
