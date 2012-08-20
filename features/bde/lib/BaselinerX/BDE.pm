package BaselinerX::BDE;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'config.bde.estado_entorno' => {
  metadata => [
    {id => "Desarrollo",            default => "TEST"},
    {id => "Pruebas",               default => "TEST"},
    {id => "Preproducción",         default => "ANTE"},
    {id => "Producción",            default => "PROD"},
    {id => "Emergencia",            default => "PROD"},
    {id => "Producción Emergencia", default => "PROD"},
    {id => "Desarrollo Correctivo", default => "TEST"},
    {id => "Producción Correctivo", default => "PROD"},
  ]
};

register 'config.bde.vista_entorno' => {
  metadata => [
    {id => "DESA", default => "TEST"},
    {id => "TEST", default => "TEST"},
    {id => "ANTE", default => "ANTE"},
    {id => "PROD", default => "PROD"},
  ]
};

register 'config.bde.estado_vista' => {
  metadata => [
    {id => "Desarrollo",            default => "DESA"},
    {id => "Pruebas",               default => "TEST"},
    {id => "Preproducción",         default => "ANTE"},
    {id => "Producción",            default => "PROD"},
    {id => "Emergencia",            default => "PROD"},
    {id => "Producción Emergencia", default => "PROD"},
    {id => "Desarrollo Correctivo", default => "TEST"},
    {id => "Producción Correctivo", default => "PROD"},
  ]
};

register 'config.bde.vista_estado' => {
  metadata => [
    {id => "DESA", default => "Pruebas"},
    {id => "TEST", default => "Pruebas"},
    {id => "ANTE", default => "Preproducción"},
    {id => "PROD", default => "Producción"},
  ]
};

register 'config.bde.estado_checkout' => {
  metadata => [
    {id => "Desarrollo Correctivo", default => "Producción"}
  ]
};

register 'config.bde.entorno_estado' => {
  metadata => [
    {id => "TEST", default => "Pruebas"},
    {id => "ANTE", default => "Preproducción"},
    {id => "PROD", default => "Producción"},
  ]
};

register 'config.bde.promote_process' => {
  metadata => [
    {id => "Desarrollo",            default => "admin: Promover a Desarrollo"},
    {id => "Emergencia",            default => "admin: Promover a Emergencia"},
    {id => "Desarrollo Correctivo", default => "admin: Promover a Desarrollo Correctivo" },
  ]
};

register 'config.bde.usuario_entorno' => {
  metadata => [
    {id => "vtscm", default => 'TEST'},
    {id => "vascm", default => 'ANTE'},
    {id => "vpscm", default => 'PROD'},
  ]
};

register 'config.bde.entorno_usuario' => {
  metadata => [
    {id => 'TEST', default => 'vtscm'},
    {id => 'ANTE', default => 'vascm'},
    {id => 'PROD', default => 'vpscm'},
  ]
};

register 'config.bde.lifecycle' => {
    metadata => [
        { id => 'N', default => 'Normal'     },
        { id => 'R', default => 'Rápido'     },
        { id => 'C', default => 'Correctivo' },
        { id => 'E', default => 'Emergencia' },
    ]
};  

register 'config.form.lifecycle.sistemas' => {
    metadata => [
    { id => 'N', default => 'Sistemas' }
    ]
};

register 'config.form.lifecycle.analisis' => {
    metadata => [
        { id => 'N', default => 'Normal (Con Preproducción)' },
        { id => 'R', default => 'Rápido (Sin Preproducción)' },
        { id => 'C', default => 'Correctivo' },
        { id => 'E', default => 'Emergencia' },
    ]
};

register 'config.form.lifecycle.desa' => {
    metadata => [
        { id => 'N', default => 'Normal' },
        { id => 'R', default => 'Rápido' },
        { id => 'E', default => 'Emergencia' },
    ]
};

register 'config.form.cambio' => {
    metadata => [
        { id => 'N', default => 'Nuevo Desarrollo' },
        { id => 'E', default => 'Desarrollo Evolutivo' },
        { id => 'P', default => 'Pequeño Mantenimiento' },
    ]
};

