package BaselinerX::SQAMain;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

##Acciones
register 'action.sqa.view' => {
	name => "Access to the quality portal"
};

register 'action.sqa.new_analysis' => {
	name => "Can request a new quality analysis"
};

register 'action.sqa.request_analysis' => {
	name => "Can request a new analysis from an already calculated project"
};

register 'action.sqa.request_project' => {
	name => "Can request the analysis of all subapp/nature of a Project"
};

register 'action.sqa.request_subproject' => {
	name => "Can request the analysis of all subapp/nature of a Subproject"
};

register 'action.sqa.request_recalc' => {
	name => "Can request the recalc of an already calculated project"
};

register 'action.sqa.general' => {
	name => "Can see the General branch in SQA tree"
};

register 'action.sqa.project' => {
	name => "Can see the Project branch in SQA tree"
};

register 'action.sqa.subproject' => {
	name => "Can see the subproject branch in SQA tree"
};

register 'action.sqa.subprojectnature' => {
	name => "Can see the Subproject/Nature branch in SQA tree"
};

register 'action.sqa.packages' => {
	name => "Can see the packages branch in SQA tree"
};

register 'action.sqa.config' => {
	name => "Can see the configuration branch in SQA tree"
};

register 'action.sqa.project_config' => {
	name => "Can configure a project"
};

register 'action.sqa.global_config' => {
	name => "Can configure the global SQA properties"
};

register 'action.sqa.view_project' => {
	name => "Can see the project in SQA grid"
};

register 'action.sqa.analysis_mail' => {
	name => "Receive a mail when an analysis finishes"
};

register 'action.sqa.pkg_analysis_mail' => {
	name => "Receive a mail when a package analysis finishes"
};

register 'action.sqa.ju_mail' => {
	name => "Receive a daily mail whith the analysis results"
};

register 'action.sqa.delete_analysis' => {
	name => "Can delete an analysis row from SQA grid"
};


##Configuración del daemon
register 'config.sqa.feed' => {
	metadata => [
       { id=>'frequency', label=>'SQA Feed Daemon Frequency', default => 60 },
       { id=>'job_home', label=>'Job dir home', default => '/home/grpt/scm/pase' },  # /home/apst/pase - por ej.
       { id=>'job_file_name', label=>'Nombre del fichero de job', default => 'job.yml'},
       { id=>'processed_file', label=>'Nombre del fichero de job procesado', default => 'bali_processed.txt'},
       { id=>'iterations', label=>'Iteraciones del servicio', default => '10'},
       { id=>'running_states', label=>'Estados en los que un analisis se puede quedar "colgado"', default=>'RUNNING,ANALYZING RESULTS,WAITING FOR SLOT' }
    ]
};

##Configuración del daemon
register 'config.sqa.send_ju' => {
	metadata => [
       { id=>'frequency', label=>'SQA send_ju Daemon Frequency', default => 600 },
       { id=>'iterations', label=>'Iteraciones del servicio', default => '10'},
       { id=>'bl', label=>'Baselines en las que se enviará correo al JU', default => 'ANTE|PROD'},
       { id => 'mail_time', label => 'Hora de envio del mail de JU', default => '21', },
       { id => 'next_mail', label => 'Ultimo mail de JUs enviado', default => '2011-07-24 20:00:00', }, 
    ]
};

##Configuración del daemon
register 'config.sqa.purge' => {
	metadata => [
       { id=>'days_to_keep', label=>'Days to keep a package analysis', default => 7 }
    ]
};

