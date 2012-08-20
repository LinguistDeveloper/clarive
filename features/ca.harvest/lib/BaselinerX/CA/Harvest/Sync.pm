package BaselinerX::CA::Harvest::Sync;

sub new {
    shift;
    my $ver = Baseliner->config->{'Model::Harvest'}->{db_version} || 12;
    my $class = "BaselinerX::CA::Harvest::Sync" . $ver;
    $class->new( @_ );
}

1;


