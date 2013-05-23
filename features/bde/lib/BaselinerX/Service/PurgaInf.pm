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

register 'config.bde.purga_inf' => {
    metadata => [
        {   id          => 'url',
            default     => '%s/inf/infFormIPrint.jsp?ENV=%s&IDFORM=%s',
            label       => 'URL de impresión del formulario',
            description => 'La URL para recuperar el formulario para imprimir. El primer %s es el servidor, el segundo el env y el tercer el idform',
        },
        {   id          => 'dias',
            default     => 365,
            label       => 'Antiguedad en Días para borrar',
            description => 'Número de días de cierre de peticion a partir del cuál se purgan formularios',
        },
        {   id          => 'dias_peticion',
            default     => 365*5,
            label       => 'Antiguedad en Días para borrar',
            description => 'Número de días de cierre de peticion a partir del cuál se purgpeticiones',
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
        {   id          => 'save_html',
            default     => 0,
            label       => 'Guardar HTML?',
            description => 'Guardar o no HTML de los borrados en la tabla inf_peticion_form',
        },
        {   id          => 'envs',
            default     => 'T,A,P',
            label       => 'Entornos de formulario',
            description => 'Letra que se utiliza en la llamada a la url de formulario, separada por comas',
        },
    ]
};

register 'service.bde.purga_inf' => {
  name    => 'Purga historico de formularios (inf_data e inf_data_mv).',
  config  => 'config.bde.purga_inf',
  handler => \&run
};

register 'service.bde.hist_get' => {
  name    => 'Recupera el HTML de la tabla INF_PETICION_FORM',
  handler => \&hist_get
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
        my $cnt  = $inf->query(q{delete from inf_data_mv m where (not exists ( select 1 from inf_data d where valor like '@#%' and d.valor = '@#'||m.id )) and (not exists (select 1 from inf_hashdata h where valor like '@#%' and h.valor = '@#'||m.id))}) ;
        _log "inf_data_mv huerfanos borrados ok (cnt=$cnt).";
    } else {
        _log "Borrado de huerfanos desactivado (no_del=1)";
    }

    # los max de infform no se borran
    my %max = map { $_->{idform}=>1 } $inf->query(q{select idform from inf_form_max fm})->hashes;

    my $days = $config->{dias} // _throw 'El parametro "dias" no está definido';
    _log sprintf "Purga de datos de Formularios antiguos de Inf inicio, %d dias.", $days;
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
    my $serv = $config_bde->{scminfreal} // _throw('URL de scminfreal no definida en config.bde'); #'http://prusvc61:52024/scm_inf';  # http://prusvc61:52024/scm_inf/inf/infFormIPrint.jsp?ENV=%s&CAM=DWB
    my $whoami = $config_bde->{'iv-user'} // _throw 'Falta definir config.bde.iv-user'; # en cualquier entorno es lo mismo, siempre vpscm
    my @envs = grep { length } split /,/, $config->{envs};
    _log "Envs de formulario: " . join ',', @envs;

    for my $idform ( sort { $a <=> $b } grep { !$config->{idform} || $config->{idform} == $_ } @borrables ) {
        _log "Recuperando html para idform=$idform ($k/$borrables_total)" if $config->{save_html};
        $k++;
        #my $serv = 'http://wassva61:52024/scm_inf';
        my $html;
        for my $e ( @envs ) {
            if( $config->{save_html} ) {
                my $row = Baseliner->model('Inf::InfPeticionForm')->find({ idform=>$idform, env=>$e });
                if( $row && !$config->{force_update} ) { # update solo si se fuerza por config 
                    _log "HTML ya existe. No se actualizará la fila idform = $idform y env = $e (force_update=0)";
                } 
                else {
                    my $url = sprintf $config->{url}, $serv, $e, $idform;  
                    my $ua = new LWP::UserAgent;
                    $ua->cookie_jar( {} );
                    my $req = HTTP::Request->new( GET => $url );
                    $req->header( "iv-user" => "$whoami" );
                    my $res = $ua->request($req);
                    if(  $res->is_success ) {
                        require Compress::Zlib;
                        my $cont_orig = $res->content;
                        my $len = length( $cont_orig );
                        my $html_zip = Compress::Zlib::compress( $cont_orig );
                        $len_total += $len;
                        # verifica si el HTML es sospechoso (error login, error en la pagina, error oracle...
                        if( defined $min_size && $len < $min_size ) {
                            _error "ERROR: HTML recuperado sospechoso - tamaño $len < $min_size para idform=$idform y env=$e. No se borrará." ;
                            $cont_orig =~ s{[\n|\r|\t]}{}g unless $config->{no_short_html};
                            $cont_orig = _strip_html( $cont_orig ) unless $config->{no_strip_html};
                            _error "HTML Sospechoso:\n" . $cont_orig;
                            next;
                        }
                        # actualiza la fila
                        if( $row ) {
                            $row->update({ html=>$html_zip, html_size=>$len });
                            _log "Fila idform = $idform y env = $e actualizada (force_update=1)";
                        } else {
                            # new
                            Baseliner->model('Inf::InfPeticionForm')->create({ idform=>$idform, env=>$e, html=>$html_zip, html_size=>$len });
                            _log "Fila idform = $idform y env = $e creada";
                        }
                    } else {
                        _error sprintf "ERROR (code=%d) al recuperar HTML: %s" , $res->code, $res->message ;
                        next;
                    }
                }
            } else {
                _debug "HTML get desactivado (save_html=0)";
            }
            $descargados_3{ $idform } ++;
        }
    }

    my @descargados = grep { $descargados_3{ $_ } >= 3 } keys %descargados_3;   # borrados en los 3 entornos? 
    _log sprintf "IDs de formulario que se borraran en INF_DATA e INF_DATA_MV: %s", join ',', @descargados;

    # borra las filas de inf_data e inf_data_mv que se hayan descargado con exito
    unless( $config->{no_del} ) {
        for my $idform ( @descargados ) {
            _log "Borrando idform de inf_data = $idform";
            $inf->query(q{delete from inf_data where idform=?}, $idform );
            _log "Borrando idform de inf_hashdata = $idform";
            $inf->query(q{delete from inf_hashdata where idform=?}, $idform );
            _log "Borrando idform de inf_data_mv = $idform";
            $inf->query(q{delete from inf_data_mv where idform=?}, $idform );
            _log "Borrando idform de inf_form = $idform";
            $inf->query(q{delete from inf_form where idform=?}, $idform );
        }

        # borrando los campos (inf_status_hist) de las peticiones que se borrarán
        my $pet_cnt = $inf->query(q{select count(*) from inf_status_hist where idpeticion in (
    									select id from inf_peticion p
    									where finished_on < sysdate - ?
            									and not exists (select 1 from inf_status s where s.idpeticion = p.id) )}, $config->{dias_peticion} )->flat;
        _log _loc "Borrando %1 campos de INF_STATUS_HIST", $pet_cnt->[0];

        $inf->query(q{delete from inf_status_hist where idpeticion in (
    									select id from inf_peticion p
    									where finished_on < sysdate - ?
            									and not exists ( select 1 from inf_status s where s.idpeticion = p.id) )}, $config->{dias_peticion} );

        # borrando las tareas (inf_peticion_tarea) de las peticiones que se borrarán
        $pet_cnt = $inf->query(q{select count(*) from inf_peticion_tarea where idpeticion in (
    									select id from inf_peticion p
    									where finished_on < sysdate - ?
            									and not exists (select 1 from inf_status s where s.idpeticion = p.id) )}, $config->{dias_peticion} )->flat;
        _log _loc "Borrando %1 tareas de INF_PETICION_TAREA", $pet_cnt->[0];

        $inf->query(q{delete from inf_peticion_tarea where idpeticion in (
    									select id from inf_peticion p
    									where finished_on < sysdate - ?
            									and not exists (select 1 from inf_status s where s.idpeticion = p.id) )}, $config->{dias_peticion} );

        # borrando las filas de inf_peticion
        $pet_cnt = $inf->query(q{select count(*) from inf_peticion p where finished_on < sysdate - ?
            and not exists ( select 1 from inf_status s where s.idpeticion = p.id )}, $config->{dias_peticion} )->flat;
        _log _loc "Borrando %1 peticiones de INF_PETICION", $pet_cnt->[0];

        $inf->query(q{delete from inf_peticion p where finished_on < sysdate - ?
            and not exists ( select 1 from inf_status s where s.idpeticion = p.id )}, $config->{dias_peticion} );

        # limpiando huerfanas
        _log "Limpiando filas de INF_STATUS_HIST que no existan en INF_PETICION...";
        $inf->query(q{delete from inf_status_hist h where not exists ( select 1 from inf_peticion where id = h.idpeticion ) });
        _log "Limpiando filas de INF_PETICION_TAREA que no existan en INF_PETICION...";
        $inf->query(q{delete from inf_peticion_tarea t where not exists ( select 1 from inf_peticion where id = t.idpeticion )});

    } else {
        _log "Borrado de filas desactivado (no_del=1)";
    }

    _log "Purga de Peticiones antiguas de Inf terminado ok.";
}

sub hist_get {
    my ($self, $c, $config) = @_;

    require DBIx::Simple;
    my $inf = DBIx::Simple->connect( Baseliner->model('Inf')->storage->dbh );
    my $idform = $config->{idform} // _throw 'Falta el parámetro --idform';
    my $env = $config->{env} // _throw 'Falta el parámetro --env';
    my $html = $inf->query('select html,html_size from inf_peticion_form where env=? and idform=?', $env, $idform)->flat;
    if( ref $html eq 'ARRAY' && $html->[0] ) {
        _log sprintf "SIZE %.02f KBs" , $html->[1]/1024;
        _log "LEN=" . length $html->[0];
        require Compress::Zlib;
        my $data = $html->[0];
        $data = Compress::Zlib::uncompress( $data ) or _throw "No se ha podido descomprimir el fichero html";
        if( $config->{file} ) {
            open my $ff, '>', $config->{file} or _throw "Error al intentar abrir el fichero $config->{file}: $!";
            binmode $ff;
            print $ff $data;
            close $ff;
        } else {
            print STDERR $data;
        }
    } else {
        _throw "HTML no encontrado o vacío";
    }
}

1;
