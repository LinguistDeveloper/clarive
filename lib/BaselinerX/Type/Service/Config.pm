package BaselinerX::Type::Service::Config;
use Baseliner::Plug;
use Baseliner::Utils;
use v5.10;

with 'Baseliner::Role::Service';

register 'service.config' => {
    alias => 'config',
    name    => 'Config Baseliner',
    handler => \&run,
};

sub run {
    my ($self,$c,$p)=@_;
    #_log _dump $p;
    if( defined $p->{value} ) {
        $c->model('ConfigStore')->set( key=>$p->{key}, value=>$p->{value}, ns=>$p->{ns}, bl=>$p->{bl} );
    } elsif( exists $p->{l} ) {
        #  bl: "*"
        #  composed: config.sqa.tar_exe
        #  config_default: C:\Aps\SCM\cliente\tar.exe
        #  config_key: config.sqa
        #  config_label: Ejectutable tar.exe
        #  config_module: BaselinerX::SQAMain
        #  config_name: ''
        #  config_type: ''
        #  data: ~
        #  id: 1388
        #  key: config.sqa.tar_exe
        #  ns: /
        #  parent_id: 1
        #  ref: ~
        #  reftable: ~
        #  resolved: e:\apsdat\SQA\jobs
        #  ts: 2011-04-20 16:44:05
        #  value: C:\Aps\SCM\cliente\tar.exe

        my $d = $c->model('ConfigStore')->search;
        my $to_hash = sub { 
            my $format = shift // '%s [%s, %s]';
            +{ map {
                my $k=sprintf( $format, $_->{key}, $_->{bl}, $_->{ns}); $k => $_ }
                _array( $d->{data} )
             }
        };
        given( $p->{format} ) {
            when( 'yaml' ) {
                print _dump( $to_hash->()  );
            }
            when( 'apache' ) {
                require Config::General;
                my $conf = Config::General->new();
                print $conf->save_string( $to_hash->('%s_%s_%s') );
            }
            default {
                for( _array( $d->{data} ) ) {
                    print "$_->{composed} = $_->{value}\n";
                    print "\t$_->{config_label}, $_->{ts}, $_->{config_module}, $_->{config_default}\n\n"
                       if exists $p->{v};
                }
            }
        }
    } elsif( defined $p->{reset} ) {
        my $data = $c->model('ConfigStore')->delete( key=>$p->{key}, ns=>$p->{ns}, bl=>$p->{bl} );
    } else {
        my $data = $c->model('ConfigStore')->get( $p->{key}, ns=>$p->{ns}, bl=>$p->{bl} );
        print _dump $data;
    }
}

1;
