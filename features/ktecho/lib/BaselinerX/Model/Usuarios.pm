package BaselinerX::Model::Usuarios;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub coger_todos_usuarios {
    my ( $self, $c ) = @_;
    my $rs = Baseliner->model('Baseliner::BaliUser');
    my @data;

    rs_hashref($rs);

    @data = $rs->all;

    return \@data;
}

1;
