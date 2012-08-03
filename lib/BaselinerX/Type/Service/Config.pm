package BaselinerX::Type::Service::Config;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'service.config' => {
    alias => 'config',
    name    => 'Config Baseliner',
    handler => \&run,
};

sub run {
    my ($self,$c,$p)=@_;
    _log _dump $p;
    if( defined $p->{value} ) {
        $c->model('ConfigStore')->set( key=>$p->{key}, value=>$p->{value}, ns=>$p->{ns}, bl=>$p->{bl} );
    } elsif( defined $p->{reset} ) {
        my $data = $c->model('ConfigStore')->delete( key=>$p->{key}, ns=>$p->{ns}, bl=>$p->{bl} );
    } else {
        my $data = $c->model('ConfigStore')->get( $p->{key}, ns=>$p->{ns}, bl=>$p->{bl} );
        print _dump $data;
    }
}

1;
