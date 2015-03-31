package BaselinerX::Type::Fieldlet;
use Baseliner::PlugMouse;
with 'Baseliner::Role::Registrable';

register_class 'fieldlet' => __PACKAGE__;
sub service_noun { 'fieldlet' }

has name_field => (is=>'rw', isa=>'Str', default=>'');
has id_field   => (is=>'rw', isa=>'Str', default=>'');
has bd_field   => ( is=> 'rw', isa=> 'Str', default=>sub{ 
    my $self = shift;
    return $self->id_field;
});

sub dsl {
    my ($self, $n, %p ) = @_;
    sprintf(q{
        push @{ $stash->{fieldlets} }, %s; 
    }, Data::Dumper::Dumper($n->{data}));
}

1;

