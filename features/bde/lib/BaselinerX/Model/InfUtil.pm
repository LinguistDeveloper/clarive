package BaselinerX::Model::InfUtil;
use Baseliner::Core::DBI;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use Compress::Zlib;
use Data::Dumper;
use Moose;
use Try::Tiny;
use utf8;

has 'cam',            is => 'rw', isa => 'Str';
has 'whoami',         is => 'ro', isa => 'Str',      lazy_build => 1;
has 'inf_data',       is => 'ro', isa => 'Str',      lazy_build => 1;
has 'inf_hashdata',   is => 'ro', isa => 'Str',      lazy_build => 1;
has 'hardistreal',    is => 'ro', isa => 'Str',      lazy_build => 1;
has 'staunix',        is => 'ro', isa => 'Str',      lazy_build => 1;
has 'staunixport',    is => 'ro', isa => 'Str',      lazy_build => 1;
has 'staunixdir',     is => 'ro', isa => 'Str',      lazy_build => 1;
has 'staunixuser',    is => 'ro', isa => 'Str',      lazy_build => 1;
has 'max_idform',     is => 'rw', isa => 'Int',      lazy_build => 1;
has 'has_sistemas',   is => 'ro', isa => 'Int',      lazy_build => 1;
has 'is_public',      is => 'ro', isa => 'Str',      lazy_build => 1;
has 'is_public_bool', is => 'ro', isa => 'Int',      lazy_build => 1;
has 'tiene_test',     is => 'ro', isa => 'Int',      lazy_build => 1;
has 'tiene_ante',     is => 'ro', isa => 'Int',      lazy_build => 1;
has 'tiene_prod',     is => 'ro', isa => 'Int',      lazy_build => 1;
has 'tiene_java',     is => 'ro', isa => 'Int',      lazy_build => 1;
has 'entornos',       is => 'ro', isa => 'ArrayRef', lazy_build => 1;
has 'sub_apps_java',  is => 'ro', isa => 'ArrayRef', lazy_build => 1;
has 'sub_apps_net',   is => 'ro', isa => 'ArrayRef', lazy_build => 1;
has 'has_oracle',     is => 'ro', isa => 'Bool',     lazy_build => 1;
has 'has_vignette',   is => 'ro', isa => 'Bool',     lazy_build => 1;
has 'has_rs',         is => 'ro', isa => 'Bool',     lazy_build => 1;
has 'nets_oracle',    is => 'ro', isa => 'ArrayRef', lazy_build => 1;
has 'nets_oracle_r7', is => 'ro', isa => 'Str',      lazy_build => 1;

sub db {
  my $self = shift;
  Baseliner::Core::DBI->new({model => 'Inf'});
}

sub _build_inf_data {
  my $self       = shift;
  my $config_bde = Baseliner->model('ConfigStore')->get('config.bde');
  $config_bde->{inf_data};
}

sub _build_whoami {
  my $self       = shift;
  my $config_bde = Baseliner->model('ConfigStore')->get('config_bde');
  $config_bde->{whoami};
}

sub _build_hardistreal {
  my $self           = shift;
  my $config_harvest = Baseliner->model('ConfigStore')->get('config.harvest');
  $config_harvest->{hardistreal};
}

sub _build_max_idform {
  my $self = shift;
  my $cam  = uc($self->cam);
  my $sql  = qq{
    SELECT MAX(idform)
      FROM inf_form
     WHERE cam = ?
  };
  $self->db->value($sql, $cam);
}

sub _build_staunix {
  my $self           = shift;
  my $config_harvest = Baseliner->model('ConfigStore')->get('config.bde');
  $config_harvest->{staunix};
}

sub _build_staunixport {
  my $self           = shift;
  my $config_harvest = Baseliner->model('ConfigStore')->get('config.bde');
  $config_harvest->{staunixport};
}

sub _build_staunixdir {
  my $self           = shift;
  my $config_harvest = Baseliner->model('ConfigStore')->get('config.bde');
  $config_harvest->{staunixdir};
}

sub _build_staunixuser {
  my $self           = shift;
  my $config_harvest = Baseliner->model('ConfigStore')->get('config.bde');
  $config_harvest->{staunixuser};
}

sub _build_has_sistemas {
  my $self = shift;
  my $value = $self->get_inf(undef, [{column_name => 'SCM_APL_SISTEMAS'}]);
  $value eq 'Si' ? 1 : 0;
}

sub _build_entornos {
  my $self=  shift;
  my @array = @{$self->get_inf(undef, [{column_name => 'MAIN_ENTORNOS'}])};
  \@array;
}

sub _build_is_public {
  my $self = shift;
  $self->get_inf(undef, [{column_name => 'SCM_APL_PUBLICA'}]);
}

sub _build_is_public_bool {
  my $self = shift;
  $self->is_public eq 'Si' ? 1 : 0;
}

