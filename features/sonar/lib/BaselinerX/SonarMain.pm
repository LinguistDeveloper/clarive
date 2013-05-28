=head1 BaselinerX::SonarMain

Configuration of the feature to connect to sonar.

=head2 Configuration variables (config.sonar)

	* url: URL to access sonar server

=cut

package BaselinerX::SonarMain;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

##Configuración de sonar
register 'config.sonar' => {
	metadata => [
	    {id => 'url', label => 'URL del servidor de sonar', default => 'http://localhost:9000'},
	    {
	        id    => 'metrics',
	        label => 'Métricas que se recuperarán para analizar la calidad',
	        default =>
	            'complexity,duplications,violations_density,violations,blocker_violations,major_violations,critical_violations,minor_violations,info_violations'
	    },
	    {
	        id    => 'metrics_limits',
	        label => 'Límites aceptables de cada métrica',
	        type => 'hash',
	        default =>
	            "violations_density => { value => '85,0', comp => '<'},
	             blocker_violations => { value => '0', comp => '>'},
	             critical_violations => { value => '0', comp => '>'}"
	    },
	    {
	        id    => 'metrics_stable',
	        label => 'Métricas que no deberán aumentar entre análisis',
	        default => 'blocker_violations,critical_violations'
	    },
	    # {
	    #     id    => 'not_new_violations',
	    #     label => 'Evidencias que no deberán aumentar entre análisis (nuevas evidencias en el último análisis)',
	    #     default => 'blocker,critical,major'
	    # },
	    {
	        id    => 'global_indicator',
	        label => 'Métrica que se debe mostrar como indicador global',
	        default => 'violations_density'
	    },
	    {
	        id    => 'use_auth',
	        label => 'Sonar con autentificación o no',
	        default => '0'
	    },
	    	    {
	        id    => 'sonar_user',
	        label => 'Usuario de sonar',
	        default => 'admin'
	    },
	    	    {
	        id    => 'sonar_password',
	        label => 'Contraseña de sonar',
	        default => 'admin'
	    },
	    	    {
	        id    => 'resource_prefix',
	        label => 'Prefijo de las claves de recurso',
	        default => 'AUT:'
	    },
    ]
};

1;