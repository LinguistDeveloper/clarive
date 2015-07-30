package BaselinerX::Type::Fieldlet;
use Moose;
use Baseliner::Core::Registry ':dsl';
with 'Baseliner::Role::Registrable';
with 'Baseliner::Role::Palette';

register_class 'fieldlet' => __PACKAGE__;
sub service_noun { 'fieldlet' }

has name		=> (is=>'rw', isa=>'Str', default=>'');
has name_field 	=> (is=>'rw', isa=>'Maybe[Str]', default=>sub{ 
    my $self = shift;
    return $self->name;
});
has id_field   	=> (is=>'rw', isa=>'Str', default=>'');
has form		=> (is=>'rw', isa=>'Str', default=>'');
has html_file	=> (is=>'rw', isa=>'Str', default=>'');
has js_file		=> (is=>'rw', isa=>'Str', default=>'');
has bd_field   	=> ( is=> 'rw', isa=> 'Maybe[Str]', default=>sub{ 
    my $self = shift;
    return $self->id_field;
});

has leaf        => ( is => 'rw', isa => 'Bool', default => 1);
has holds_children => ( is => 'rw', isa => 'Bool', default => 0);

has dsl            => ( is => 'rw', isa => 'CodeRef', default=>sub{
	return sub{
	    my ($self, $n, %p ) = @_;
	    my %data = %{ $n->{data} || {} };
	    $data{name_field} = $n->{text};
        sprintf(q{
            push @{ $stash->{fieldlets} }, parse_vars(%s, $stash);
            %s
        }, Data::Dumper::Dumper(\%data), $self->dsl_build( $n->{children}));
	};
});

no Moose;
__PACKAGE__->meta->make_immutable;

1;