sub _build_tiene_test {
  my $self = shift;
  'TEST' ~~ $self->entornos ? 1 : 0;
}

sub _build_tiene_ante {
  my $self = shift;
  'ANTE' ~~ $self->entornos ? 1 : 0;
}

sub _build_tiene_prod {
  my $self = shift;
  'PROD' ~~ $self->entornos ? 1 : 0;
}

sub _build_tiene_java {
  my $self  = shift;
  my @redes = qw/ I W G /;
  my @data;
  for my $red (@redes) {
    push @data, $self->get_inf(undef, 
                               [{column_name => 'TEC_JAVA', 
                                 idred       => $red}]);
  }
  'Si' ~~ @data ? 1 : 0;
}

sub _build_sub_apps_java {
  my $self = shift;
  return [] unless $self->tiene_java;

  my $ref = $self->get_inf(undef, [{column_name => 'JAVA_APPL'}]);
  return ["$ref"] if ref($ref) ne 'ARRAY';

  my @data = @{$ref};
  \@data;
}

sub _build_sub_apps_net {
  my $self = shift;
  my $ref = $self->get_inf(undef, [{column_name => 'WIN_APPL'}]);

  if (ref($ref) ne 'ARRAY') {
    return [] if ref($ref) == 0;
    return ["$ref"];
  }
  my @data = @{$ref};
  \@data;
}

sub sub_apps_biztalk {
  my ($self, $sub_appl) = @_;
  my $value = $self->get_inf({sub_apl => $sub_appl}, 
                             [{column_name => 'NET_BIZTALK'}]);
  $value eq 'Si' ? 1 : 0;
}

sub has_nature {
  my ($self, $nature) = @_;
  my $cam = $self->cam;
  my $sql = qq{ SELECT COUNT (*)
                  FROM harpathfullname
                 WHERE pathfullnameupper LIKE ? };
  my $count = $self->harvest->db->value($sql, "\\$cam\\$nature%");
  $count > 0 ? 1 : 0;
}

sub _build_has_oracle {
  my $self = shift;
  $self->has_nature("ORACLE");
}

sub _build_has_vignette {
  my $self = shift;
  $self->has_nature("VIGNETTE");
}

sub _build_has_rs {
  my $self = shift;
  my $cam  = $self->cam;
  my $sql  = qq{ SELECT COUNT (*)
                   FROM harpathfullname
                  WHERE pathfullnameupper = ? };
  my $count = $self->harvest->db->value($sql, "\\$cam\\RS");
  $count > 0 ? 1 : 0;
}

sub harvest_init {
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  sub {$har_db}
}

sub harvest {
  my $self    = shift;
  my $harvest = $self->harvest_init;
  $harvest->();
}

sub get_metadata {
  # Informacion de campo de la tabla inf_metadata.
  my ($self, $colname) = @_;
  my $sql = qq{
        SELECT display_name, 
               short_name, 
               seq, 
               description, 
               column_group, 
               list_of_values 
        FROM   inf_metadata 
        WHERE  column_name = Trim('$colname')  
  };
  $self->db->array($sql);
}

sub solve_mv {
  my ($self, @array) = @_;
  for my $href (@array) {
    if ($href->{value} =~ m/@#(.+)/) {
      my $sql  = "SELECT mv_valor FROM inf_data_mv WHERE ID IN ($1)";
      my @data = $self->db->array($sql);
      $href->{value} = \@data;
    }
  }
  wantarray ? @array : \@array;
}

sub solve_mv_single {
  my ($self, $str) = @_;
  if ($str =~ m/^\@\#(.+)/x) {
    my $sql = qq{
      SELECT mv_valor
        FROM inf_data_mv
       WHERE ID = $1
    };
    my @data = $self->db->array($sql);
    return wantarray ? @data : \@data;
  }
  return;
}

# Gets:  Array  de hashes con el  column_name,  idred e idenv de  cada campo a
# mostrar
# Returns: Array con la condicion where
sub get_where_f2 {
  my ($self, $array_ref) = @_;
  my @array_of_hashes = @{$array_ref};
  my @array           = ();
  my $count           = 0;

  for my $ref (@array_of_hashes) {
    # Por defecto es 'General'...
    $ref->{idred} = 'G' unless $ref->{idred};
    $ref->{ident} = 'G' unless $ref->{ident};
    
    # Column names are always UC.
    $ref->{column_name} = uc($ref->{column_name});

    # Filter the NET just in case.
    # $ref->{idred} = $ref->{idred} eq 'LN'
    #                   ? 'I'
    #                   : $ref->{idred} eq 'W3'
    #                       ? 'W'
    #                       : 'G';

    # The environment should be a char.
    $ref->{ident} = substr($ref->{ident}, 0, 1);

    my $string = $count != 0 ? "or " : q{};
    $string .= qq((
          column_name = '$ref->{column_name}' 
      and ident       = '$ref->{ident}' 
      and idred       = '$ref->{idred}' 
    ));
    push @array, $string;
    $count++;
  }
  @array;
}

