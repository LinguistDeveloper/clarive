=head1

BaselinerX::Service::PurgaInf - purga de los multivalores

=cut
package BaselinerX::Service::PurgaInf;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::BdeUtils;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.bde.purga_inf_hist' => {
  name    => 'Purga historico de formularios.',
  config  => 'config.bde',
  handler => \&run
};

sub run {
    my ($self, $c, $config) = @_;

    require DBIx::Simple;
    require LWP::UserAgent;

    my $inf = DBIx::Simple->connect( Baseliner->model('Inf')->storage->dbh );
    my @idforms =
        map { $_->{idform} }
        $inf->query(q{select distinct idform
            from inf_data_mv m where idform=13297
            and not exists ( 
                select 1
                from inf_data d 
                where valor like '@#%' and d.valor = '@#'||m.id )})
        ->hashes;
    
    for my $idform ( @idforms ) {

        my $serv = $config->{scminfreal} // 'http://prusvc61:52024/scm_inf';  # http://prusvc61:52024/scm_inf/inf/infFormIPrint.jsp?ENV=%s&CAM=DWB
        #my $serv = 'http://wassva61:52024/scm_inf';
        my $whoami = 'vpscm'; # en cualquier entorno es lo mismo, siempre vpscm
        my $html;
        for my $e ( qw/T A P/ ) {
           my $url = sprintf '%s/inf/infFormIPrint.jsp?ENV=%s&IDFORM=%s', $serv, $e, $idform;  
           my $ua=new LWP::UserAgent;
           $ua->cookie_jar({});
           my $req=HTTP::Request->new(GET => $url);
           $req->header( "iv-user"=>"$whoami" );
           my $resp=$ua->request($req)->content;
           $html .= $resp; 
        }
    }

    # actualiza el clob con el dato

    # borra las filas de inf_data_mv
    for my $idform ( @idforms ) {
        _log "Borrando idform de inf_data_mv = $idform";
        #$inf->do(q{delete from inf_data_mv where idform=?}, $idform );
    }
}

1;
