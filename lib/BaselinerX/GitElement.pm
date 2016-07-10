package BaselinerX::GitElement;
use Moose;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;

with 'BaselinerX::Job::Element';

has mask => qw(is rw isa Str default /application/subapp/nature);
has sha => qw(is rw isa Str);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p = @_;

    if( ! exists $p{path} && ! exists $p{name} ) {
        if(  $p{ fullpath } =~ /^(.*)\/(.*?)$/ ) {
            ( $p{path}, $p{name} ) = ( $1, $2 );
        }
        else {
            ( $p{path}, $p{name} ) = ( '', $p{fullpath} );
        }
    }
    $self->$orig( %p );
};

1;
