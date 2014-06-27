# model : shortcut to Baseliner->model
package model;
use strict;
use v5.10;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my ($method) = reverse( split(/::/, $name));
    state $model_loaded = Baseliner->can('model');
    return $model_loaded 
        ? Baseliner->model($method) 
        : do {
         my $cn = 'Baseliner::Model::'.$method;
         eval "require $cn";
         $cn 
     };
}

1;