# Gets:    1. Hash con sub_apl y cam (opcional), en caso de ser nulo se pone undef.
#          2. Array hash con column_name, idred e ident.
# Returns: Hash si se pasa mas de una tabla, array con valores sin se pasa una.
sub get_inf {
  my ($self, $args_ref, $array_ref) = @_;

  my $sub_apl    = $args_ref->{sub_apl} || q{};
  my @columns    = $self->get_where_f2($array_ref);
  my $inf_data   = $self->inf_data;
  my $max_idform = $self->max_idform;
  my $cam        = $args_ref->{cam} || uc($self->cam) or die "No hay CAM";

  # Construyendo la query...
  my $query = qq{
    SELECT column_name key, valor value
    FROM   $inf_data
    WHERE  ( @columns )
      AND  cam = '$cam'
      AND  idform = $max_idform
  };
  $query .= " AND subaplicacion = '$sub_apl' " if $sub_apl;
  $query .= " ORDER BY 1 ";
  
  # _log "\nQuery:\n $query";

  my @array_inf_data = $self->db->array_hash($query);
  @array_inf_data = $self->solve_mv(@array_inf_data);

  undef my %hash;
  my @campos;

  for my $ref (@array_inf_data) {
    $hash{$ref->{key}} = $ref->{value};
    push @campos, $ref->{key};
  }
  return scalar(keys %hash)   > 1  ? \%hash
       : scalar(values %hash) == 1 ? $hash{$campos[0]}
       :                             [values %hash];
}

# set_inf_SCM_status - modifica el status del campo SCM_APL_CREAR (Si,No,Creado)
sub set_inf_SCM_status {
  my ($self, $status) = @_;
  my $cam        = uc($self->cam);
  my $inf_data   = $self->inf_data;
  my $max_idform = $self->max_idform;

  my $sql_scm_apl_crear = qq{
    UPDATE $inf_data d
       SET d.valor = '$status'
     WHERE UPPER (d.cam) = '$cam'
       AND d.column_name = 'SCM_APL_CREAR'
       AND d.idform = $max_idform
  };
  my $sql_readonly = qq{
    UPDATE $inf_data d
       SET d.valor =
             d.valor || '|#SCM_APL_CREAR#|#SCM_APL_PUBLICA#|#SCM_APL_SISTEMAS#'
     WHERE UPPER (d.cam) = '$cam'
       AND d.column_name = $max_idform
       AND d.idform = $max_idform
  };
  $self->db->do($sql_scm_apl_crear);
  $self->db->do($sql_readonly);
  return;
}

# Carga las variables de infraestructura en un Hash.
sub load_infvar {
  my $self = shift;
  my $sql  = "SELECT variable, valor FROM infvar";
  $self->db->hash($sql);
}

sub inf_report {
  my ($self, $pase, $env) = @_;
  my $hardistreal = $self->hardistreal;
  my $whoami      = $self->whoami;
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

  for my $infenv ($har_db->get_pass_projects($pase)) {
    my ($cam, $cam_uc) = get_cam_uc($infenv);
    my $servidor_hardist = $hardistreal;

    use LWP::UserAgent;
    my $ua = new LWP::UserAgent;
    $ua->cookie_jar({});

    undef my %var_env;
    my $url = "$servidor_hardist/inf/infForm.jsp?cam_uc=${cam_uc}&VIEW=1&ENV=$var_env{$env}";
    warn "Conectando a '$url' para obtener el informe de infraestructura...";
    my $req = HTTP::Request->new(GET => $url);
    $req->header("iv-user" => $whoami);
    my $resp = $ua->request($req)->content;
    warn "Infraestructura de la aplicacion '$cam_uc'", $resp;
  }
  return;
}

sub inf_es_ {
  my ($self, $env_name, $string, $sub_apl) = @_;
  my $cam = uc($env_name);
  my $ret = $self->get_inf({cam => $cam, sub_apl => $sub_apl}, 
                           [{column_name => $string}]);
  $ret;
}

sub inf_es_publica {
  my ($self, $env_name) = @_;
  my $value = $self->inf_es_($env_name, 'SCM_APL_PUBLICA', q{});
  $value
    ? do { _log "\nApplication $env_name is public.";      return 'Si' }
    : do { _log "\nApplication $env_name is not public. "; return 'No' }
    ; 
}

sub inf_es_IAS {
  # DFEATURE my $f_;
  my ($self, $env_name, $sub_apl) = @_;
  
  # DREQUIRE length($env_name) == 3, 
   #         "CAM length must be 3 chars ($env_name length is " . length($env_name) . ")";
  
  my $value = $self->inf_es_($env_name, 'JAVA_APPL_TECH', $sub_apl);
  $value =~ m/IAS/ix ? 1 : 0;
 
  _log $value ? "$env_name is IAS" : "$env_name is NOT IAS";
  
  # DVAL $value;
}

