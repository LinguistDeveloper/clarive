=head1 BaselinerX::Model::SQA::checking

Model for comunicate with SonarSource throug its WebServices API

=cut

package BaselinerX::Model::SQA::checking;
use Moose;
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use HTTP::Request;
use LWP::UserAgent;

BEGIN { extends 'Catalyst::Model' }

sub grab_results {    # recupera resultados
	my ( $self, %p ) = @_;

	my $config     = Baseliner->model('ConfigStore')->get('config.sqa');
	my $sp         = $p{subproject};
	my $subproject = $sp->{subproject};
	my $project    = $p{project};
	my $nature     = $sp->{nature};
	my $bl         = $p{bl};
	my $job_id     = $p{job_id};
	my $xml        = $p{xml};
	my $html       = $p{html};
	my $mstest     = $p{mstest};
	my $junit      = $p{junit};
	my $level      = $p{level};
	my $username   = $p{username};

	my $sqam = 'BaselinerX::Model::SQA';

	$sqam->update_status( job_id => $job_id, status => 'ANALYZING RESULTS' );

	my $x = XML::Simple->new;
	my $data;
	my $row = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
	my $hash_data = _load ( $row->data );
	my $result;

	try {

		#$xml =~ s{>}{>\n}gs;
		$data = $x->XMLin($xml);
	}
	catch {
		$xml =~ s{>}{>\n}gs;
		$data = $x->XMLin($xml);
		$result = "SQA ERROR" unless $data;
	};

	my $global_hash = {};
	my $qualification;

	if ($data) {
		$result        = $data->{result}{value};
		$qualification = $data->{result}{qualification};
		my $ts         = $data->{timestamp};
		my $category   = $config->{indicadores_category};
		my $checkpoint = $config->{indicadores_checkpoint};
		my $global;

		if ( ref $data->{category}{$category} ) {
			$global =
			  $data->{category}{$category}{checkpoint}{$checkpoint}{violation};
		}
		else {
			$global = $data->{category}{checkpoint}{$checkpoint}{violation};
		}

		for my $linea ( _array $global ) {
			$linea =~ s/\"| |\n|.$//g;

			my ( $indicador, $valor ) = split ":", $linea;
			$valor =~ s/,/\./g;

			#$valor= sprintf("%.2f", $valor);
			$global_hash->{$indicador} = $valor;
		}

		if ( $nature =~ /NET|J2EE/ ) {
			my @fichero = ();

			my $URL                 = "";
			my $URL_prefix          = "";
			my $URL_suffix_errors   = "";
			my $URL_suffix_coverage = "";

			if ( $nature =~ /NET/ && $mstest ) {
				@fichero             = split "\n", $mstest;
				$URL_prefix          = $config->{url_mstest};
				$URL_suffix_errors   = $config->{file_mstest_errors};
				$URL_suffix_coverage = $config->{file_mstest_coverage};
			}
			elsif ( $nature =~ /J2EE/ && $junit ) {
				@fichero             = split "\n", $junit;
				$URL_prefix          = $config->{url_junit};
				$URL_suffix_errors   = $config->{file_junit_errors};
				$URL_suffix_coverage = $config->{file_junit_coverage};
			}
			if ( @fichero eq 2 ) {
				my @cabecera = split ";", $fichero[0];
				my @valores  = split ";", $fichero[1];
				my %datos    = {};
				my $i        = 0;
				foreach (@cabecera) {
					my $clave;
					if ( $_ =~ /cobertura/ ) {
						$clave = "cobertura";
					}
					else {
						$clave = $_;
					}
					$datos{$clave} = $valores[ $i++ ];
				}

				$URL =
				  $URL_prefix . $datos{proyecto} . "/" . $URL_suffix_coverage;
				$hash_data->{url_cobertura} = $URL;
				$URL =
				  $URL_prefix . $datos{proyecto} . "/" . $URL_suffix_errors;
				$hash_data->{url_errores} = $URL;

				$hash_data->{tests_errores}   = $datos{"% error/fallo"};
				$hash_data->{tests_cobertura} = $datos{"cobertura"};
			}
		}

		#_log _dump ( $data );

		$hash_data->{scores}      = $global;
		$hash_data->{html}        = $html;
		$hash_data->{indicadores} = $global_hash;
		$hash_data->{harvest_project} = $project;

		my $url       = $config->{url};
		my $file_html = $config->{file_html};

	#$hash_data->{ URL } = $url."/$bl/$project/$subproject/$nature/".$file_html;

		$hash_data->{prev_qualification} = $row->qualification;

		#$row->qualification( $qualification );
		$row->qualification( $global_hash->{GLOBAL} );
		$qualification = $global_hash->{GLOBAL};

		if ( $level && $level eq 'NAT' ) {
			$sqam->end_analysis_mail(
				bl            => $bl,
				project       => $project,
				subproject    => $subproject,
				nature        => $nature,
				qualification => $qualification,
				result        => _loc($result),
				job_id        => $job_id,
				status        => $result,
				indicators    => _dump $hash_data->{scores}
			);
			if ( $bl =~ /$config->{states_to_create_issue}/ && $result eq 'FAILURE' ) {
				my ($msg, $id) = Baseliner::Model::Issue->update({
					action       => 'add',
                    created_by  => $username,
                    title      => "X",
                    description => "X",
				});
				($msg, $id) = Baseliner::Model::Issue->update({
					action       => 'update',
                    id => $id,
					title       => 'SQA Issue '.$id,
                    description => "El análisis de calidad de $project/$subproject/$nature no ha superado la auditoría. Indicador global: $qualification",
				});
			}
		}
	} else {
		$hash_data->{xml} = $xml;
		write_sqa_error( job_id => $job_id, html => $xml, type => "pre", reason => "Ha ocurrido un error al interpretar el XML de resultado del an&aacute;lisis.  Consulte con el administrador de SQA" );
		$result = "SQA ERROR";
	}

	$row->data( _dump $hash_data );
	$row->update;

	$sqam->update_status( job_id => $job_id, status => $result, tsend => 1 );

}

1;