register 'config.form.tipologia' => {
    metadata => [
        { id => 'INC', default => 'Incidencia' },
        { id => 'PET', default => 'Peticion' },
        { id => 'PRO', default => 'Proyecto' },
        { id => 'MAN', default => 'Mantenimiento Tecnico' },
    ]
};

register 'config.biztalk.tipo' => {
    metadata => [
        { id => 'BT', default => 'Biztalk' },
        { id => 'RS', default => 'Resource' },
        { id => 'FO', default => 'Functoid' },
        { id => 'PC', default => 'Pipeline Component' },
        { id => 'WS', default => 'Web Service Orquestation' },
    ]
};

register 'config.biztalk.store' => {
    metadata => [
        { id => 0, default => 'No Agregar' },
        { id => 1, default => 'Como BiztalkAssembly' },
        { id => 2, default => 'Como Assembly' },
        { id => 3, default => 'Como File' },
    ]
};

register 'config.harax' => {
    metadata => [
        {   id      => 58765,
            default => 'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE='
        },
        {   id      => 49150,
            default => 'TGtkaGZrYWpkaGxma2psS0tKT0tIT0l1a2xrbGRmai5kLC4yLjlka2ozdTQ4N29sa2hqZGtzZmhr'
        },
        {   id      => 49164,
            default => 'SmsuSVVqa0lVNzY1NHJKaC4rODc4N2Rmai4uMTklZGtqc2ExMTo5OCwsMUBqaHJ1KGhqaEh0MmpFcWF4eng='
        }
    ]
};

register 'config.harvest' => {
    metadata => [
        {   id          => 'user',
            default     => '-eh /home/aps/scm/servidor/harvest/hserverauth_new.dfo',
            label       => 'Usuario TAM',
            description => 'Usuario TAM para la ejecución de UDP (Si -eh ......dfo se utilizará'
                . ' el fichero dfo)'
        },
        {   id          => 'password',
            default     => '-',
            label       => 'Password TAM',
            description => 'Password TAM del usuario vpscm (en blanco utilizará el fichero dfo). '
                . 'Valido para la ejecución de UDPS'
        },
        {   id          => 'broker',
            default     => 'prusv063',
            label       => 'Servidor Harvest',
            description => 'Nombre del servidor Harvest'
        },
        {   id          => 'alta_frecuencia',
            default     => 30,
            label       => 'Frecuencia alta Harvest',
            description => 'Frecuencia de revisión de alta de aplicaciones Harvest.'
        },
        {
        	id          => 'hardist',
        	default     => 'http://wbetest.bde.es/scmdist'
        }
    ] 
};

