package BaselinerX::Model::ConfigRegister;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Model' }

sub register_config {
    my ( $self, $c, $id, $default, $table, $config ) = @_;

    my $rs =
        Baseliner->model("Baseliner::$table")
        ->search( undef,
        { select => [ $id, $default ], as => [qw/ id default /], order_by => { -asc => 'id' } } );

    rs_hashref($rs);

    my @metadata = $rs->all;

    register "config.$config" => { metadata => [@metadata] };

    return;
}

1;

