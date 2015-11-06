package Baseliner::Validator;
use Moose;
use Moose::Util::TypeConstraints qw(find_type_constraint);
use Baseliner::Types;

has fields => ( is => 'ro', default => sub { {} } );

sub add_field {
    my $self = shift;
    my ( $name, %params ) = @_;

    $self->fields->{$name} = {%params};

    return $self;
}

sub validate {
    my $self = shift;
    my ($params) = @_;

    my $validated_params = {};
    my $errors           = {};

    foreach my $name ( keys %{ $self->fields } ) {
        my $field = $self->fields->{$name};
        my $value = $params->{$name};
        $value = $value->[0] if $value && ref $value eq 'ARRAY';

        if ($self->_is_empty($value)) {
            if (exists $field->{default}) {
                $validated_params->{$name} = $field->{default};
            }
            else {
                $errors->{$name} = 'REQUIRED';
            }

            next;
        }

        my $has_errors = 0;

        if (my $isa = $field->{isa}) {
            my $type_constraint = find_type_constraint($isa) or die "Can't find type $isa";

            if ($type_constraint->coercion) {
                $value = $type_constraint->coerce($value);
            }

            my $error_message = $type_constraint->validate($value);

            if (defined $error_message) {
                if ($field->{default} && $field->{default_on_error}) {
                    $value = $field->{default};
                }
                else {
                    $errors->{$name} = $error_message;

                    $has_errors = 1;
                    last;
                }
            }
        }

        $validated_params->{$name} = $value unless $has_errors;
    }

    my $is_valid = %$errors ? 0 : 1;

    return {
        is_valid         => $is_valid,
        validated_params => $validated_params,
        errors           => $errors
    };
}

sub _is_empty {
    my $self = shift;
    my ($value) = @_;

    return 1 unless defined $value;
    return 1 unless length $value;

    return 0;
}

1;