register 'config.bde' => {
    metadata => [
        {   id          => 'ldifmaq',
            default     => 'prue',
            label       => 'Maquina FTP',
            description => 'Nombre de la máquina donde la carga de usuarios se conectará por FTP para descargar el fichero de usuarios (por defecto: prue)'
        },
        {   id          => 'ldif_remote_directory',
            default     => '/u/grp/tds/salidas_tds02',
            label       => 'Directorio servidor remoto',
            description => 'Directorio en el servidor remoto desde donde se cargarán los ficheros'
        },
        {   id          => 'ldif_home_directory',
            default     => '/home/grp/scm/datos/ldif',
            label       => 'Directorio objetivo',
            description => 'Directorio de datos donde se dejarán los ficheros LDIF importados para su tratamiento'
        },
		{   id          => 'harpwd',
            default     => '-',
            label       => 'Password TAM',
            description => 'Password TAM del usuario vpscm (en blanco utilizará el fichero dfo). Valido para la ejecución de UDPS'
        },
        {   id          => 'ldif_updates_harvest',
            default     => 0,
            label       => 'Actualizar Harvest ademas de Baseliner?',
        },
        {   id          => 'perltemp',
            default     => '/home/aps/scm/servidor/tmp',
           label       => 'Directorio Perl',
            description => 'Directorio temporal general para procesos Perl'
        },
        {   id          => 'udphome',
            default     => '/home/aps/scm/servidor/udp',
            label       => 'Directorio scripts',
            description => 'Directorio donde se encuentran los scripts perl'
        },
        {   id          => 'inf_data',
            default     => 'INF_DATA',
            label       => 'Tabla Info Formulario Infraestructura',
            description => 'Directorio donde se encuentran los scripts perl'
        },
        {   id          => 'loghome',
            default     => '/home/aps/scm/servidor/logs',
            label       => 'Directorio log Dispatcher',
            description => 'Directorio de logs donde se creará el log del Dispatcher'
        },
        {   id          => 'templates',
            default     => '/home/aps/scm/servidor/plantillas',
            label       => 'Plantillas',
            description => 'Directorio de plantillas de correo electrónico y esqueletos de JCL'
        },
        {   id          => 'udpverbose',
            default     => '(en modo VERBOSE)',
            description => 'Ver Dispatcher.pl'
        },
        {   id          => 'package_promote_wait',
            default     => 10,
            label       => 'Tiempo espera',
            description => 'Tiempo de espera para segundo intento de verificacion de si los paquetes están en el estado correspondiente. V. x Defecto = 10'
        },
        {   id          => 'hardist',
            default     => 'http://wbeprod.bde.es/scm_hardist',
            label       => 'URL Hardist',
            description => 'URL de hardist via webseal'
        },
        {   id          => 'kill_chain', 
            default     => 1,
            label       => 'Matar pase en caso de error',
            description => 'Finaliza el pase en cuanto se detecte un error, con el estado "ERROR"'
        },
        {
        	id          => 'temp',
        	default     => '/home/aps/scm/servidor/tmp',
        	label       => 'Directorio tempora gen�rico.',
        	description => 'Directorio tempora gen�rico.'
        },
        {
        	id          => 'pasehome',
        	default     => '/home/aps/scm/servidor/pase',
        	label       => 'Directorio de trabajo de pases.',
        	description => 'Directorio de trabajo de pases.'
        },
        {
        	id          => 'backuphome',
        	default     => '/home/grp/scm/bkpase',
        	label       => 'Directorio de backup de pases.',
        	description => 'Directorio de backup de pases.'
        },
        {
        	id          => 'purga_dirpase',
        	default     => 2,
        	label       => 'Número de días que permanecerá el pase en el directorio de backup de pases antes de borrarlo.',
        	description => 'Número de días que permanecerá el pase en el directorio de backup de pases antes de borrarlo.'
        },
        {
        	id          => 'temp_harax',
        	default     => '/home/grpt/scm',
        	label       => 'Directorio temporal de importación de distribuciones CLICK-ONCE.',
        	description => 'Directorio temporal de importación de distribuciones CLICK-ONCE.'
        },
        {
        	id          => 'purga_releases_borradas',
        	default     => 1,
        	label       => 'Un 1 Indica que la purga debe borrar los dirs de release en la carpeta PUBLICO de los staging si la release ha sido borrada en Harvest.',
        	description => 'Un 1 Indica que la purga debe borrar los dirs de release en la carpeta PUBLICO de los staging si la release ha sido borrada en Harvest.'
        },
        {
        	id          => 'pubname',
        	default     => 'PUBLICO',
        	label       => 'Nombre del proyecto Harvest de aplicaciones publicas.',
        	description => 'Nombre del proyecto Harvest de aplicaciones publicas.'
        },
        {
        	id          => 'stawin',
        	default     => 'svm0210',
        	label       => 'Nombre del servidor de Staging .NET SVM0210 o SVM0609',
        	description => 'Nombre del servidor de Staging .NET SVM0210 o SVM0609'
        },
        {
        	id          => 'stawindir',
        	default     => '/home/aps/scm/servidor/staging',
        	label       => 'Directorio de trabajo del servidor de Staging UNIX.',
        	description => 'Directorio de trabajo del servidor de Staging UNIX.'
        },
        {
        	id          => 'stawinport',
        	default     => 58765,
        	label       => 'Puerto de conexión Harax en el servidor de Staging UNIX.',
        	description => 'Puerto de conexión Harax en el servidor de Staging UNIX.'
        },
        {
        	id          => 'stawindirpublico',
        	default     => 'C:/APS/SCM/SERVIDOR/PUBLICO',
        	label       => 'Directorio de publicación de las aplicaciones públicas en el Staging Windows.',
        	description => 'Directorio de publicación de las aplicaciones públicas en el Staging Windows.'
        },
        {
        	id          => 'sta_eclipse_staging',
        	default     => 'E:/APSDAT/SCM/STAGING/PUBLICO/ECLIPSE',
        	label       => 'Path en Staging windows donde se dejará la versión de feature compilada y sus plugins para que lo utilice posteriormente la compilación de IAS, etc. P.Ej.: E:/APSDAT/SCM/STAGING/PUBLICO/ECLIPSE',
        	description => 'Path en Staging windows donde se dejará la versión de feature compilada y sus plugins para que lo utilice posteriormente la compilación de IAS, etc. P.Ej.: E:/APSDAT/SCM/STAGING/PUBLICO/ECLIPSE'
        },
        {
        	id          => 'stawinbizserver',
        	default     => 'SVM0132',
        	label       => 'Staging para Biztalk',
        	description => 'Staging para Biztalk'
        },
        {
        	id          => 'stawinbizport',
        	default     => '58765'
        },
        {
        	id          => 'stawinbizdir',
        	default     => 'E:\APSDAT\SCM',
        	label       => 'Directorio de trabajo del servidor de Staging BizTalk',
        	description => 'Directorio de trabajo del servidor de Staging BizTalk'
        },
        {
        	id          => 'loghome',
        	default     => '/home/aps/scm/servidor/logs',
        	label       => 'Directorio de logs donde se creará el log del Dispatcher.',
        	description => 'Directorio de logs donde se creará el log del Dispatcher.'
        },
        {
        	id          => 'harvesthome',
        	default     => '/home/apst/scm/servidor/logs'
        },
        {
        	id          => 'scminfreal',
        	default     => 'http://prusvc61:52024/scm_inf',
        	label       => 'url verdadera de scm_inf',
        	description => 'url verdadera de scm_inf'
        },
        {
        	id          => 'poll_log_dir',
        	default     => '/home/apst/scm/servidor/vass/logs',
        	label       => 'Directorio donde está localizado el log del script poll.',
        	description => 'Directorio donde está localizado el log del script poll.'
        },
        {
        	id          => 'poll_log_name',
        	default     => 'poll.log',
        	label       => 'Nombre del fichero de log del script poll.',
        	description => 'Nombre del fichero de log del script poll.'
        },
        {
        	id          => 'log_dias_baseliner',
        	default     => 30,
        	label       => 'Máximo de días en los que se guardarán los logs de Baseliner.',
        	description => 'Máximo de días en los que se guardarán los logs de Baseliner.'
        },
        {
        	id          => 'log_dias_baseliner_pase',
        	default     => 30,
        	label       => 'Máximo de días en los que se guardarán los pases de Baseliner en disco.',
        	description => 'Máximo de días en los que se guardarán los pases de Baseliner en disco.'
        },
        {
        	id          => 'root_username',
        	default     => 'admin',
        	label       => 'Usuario con permisos de root',
        	description => 'Usuario con permisos de root'
        },
        {
        	id          => 'natures_with_subapps',
        	default     => [qw/J2EE .NET BIZTALK VIGNETTE/],
        	label       => 'Naturalezas con subaplicaciones.',
        	description => 'Naturalezas con subaplicaciones.'
        }, 
        {
            id          => 'dailyqainterval',
            default     => 600,
            label       => 'Tiempo de espera en cada iteración del demonio lanzamiento análisis SQA',
            description => 'Tiempo de espera en cada iteración del demonio lanzamiento análisis SQA'
        }
    ]
};

1;
