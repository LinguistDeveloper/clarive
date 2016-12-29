package Baseliner::Controller::Variable;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

sub options : Local {
    my ( $self, $c ) = @_;

    my $id       = $c->req->params->{id};
    my $bl       = $c->req->params->{bl} // '*';
    my $variable = ci->new($id);
    my $options;
    my @values;

    if ( $variable->{var_type} eq 'combo' ) {
        $options = $variable->{var_combo_options};
    }
    else {
        $options = $variable->{variables}->{$bl};
    }

    if ($options) {
        @values = map { +{ value => $_ } } @{$options};
    }

    $c->stash->{json} = { data => \@values, totalCount => scalar @values };
    $c->forward('View::JSON');
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
