package BaselinerX::Job::Service::FootprintElements;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Filesys;
use Baseliner::Core::Version;
use BaselinerX::Session::ConfigState;
use BaselinerX::Job::Elements;
use BaselinerX::Job::Element;
use YAML::Syck;
use File::Spec;
use Data::Dumper;
use Path::Class;
use XML::Smart;
use Try::Tiny;
use Encode;
use Encode::Guess qw/utf8/;
use Baseliner::Legacy;

with 'Baseliner::Role::Service';

## COMPILA 
register 'service.job.footprint' => {
    name    => _loc( 'Footprint elements' ),
    handler => sub {
        my ( $self, $c ) = @_;

        my $job       = $c->stash->{job};
        my $log       = $job->logger;
        my $job_stash = $job->job_stash;
        my $elements  = $job_stash->{elements};
        my $path      = $job->job_stash->{path};

        my @eltos = $elements->list( '' );


       	my %MODIFICADOS;
		my @FOUND = `find '$path' -name "*" -type f -exec grep -l '\@(#)' {} \\;`;
		if( $? ne 0 ) {
			$log->warn("Footprinting ha fallado. Compruebe el log del Dispatcher para ver los errores.");
			return;
		}
		my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
		$Year += 1900;
		$Month +=1;
	
		my $now= Class::Date->new([$Year,$Month,$Day,$Hour, $Minute]);

		foreach my $filename (@FOUND) {
			my $elto_found = 0;
			chop $filename;

			my $EnvironmentName;
			my $elto_state;
			my $elto_name;
			my $elto_version;
			my $elto_path;
			my $elto_package;
			my $elto_user;
			my $elto_date;
			my $elto_pase;
			my $pase_date;

			for ( @eltos ) {
				if ( $path.$_->fullpath eq $filename) {
					$_->path =~ /^\/(.*?)\//;
					$EnvironmentName = $1;
					$elto_state = $job->bl;
					$elto_name = $_->name;
					$elto_version = $_->version;
					$elto_path = $_->path;
					$elto_package = $_->package;
					$elto_user = $_->modifier;
					$elto_date = $_->modified_on;
					$elto_pase = $job->job_data->{name};
					$pase_date = $now;
					$elto_found = 1;
					last;
				}
			}
			#logdebug "Footprinting fichero:\n'$filename'\n";
			if ( $elto_found ) {			
				if( (-f $filename) && (-T $filename)) {
					my $newdata = "";
					open FP,"<$filename";
					while(<FP>) {
						if( /\@\(\#\)/ ) {
							if( !$MODIFICADOS{ $filename} ) {
								$MODIFICADOS{ $filename } = "1";
							}

							s/\@\(\#\)//g;
							s/\[state\s*\]/$elto_state/gi;
							s/\[project\s*\]/$EnvironmentName/gi if($EnvironmentName);
							s/\[item\s*\]/$elto_name/gi;
							s/\[version\s*\]/$elto_version/gi;
							s/\[viewpath\s*\]/$elto_path/gi;
							s/\[package\s*\]/$elto_package/gi;
							s/\[user\s*\]/$elto_user/gi;
							s/\[date\s*\]/$elto_date/gi;
							s/\[pase\s*\]/$elto_pase/gi;
							s/\[pasefechahora\s*\]/$pase_date/gi;
						}
						$newdata .= $_;
					}
					close FP;
					if( $newdata ) {
						open FPNEW,">$filename";
						binmode FPNEW;
						print FPNEW $newdata;
						close FPNEW;
						$log->debug("Fichero $filename modificado", data => $newdata);
					}
				}
			} else {
				$log->warn("No se han encontrado datos para footprinting del fichero $filename");
			}
		}
		$log->info("Footprinting terminado. Listado de ".scalar(keys(%MODIFICADOS))." elemento(s) modificado(s):", data => join("\n",keys(%MODIFICADOS)));
	    }
};

1;