#Configuración del servicio
register 'config.sqa' => {
    metadata => [
        { id => 'server', label => 'SQA Server', default => 'svm0759', },
        { id => 'port', label => 'SQA Server Port', default => '58765', },
        { id => 'key', label => 'SQA Server Key', default =>'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE='  },
        { id => 'dist_server', label => 'Dist Server', default => 'prusv063', },
        { id => 'dist_port', label => 'Dist Server Port', default => '58765', },        
        { id => 'dist_key', label => 'Dist Server Key', default =>'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE='  },
        { id => 'dist_udp_dir', label => 'Directorio de scripts', default => '/home/apst/scm/servidor/udp', },
        { id => 'dist_user', label => 'Dist Server', default => 'vtscm', },
        { id => 'file', label => 'Fichero de salida', default => 'auditrep.xml', },
        { id => 'file_html', label => 'Fichero de salida', default => 'auditrep.html', },
        { id => 'dir_pase',  label => 'Directorio de salida', default => 'e:\apsdat\SQA\pases', },
        { id => 'script_dir', label => 'Directorio de scripts', default => 'e:\apsdat\SQA\script', },
        { id => 'jobs_dir', label => 'Directorio de jobs SQA', default => 'e:\apsdat\SQA\jobs', },
        { id => 'source_dir', label => 'Directorio de fuentes para SQA', default => 'src', },
        { id => 'builds_dir', label => 'Directorio de compilados para SQA', default => 'build', },
        { id => 'script_name', label => 'Nombre del script', default => 'Analyze.xml', },
        { id => 'purge_script_name', label => 'Nombre del script de purga', default => 'Purge.xml', },
        { id => 'plugin',      label => 'Nombre del plugin Checking', default => 'auditrep', },
        { id => 'extensiones', label => 'Extensiones de objetos compilados', default => 'exe,dll,ocx,class,pdb'},
        { id => 'exclusiones', label => 'Directorios excluidos en el tar de compilados', default => '\\PAC\\'},
        { id => 'indicadores_category', label=> 'Categoria del xml que contiene los indicadores', default=> 'Indicadores de modelo de calidad'},
        { id => 'indicadores_checkpoint', label=> 'Checkpoint del xml que contiene los indicadores', default=> 'Adecuado nivel de indicador Global'},
        { id => 'url', label=>'URL del informe de auditoria', default=> 'http://wbetest.bde.es/sqamain/plugindata/auditrep'},
        { id => 'url_checking', label=>'URL del servidor de checking', default=>'http://wbetest.bde.es/sqamain'},
        { id => 'url_reports', label=>'URL del servidor de checking para acceder a los reports', default=>'http://wbetest.bde.es/sqamain/plugindata/qaking'},
        { id => 'languages_file', label=>'Fichero de resultados de los pases de paquetes', default=>'languages.csv'},
        { id => 'tar_exe', label=>'Ejectutable tar.exe', default=> 'C:\Aps\SCM\cliente\tar.exe'},
        { id => 'jar_exe', label=>'Ejectutable jar.exe', default=> 'jar'},
        { id => 'remove_dir', label=>'Borrar directorio de pase SQA', default=> '1'},
        { id => 'debug', label=>'Solo recalcula analisis si 1', default=> '0'},
        { id => 'compile_script', label=>'Script de compilacion de aplicaciones de TEST J2EE', default=> 'e:\apsdat\SQA\JUnit\build.xml'},
        { id => 'file_mstest', label => 'Fichero de salida de resultados MSTEST', default => 'mstest.csv', },
        { id => 'file_junit', label => 'Fichero de salida de resultados JUnit', default => 'junit.csv', },
        { id => 'url_mstest', label=>'URL del servidor de checking para acceder a los reports de mstest', default=>'http://wbetest.bde.es/sqamain/plugindata/mstest'},
        { id => 'url_junit', label=>'URL del servidor de checking para acceder a los reports de junit', default=>'http://wbetest.bde.es/sqamain/plugindata/junit'},
        { id => 'file_mstest_errors', label => 'Fichero de salida de resultados MSTEST', default => 'report.html', },
        { id => 'file_mstest_coverage', label => 'Fichero de salida de resultados MSTEST coverage', default => 'data.html', },
        { id => 'file_junit_errors', label => 'Fichero de salida de resultados JUNIT', default => 'junit/index.html', },
        { id => 'file_junit_coverage', label => 'Fichero de salida de resultados JUnit', default => 'coverage/coverage.html', },       
        { id => 'run_sqa', label=>'Ejecutar analisis de SQA despues del pase', default=>'N'},
        { id => 'block_deployment', label=>'Bloquar pase si la ultima auditoria de SQA no esta aprobada (estado:OK)', default=>'N'},
        { id => 'url_scm', label=>'URL del servidor de scm', default=>'http://wbetest.bde.es/scm_inf'},
        { id => 'send_mail_sqa_owner', label=>'Se enviará correo al solicitante del análisis desde SQA', default=>'1'},
        { id => 'send_mail_scm_owner', label=>'Se enviará correo al solicitante del pase desde SCM', default=>'0'},
        { id => 'job.host', label => 'Host donde mirara si existen los jobs.', default => 'prusv063' },
        { id => 'job.port', label => 'El puerto del host <config.sqa.job.host>.', default => '58765' },
   ]
};

1;
