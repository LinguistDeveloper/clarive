package Baseliner::PlugMouse;

=head1 DESCRIPTION

Sugar for registrable plugins with Mouse included.

=cut

use Mouse;
use Baseliner::Core::Registry;

use Mouse::Exporter;

Mouse::Exporter->setup_import_methods( 
    as_is => [ 'register','register_class' ],
    also => [ 'Mouse' ]
);

sub register {
    my $package = caller;
    my $key = shift;
    my $obj = shift;
    Baseliner::Core::Registry->add( $package, $key, $obj);
}

sub register_class {
    my $package = caller;
    my $key = shift;
    my $obj = shift;
    Baseliner::Core::Registry->add_class( $package, $key, $obj);
}

1;