sub inf_es_EDW4J {    #JAVA_APPL_TECH
  my ($self, $env_name, $sub_apl) = @_;
  my $value = $self->inf_es_($env_name, 'JAVA_APPL_TECH', $sub_apl);
  $value =~ m/EDW4J/ix 
    ? do { _log "\n$sub_apl ($env_name) is EDW4J.";     return 1 }
    : do { _log "\n$sub_apl ($env_name) is not EDW4J."; return 0 }
    ;
}

# Retorna un array de campos con los datos de un servidor Windows
sub get_win_server_info {
  my ($self, $server, $array_ref) = @_;
  my $str = join ', ', @{$array_ref};
  my $sql = qq{
    SELECT $str
      FROM inf_server_win
     WHERE server = '$server'
  };
  my @ls = $self->db->array($sql);
  wantarray ? @ls : \@ls;
}

# Retorna un array de campos con los datos de un servidor Unix
sub get_unix_server_info {
  my ($self, $args_ref, @fields) = @_;
  my $server  = $args_ref->{server}  || q{};
  my $env     = $args_ref->{env}     || q{};
  my $sub_apl = $args_ref->{sub_apl} || 'something';
  my $cam     = uc($self->cam);
  my $sql = "SELECT " . join(',', @fields) . "
               FROM inf_server_unix
              WHERE UPPER (TRIM (server)) = UPPER (TRIM ('$server')) ";
  my @data = $self->db->array($sql);

  my $resolver = 
       BaselinerX::Ktecho::Inf::Resolver->new({cam     => $cam,
                                               entorno => $env,
                                               sub_apl => $sub_apl});
  for my $value (@data) {
    $value = $resolver->get_solved_value($value);
  }
  scalar(@data) == 1 ? $data[0] : @data;
}

sub get_aplicacion_ {
  my ($self, $string, $num) = @_;
  undef my %aplicacion;
  my @campos = ({column_name => $string, idred => 'G', ident => 'G'});
  my @array = $self->get_inf(undef, \@campos);

  for my $ref (@array) {
    foreach (@{$ref->{value}}) {
      $aplicacion{substr($_, 0, $num)} = $_;
    }
  }
  %aplicacion;
}

sub get_aplicacion_publicas_net {
  my $self = shift;
  $self->get_aplicacion_('WIN_SCM_APL_PUB', 3);
}

sub get_aplicacion_publicas_net_form {
  my $self = shift;
  $self->get_aplicacion_('WIN_SCM_APL_PUB', 50);
}

sub get_aplicacion_publicas_biztalk {
  my $self = shift;
  $self->get_aplicacion_('WIN_BIZ_SCM_APL_PUB', 3);
}

sub get_aplicacion_publicas_biztalk_form {
  my $self = shift;
  $self->get_aplicacion_('WIN_BIZ_SCM_APL_PUB', 50);
}

sub get_aplicacion_publicas_J2EE_form {
  my $self = shift;
  $self->get_aplicacion_('J2EE_APL_PUB', 50);
}

sub get_inf_sub_apl {
  my ($self, $nat) = @_;
  my $cam        = uc($self->cam);      # Uppercase por si las moscas...
  my $inf_data   = $self->inf_data;
  my $max_idform = $self->max_idform;

  # Consigue el campo dada la naturaleza
  my %nat_to_campo = (
    'J2EE'     => 'WAS',
    'NET'      => 'NET',
    'IASBATCH' => 'IASBATCH_APPL',
  );

  my $campo = $nat_to_campo{$nat} || 'NET';    # Por defecto NET

  my $sql = qq{
    SELECT valor
      FROM $inf_data
     WHERE cam = '$cam' AND column_name = '$campo' AND idform = $max_idform
  };
  my $rawsub_apl = $self->db->value($sql);

  my @SA = $rawsub_apl =~ m/^\@#/x 
    ? $self->solve_mv_single($rawsub_apl) 
    : split(/\|/, $rawsub_apl);

  my %RET = ();
  foreach my $sa (@SA) {
    my ($sa_name, $sa_activa) = split /\;/, $sa;  # <sub_apl>;1|0
    next if defined $sa_activa && !$sa_activa;    # las sub_apl tienen un cero "0" si no estan activas
    $RET{$sa_name} = ();
  }
  return keys %RET;
}

sub get_inf_subred {
  my ($self, $env, $sub_apl) = @_;
  my $cam = uc($self->cam);
  my $sql = qq{
    SELECT DISTINCT idred red
               FROM inf_data
              WHERE subaplicacion = '$sub_apl' AND ident = '$env'
  };
  $self->db->value($sql);
}

