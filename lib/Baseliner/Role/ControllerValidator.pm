package Baseliner::Role::ControllerValidator;
use Moose::Role;

use Baseliner::Validator;
use Baseliner::Utils qw(_loc _debug);

sub validate_params {
    my $self = shift;
    my ( $c, %schema ) = @_;

    my $schema = $self->_build_schema;
    foreach my $key ( keys %schema ) {
        $schema->add_field( $key, %{ $schema{$key} } );
    }

    my $vresult = $schema->validate($c->req->params);

    if ( $vresult->{is_valid} ) {
        return $vresult->{validated_params};
    }
    else {
        _debug 'Validation failed';

        $c->stash->{json} =
          { success => \0, msg => _loc("Validation failed"), errors => $vresult->{errors} };
        $c->forward('View::JSON');
        return 0;
    }
}

sub _build_schema {
    my $self = shift;

    return Baseliner::Validator->new;
}

1;
