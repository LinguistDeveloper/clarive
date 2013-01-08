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
  name    => 'Purga historico de formularios (inf_data e inf_data_mv).',
  config  => 'config.bde.purga_inf',
  handler => \&run
};

register 'config.bde.purga_inf' => {
    metadata => [
        {   id          => 'dias',
            default     => 365,
            label       => 'Antiguedad en Días para borrar',
            description => 'Número de días de cierre de peticion a partir del cuál se purgan formularios',
        },
        {   id          => 'no_del',
            default     => 1,
            label       => 'No borrar filas',
            description => 'Archiva el html del formulario, pero no purga las filas de formulario',
        },
        {   id          => 'force_update',
            default     => 0,
            label       => 'Forzar update del html aunque exista',
            description => 'Fuerza que se actualice el html en inf_peticion_form aunque ya exista',
        },
        {   id          => 'min_size',
            default     => 5000,
            label       => 'Bytes mínimo HTML',
            description => 'Tamaño minimo en bytes para considerar el HTML bueno',
        },
    ]
};

sub run {
    my ($self, $c, $config) = @_;

    my $config_bde = config_get('config.bde');

    require DBIx::Simple;
    require LWP::UserAgent;

    my $inf = DBIx::Simple->connect( Baseliner->model('Inf')->storage->dbh );

    # borrado de mv huerfanos
    unless( $config->{no_del} ) {
        _log "Borrando inf_data_mv huerfanos...";
        my $cnt  = $inf->query(q{delete from inf_data_mv m where not exists ( select 1 from inf_data d where valor like '@#%' and d.valor = '@#'||m.id )}) ;
        _log "inf_data_mv huerfanos borrados ok (cnt=$cnt).";
    } else {
        _log "Borrado de huerfanos desactivado (no_del=0)";
    }

    # los max de infform no se borran
    my %max = map { $_->{idform}=>1 } $inf->query(q{select idform from inf_form_max fm})->hashes;

    my $days = $config->{dias} // _throw ;
    _log sprintf "Purga de Peticiones antiguas de Inf inicio, %d dias.", $days;
    _debug $config;

    # si el idform todavia es actual, no se borra tampoco
    my %current = map { $_->{iddata}=>1 } $inf->query(q{
        select distinct iddata from inf_peticion where finished_on >= sysdate - ? or finished_on is null
    }, $days )->hashes;

    _log "Seleccionando borrables...";
    my @borrables = grep { !exists $max{ $_ } && !exists $current{ $_ } } map { $_->{idform} } 
        $inf->query(q{
            select distinct d.idform
            from inf_data d, inf_peticion p 
            where p.iddata=d.idform  
            and finished_on < sysdate - ?
        }, $days )->hashes;

    my $borrables_total = scalar @borrables;
    _log "Seleccionadas $borrables_total filas borrables.";
    my %descargados_3;  # los idform realmente descargados;
    my $len_total = 0;
    my $min_size = $config->{min_size};

    my $k = 1;

    for my $idform ( sort { $a <=> $b } grep { !$config->{idform} || $config->{idform} == $_ } @borrables ) {

        _log "Recuperando html para idform=$idform ($k/$borrables_total)";
        $k++;
        my $serv = $config_bde->{scminfreal} // _throw('URL de scminfreal no definida en config.bde'); #'http://prusvc61:52024/scm_inf';  # http://prusvc61:52024/scm_inf/inf/infFormIPrint.jsp?ENV=%s&CAM=DWB
        #my $serv = 'http://wassva61:52024/scm_inf';
        my $whoami = 'vpscm'; # en cualquier entorno es lo mismo, siempre vpscm
        my $html;
        for my $e ( qw/T A P/ ) {
            my $row = Baseliner->model('Inf::InfPeticionForm')->find({ idform=>$idform, env=>$e });
            if( $row && !$config->{force_update} ) { # update solo si se fuerza por config 
                _log "No se actualizará la fila idform = $idform y env = $e (force_update=0)";
            } else {
                my $url = sprintf '%s/inf/infFormIPrint.jsp?ENV=%s&IDFORM=%s', $serv, $e, $idform;  
                my $ua = new LWP::UserAgent;
                $ua->cookie_jar( {} );
                my $req = HTTP::Request->new( GET => $url );
                $req->header( "iv-user" => "$whoami" );
                my $res = $ua->request($req);
                if(  $res->is_success ) {
                    require Compress::Zlib;
                    my $cont = $res->content;
                    my $len = length( $cont );
                    $cont = Compress::Zlib::compress( $cont );
                    my $len_compress = length( $cont );
                    $len_total += $len;
                    if( $row ) {
                        $row->update({ html=>$cont, html_size=>$len });
                        _log "Fila idform = $idform y env = $e actualizada (force_update=1)";
                    } else {
                        # new
                        Baseliner->model('Inf::InfPeticionForm')->create({ idform=>$idform, env=>$e, html=>$cont, html_size=>$len });
                        _log "Fila idform = $idform y env = $e creada";
                    }
                    #push @descargados, { idform => $idform, env=>$e, html=>$cont, size=>length($cont) };
                    if( defined $min_size && $len < $min_size ) {
                        _error "ERROR: HTML recuperado sospechoso - tamaño $len < $min_size para $idform y $e. No se borrará." ;
                        next;
                    }
                }
            }
            $descargados_3{ $idform } ++;
        }
    }

    my @descargados = grep { $descargados_3{ $_ } >= 3 } keys %descargados_3;
    _log sprintf "IDs de formulario que se borraran en INF_DATA e INF_DATA_MV: %s", join ',', @descargados;

    # borra las filas de inf_data e inf_data_mv que se hayan descargado con exito
    unless( $config->{no_del} ) {
        for my $idform ( @descargados ) {
            _log "Borrando idform de inf_data = $idform";
            $inf->query(q{delete from inf_data where idform=?}, $idform );
            _log "Borrando idform de inf_data_mv = $idform";
            $inf->query(q{delete from inf_data_mv where idform=?}, $idform );
        }
    } else {
        _log "Borrado de filas desactivado (no_del=1)";
    }

    _log "Purga de Peticiones antiguas de Inf terminado ok.";
}

1;