## get_inf_destinos : destino de distrib. unix
sub get_inf_destinos {
  # DFEATURE my $f_;
  my ( $self, $env, $sub_apl ) = @_;

  $env = $env =~ m/^T/xi ? 'T'    # TEST    => T
       : $env =~ m/^A/xi ? 'A'    # ANTE    => A
       : $env =~ m/^P/xi ? 'P'    # PROD    => P
       :                   'G'    # General => G
       ;

  my $cam_uc = uc($self->cam);
  undef my %destino;
  my $es_IAS = $self->inf_es_IAS($cam_uc, $sub_apl);
  my $red = $self->get_inf_subred($env, $sub_apl);
  my $red_txt = $red =~ m/I/ix ? 'Interna' 
              : $red =~ m/W/xi ? 'Internet' 
              :                  'General'
              ;

  # logdebug "red ($cam_uc,$env,$sub_apl) = $red\n" if ( $ENV{DEBUG} );

  my $cam = lc($cam_uc);
  my $e = substr(lc($env), 0, 1);
  $destino{sub_apl} = $sub_apl;

  my $resolver =
   BaselinerX::Ktecho::Inf::Resolver->new({entorno => $env,
                                           sub_apl => $sub_apl,
                                           cam     => $cam_uc});

  $destino{maq} =
   $resolver->get_solved_value($self->get_inf(undef,
                                              [{column_name => 'WAS_SERVER',
                                                ident       => $env,
                                                idred       => $red}]));

#  $destino{server_cluster} =
#   $self->get_unix_server_info({sub_apl => $sub_apl,
#                                env     => $env,
#                                server  => $destino{maq}},
#                               qw{ SERVER_CLUSTER });
                               
  $destino{server_cluster} = 
   $resolver->get_solved_value($self->get_inf(undef,
                                              [{column_name => 'WAS_CLUSTER',
                                                ident       => $env,
                                                idred       => $red}]));                       

  warn "No tengo el servidor WAS para el entorno $env ($red_txt) en el formulario de Infraestructura (campo WAS_SERVER, pesta#a AIX)" unless ($destino{maq});

  $destino{puerto} = $self->staunixport;
  $destino{red}    = $red;

  my $user_auths = $self->get_inf(undef,
                                  [{column_name => 'AIX_UFUN_AUTH',
                                    idred       => $red,
                                    ident       => $env}]);

  AUTH:
  for my $auth (@$user_auths) {
    my ($serv, $usr, $grp) = split(/\;/, $auth);
    $serv = $resolver->get_solved_value($serv);
    if ($serv =~ m/^$destino{maq}/xi) {
      $destino{user}  = $usr;
      $destino{group} = $grp;
      last AUTH;
    }
  }
  warn "No tengo el usuario destino para el servidor $destino{maq} en el formulario de Infraestructura (campo ${env}_${red}_AIX_UFUN_AUTH)" 
    unless ($destino{user} or $destino{group});

  $destino{was_user}  = "vpwas";
  $destino{was_group} = "gpwas";

  my $dest_script = $self->get_inf({sub_apl => $sub_apl},
                                   [{column_name => 'SCRIPT_DESPLIEGUE',
                                     idred       => $red,
                                     ident       => $env}]);

  if ($dest_script) {
    #$destino{script} = infResolveVars( $dest_script, $cam_uc, $env );
  }
  else {
    $destino{script} =
      "/home/aps/was/scripts/gen/${cam_uc}/j2eeTools${cam_uc}.sh";
  }

  $destino{home} = lc("/tmp");    ##esto es el temporal para el EAR

  #  Se cambia para extraer el dato por sub_apl . q74313 30/08/2010
  my $hay_reinicio = $self->get_inf({sub_apl => $sub_apl},
                                    [{column_name => 'WAS_RESTART',
                                      idred       => 'G',
                                      ident       => 'G'}]);
  $destino{reinicio} = ($hay_reinicio =~ m/Si/i ? 1 : 0);

  $hay_reinicio = $self->get_inf({sub_apl => $sub_apl},
                                 [{column_name => 'WAS_WEB_RESTART',
                                   idred       => $red,
                                   ident       => $env}]);
  $destino{reinicio_web} = ($hay_reinicio =~ m/Si/i ? 1 : 0);

  # DM Version
  $destino{was_ver} = 
    $self->get_inf({sub_apl => $sub_apl},
                   [{column_name => 'WAS_SERVER_DMGR_VERSION',
                     idred       => $red,
                     ident       => $env}]);

  $destino{was_ver} = $destino{was_ver}->[0] if ref($destino{was_ver}) eq 'ARRAY';
    
  warn "Aviso: Falta rellenar la versión de DMGR de WAS en el formulario de Infraestructura del cam_uc-> $cam_uc en la pestaña de la sub_apl-> $sub_apl-> Versión de DMGR de la aplicación)"
    unless $destino{was_ver};

  $destino{was_ver} =~ s/^(.*?)\.(.*?)$/$1$2/g;
  $destino{was_ver} =~ s/0//g;
  $destino{was_ver} = "6" unless ($destino{was_ver});

  # Server Version
  $destino{was_server_ver} =
    $self->get_inf({sub_apl => $sub_apl},
                   [{column_name => 'WAS_SERVER_VERSION',
                     idred       => $red,
                     ident       => $env}]);

  my $max_idform = $self->max_idform;

  warn "Aviso: Falta rellenar la version de WAS en el formulario de Infraestructura de $cam_uc (pestana [$sub_apl]-Servidor WAS-Informacion Avanzada-Version de WAS)"
    unless ($destino{was_server_ver});

  $destino{was_server_ver} =~ s/^(.*?)\.(.*?)$/$1$2/g;
  $destino{was_server_ver} =~ s/0//g;
  $destino{was_server_ver} = "6" unless ($destino{was_server_ver});

  # HTTP
  $destino{htp_puerto} = $destino{puerto};
  $destino{htp_user}   = "v${e}${cam}";
  $destino{htp_group}  = "g${e}${cam}";

  my @temp_array =
   $self->get_inf_unix_server({ent    => $env,
                               red    => $red,
                               server => $destino{maq},
                               tipo   => 'HTTP'});
  my $servidor_var   = shift @temp_array;
  my $nombre_con_var = shift @temp_array;

  #( $destino{htp_maq} )=$self->get_inf_sub($cam_uc,$sub_apl,"${env}_${red}_WAS_verSION" );
  $destino{htp_maq} = $servidor_var;

  $destino{htp_server_cluster} =
   $self->get_unix_server_info({sub_apl => $sub_apl,
                                env     => $env,
                                server  => $destino{htp_maq}},
                               qw{ SERVER_CLUSTER });

  $destino{htp_dir} =
    $self->get_inf_unix_server_dir({entorno => $env,
                                    server  => $nombre_con_var,
                                    red     => $red});    # /home/aps/htp/$cam

  # IAS CONFIG
  # my ($servConfig,$dirConfig,$sizeConfig) = $self->get_infTipo($cam_uc,"(WAS)","${env}_${red}_AIX_CONFIG_DIRS");
  $destino{config_dir} = "/home/grp/was/j2eeaps/$sub_apl/config";

  my $hash_temp = $self->get_inf({sub_apl => $sub_apl},
                                 [{column_name => 'JAVA_APPL_TECH'},
                                  {column_name => 'WAS_CONFIG_PATH'},
                                  {column_name => 'WAS_LOG_PATH',
                                   idred       => $red,
                                   ident       => $env},
                                  {column_name => 'WAS_CONTEXT_ROOT'}]);

  $destino{tech}             = $hash_temp->{JAVA_APPL_TECH};
  $destino{config_dir}       = $hash_temp->{WAS_CONFIG_PATH} if defined $hash_temp->{WAS_CONFIG_PATH};
  $destino{was_log_dir}      = $hash_temp->{WAS_LOG_PATH};
  $destino{was_context_root} = $hash_temp->{WAS_CONTEXT_ROOT};

  warn "Campo del formulario de infraestructura 'Context-root' vacio Utilizando el nombre de subaplicacion '$sub_apl'."
    unless ($destino{was_context_root});

  $destino{was_context_root} = $sub_apl;
  $destino{htp_dir} .= "/"
    . $destino{was_context_root}; # gdf 58340, cam SAC, ahora hace falta concatenar el context-root
  $destino{htp_dir} =~ s{//}{/}g; # quita dobles barras

  # Este flag indica si debemos distribuir o no en el servidor.
  # No se puede distribuye si no esta instalado el agente harax, por ejemplo.
  $destino{desplegar_flag} =
    $self->get_unix_server_info({server  => $destino{htp_maq},
                                 sub_apl => $sub_apl,
                                 env     => $env},
                                 'DESPLEGAR_FLAG');
                                 
  _log Data::Dumper::Dumper \%destino;                                

  %destino;
}


# Busca un valor,  o  array de valores,  en un listbox de  ; y |.  Devuelve la
# fila entera si la encuentra
#   ej: get_inf_tipo($cam_uc,$env,"prusv30","TEST_LN_AIX_LOG_DIRS")
#          - devuelve las filas con prusv30 en cualquier posicion
#   ej: get_inf_tipo($cam_uc,$env,["prusv30","was"],"TEST_LN_AIX_LOG_DIRS")
#          - devuelve las filas con 'prusv30' y 'was' en cualquier posicion
sub get_inf_tipo {
  my $self      = shift;
  my $tipo      = shift;           # Puede ser un escalar o una lista
  my $array_ref = shift;           # AoH con column_name, idred e idred
  my @campos    = @{$array_ref};
  my @resultado = ();

  return unless ($self->max_idform || $tipo);

  my @data = $self->get_inf(undef, \@campos);

  for my $ref (@data) {
    my @valores = split(/\|/, $ref->{value});

    foreach my $valor (@valores) {
      my @mi_valores = split(/;/, $valor);
      try {
        my $cnt = @{$tipo};  # Esto peta si no es una lista, y va al otherwise
        if (@{$tipo} > 0) {
          foreach my $t (@{$tipo}) {
            if (index($valor, $t) > -1) {    # La lista se busca como un AND
              $cnt--;
            }
          }
          push @resultado, @mi_valores
            if ($cnt eq 0);    # OK si estan todos los valores buscados
        }
      }
      catch {
        for my $val (@mi_valores) {
          if (index($val, $tipo) > -1) {    # Busco valor a valor
            push @resultado, @mi_valores;
          }
        }
      };
    }
  }
  @resultado;
}

# get_inf_unix_server:  devuelve  el nombre  del servidor  AIX del  tipo $tipo
# (ORACLE,HTTP,WAS)  de la infraestructura de  la aplicacion para  el env $ent
# (TEST, ANTE, PROD) y para el cam_uc $cam
sub get_inf_unix_server {
  my ($self, $args_ref) = @_;
  my $ent  = $args_ref->{ent};
  my $tipo = $args_ref->{tipo};
  my $red  = $args_ref->{red};
  my $cam  = uc($self->cam);

  my @resultado = ();

  my $entorno = ( $ent =~ m/^T/i ) ? 'TEST'
              : ( $ent =~ m/^A/i ) ? 'ANTE'
              : ( $ent =~ m/^P/i ) ? 'PROD'
              :                      'N\A'
              ;

  # print "\nBuscando servidor de tipo '$tipo' para '$cam' en el entorno '$entorno'\n";

  my @campo = ({column_name => 'AIX_SERVER', ident => $ent, idred => $red});
  my @data = @{$self->get_inf(undef, \@campo)};

  # print "Columna ${ent}_${red}_AIX_SERVER = $columna\n";

  my $resolver =
   BaselinerX::Ktecho::Inf::Resolver->new({cam     => $cam,
                                           entorno => $ent,
                                           sub_apl => 'cacacacaca'});

  for my $server (@data) {
    $server =~ /^(.*?)\((.*?)\)/;
    my $servername = $1;
    my $servertype = $2;
    $servername = $resolver->get_solved_value($servername);
    _log "Evaluando servidor $servername de tipo $servertype\n";
    if ($servertype eq $tipo) {
      @resultado = ($servername, $server);
      last;
    }
  }
  wantarray ? @resultado : \@resultado;
}

# get_inf_unix_server_dir:  devuelve el directorio  de aplicacion del servidor
# $server para el env $ent (TEST, ANTE, PROD) y para el cam_uc $cam
sub get_inf_unix_server_dir {
  my ($self, $args_ref) = @_;
  my $ent    = $args_ref->{entorno};
  my $server = $args_ref->{server};
  my $red    = $args_ref->{red};
  my $resultado;

  my @campo = ({column_name => 'AIX_INST_DIRS',
                idred       => $red,
                ident       => $ent});
  my @data = @{$self->get_inf(undef, \@campo)};
  my $servername;
  my $dir;
  my $resolver =
       BaselinerX::Ktecho::Inf::Resolver->new({cam     => uc($self->cam),
                                               entorno => $ent,
                                               sub_apl => 'something'});

  RESOLVER:
  foreach (@data) {
    ($servername, $dir) = split(/;/, $_);
    $servername = $resolver->get_solved_value($servername);
    if ($servername eq $server) {
      $resultado = $dir;
      last RESOLVER;
    }
  }
  $resultado;
}

sub get_staging_unix_active {
  my $self = shift;
  use BaselinerX::Comm::Balix;
  my $staunix     = $self->staunix;
  my $staunixport = $self->staunixport;
  my $staunixdir  = $self->staunixdir;
  my $staunixuser = $self->staunixuser;
  my ($port, $dir, $usu) = ($staunixport, $staunixdir, $staunixuser);
  my $activo;
  my $crash;
  foreach my $maq (split(/,/, $staunix)) {
    try {
      my $balix = BaselinerX::Comm::Balix->new(
        host => $maq,
        port => $port,
        key  => Baseliner->model('ConfigStore')->get('config.harax')->{$port}
      ) or warn "Error al abrir la conexion con agente en $maq:$port";
      $activo = $maq;
      last;
    }
    catch {
      warn "Servidor de staging $maq esta ocupado. Se intentara el siguiente servidor...";
      $crash .= "$maq:$port,";
    };
  }
  unless ($activo) {
    $crash = substr($crash, 0, length($crash) - 1);
    print ahora()
      . " - get_staging_unix_active(): **** ERROR: no hay maquinas de "
      . "staging disponibles. Las siguientes maquinas estan ocupadas"
      . "$crash\n";
    die "ERROR: no he encontrado maquinas de staging disponibles. Las "
      . "siguientes maquinas estan ocupadas $crash\n";
  }
  return ($activo, $port, $dir, $usu);
}

# get_inf_hash_data : retorna un array de campos ocultos de la ultima version
# de un form de inf.  de un cam
sub get_inf_hash_data {
  my ($self, $idred, $ident) = @_;
  my $cam          = uc($self->cam);
  my $inf_hashdata = $self->inf_hashdata;
  my $max_idform   = $self->max_idform;

  return unless $max_idform;

  my $sql = qq{
    SELECT DISTINCT column_name, valor
               FROM $inf_hashdata
              WHERE (   column_name = 'IAS_HIDDEN'
                     OR column_name = 'WAS_VERSION_HIDDEN'
                    )
                AND idform = $max_idform
                AND idred = $idred
                AND ident = $ident
           ORDER BY column_name
  };
  $self->db->array_hash($sql);
}

sub apl_tiene_ante {
  my $self    = shift;
  my @estados = $self->get_inf(undef, [{column_name => 'MAIN_ENTORNOS'}]);
  /ante/ ~~ @estados ? 'Si' : 'No';
}

sub _build_nets_oracle { # -> ArrayRef[Str]
  my $self = shift;
  my @possible_nets = (qw/I W/);  # Feel free to edit this.
  my $where = {idred       => \@possible_nets,
               idform      => $self->max_idform,
               column_name => 'TEC_ORACLE',
               cam         => $self->cam};
  my $args = {select => ['idred', 'valor']};
  my $rs = Baseliner->model('Inf::InfData')->search($where, $args);
  rs_hashref($rs);

  # Return a new list composed by the nets whose value is 'Si'.
  [map ($_->{idred}, grep($_->{valor} eq 'Si', $rs->all))];
} #=> ['I', 'W']

sub _build_nets_oracle_r7 { # -> Str
  my $self = shift;
  my @nets = @{$self->nets_oracle};

  return 'I' ~~ @nets && 'W' ~~ @nets ? 'LN|W3'  # If has both
       : 'I'     ~~ @nets ? 'LN'     # ... or Interna
       : 'W'     ~~ @nets ? 'W3'     # ... or Internet
       : undef                                   # ... else null.
       ;
}

sub obsolete_public_version {
  my ($self, $version) = @_;
  my $sql = qq{
    SELECT statename
      FROM harstate s, harpackage p
     WHERE p.stateobjid = s.stateobjid
       AND TRIM (p.packagename) LIKE '$version' || '-%'
       AND TRIM (p.packagename) LIKE '$version-PROD'
  };
  my $har = BaselinerX::CA::Harvest::DB->new;
  my @ls = $har->db->array($sql);
  wantarray ? @ls : \@ls;
}

sub public_apps_j2ee {
  my ($self, $cam) = @_;
  my %aplicaciones = ();
  my $public_app = "";
  my $inf = BaselinerX::Model::InfUtil->new(cam => $cam);
  my @ls = @{$inf->get_inf(undef, [{column_name => 'J2EE_APL_PUB'}])};
  wantarray ? @ls : \@ls;
}

sub _get_inf_subapl_hash {
  my ($self, $column_name, $sub_apl) = @_;
  my %h = split ';', 
                join ';', 
                     @{$self->get_inf(undef, 
                                      [{column_name => $column_name}])};
  return $h{$sub_apl} if exists $h{$sub_apl};
  _throw
    "Valor no definido para subapl: '$sub_apl' en column_name: '$column_name'."
    . "\nPor favor, compruebe el formulario de infraestructura.";
}

sub get_net_project_types {
  my ($self, $env, $sub_apl) = @_;
  my %ret    = ();
  my $har_db = BaselinerX::CA::Harvest::DB->new;
  my $sql    = qq{
    SELECT prj_proyecto, prj_tipo
      FROM bde_paquete_proyectos_net
     WHERE prj_env = '$env' AND prj_subaplicacion = '$sub_apl'
  };
  my @ls = $har_db->db->array($sql);
  while (@ls) {
    my ($pro, $tipo) = (shift @ls, shift @ls);
    push @{$ret{$pro}}, $tipo;
  }
  %ret;
}

sub get_aplicaciones_publicas_net {
  my $self         = shift;
  my $cam          = $self->cam;
  my %aplicaciones = ();
  my $apl_publicas =
    $self->get_inf(undef, [{column_name => 'WIN_SCM_APL_PUB'}]);
  foreach (@{$apl_publicas}) {
    $aplicaciones{substr($_, 0, 3)} = ($_);
  }
  %aplicaciones;
}

sub get_aplicaciones_publicas_net_form {
  my $self         = shift;
  my $cam          = $self->cam;
  my %aplicaciones = ();
  my $apl_publicas =
    $self->get_inf(undef, [{column_name => 'WIN_SCM_APL_PUB'}]);
  foreach (@{$apl_publicas}) {
    $aplicaciones{substr($_, 0, 50)} = ($_);
  }
  %aplicaciones;
}

1;
