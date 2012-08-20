package BaselinerX::CA::Harvest::Service::ConnectedUsers;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.harvest.connected.users' => {
    name    => 'List Users Connected to Harvest',
    config  => 'config.ca.harvest.cli',
    show_in_menu => 1,
    handler => \&run,
};

sub run {
    my ( $self, $c, $p ) = @_;
    _check_parameters( $p, qw/broker/ );
    my $broker = $p->{broker};
    my @s = `echo "setopt server_names $broker\nconnect\npoll client_names\nrun 1\nexit\n" | rtmon `;
	my ($kk, %PC);
    foreach (grep /HClient/, @s) {
        chop;
        $self->log->info( "\t$_" );
        $kk++;
        my $p = $_;
        $p =~ s/.*\[.*: (.*?)\].*/$1/g;
        $PC{$p} = "";
    }
    my $pcs = scalar keys %PC;
    $self->log->info( `date`
      . " - Hay $kk clientes conectados.\nHay $pcs Usuarios/PCs conectados.\n" );

}

1;
