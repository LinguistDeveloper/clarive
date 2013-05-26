
=head1 BaselinerX::Model::SQA::sonar

Model for comunicate with SonarSource throug its WebServices API

=cut

package BaselinerX::Model::SQA::sonar;
use Moose;
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use HTTP::Request;
use LWP::UserAgent;
use URI;
use IO::CaptureOutput qw/capture_exec/;
use JSON::Any;

BEGIN { extends 'Catalyst::Model' }

=head2 run_analysis

Run an analysis with sonar and return results needed for Clarive SQA interface

Example: 
    BaselinerX::Model::SQA::sonar->run_analysis( 
        run_type => 'runner',
        resource => 'PROD:XXX:COBOL:COBOL1',
        version => '1.0',
        filter => 'cobol1.cbl',
        language => 'cobol',
        source_dir => '/Users/rick/dev/testsonar/COBOL'
    );

Input parameters:
    
    * resource -> name of the resource to be analyzed (i.e. TEST:XXX:COBOL:COBOL1)
    * compare_with -> name of the resource to be compared with (i.e. PROD:XXX:COBOL:COBOL1)
    * source_dir -> absolute path to the directory in the server to the sources to analyze (i.e. /temp/clarive/job_121212/XXX/COBOL/PGMCOBOL1)
    * run_type -> type of execution.  Can be ant, maven or runner.  Each of them will execute its builder with the correct parameters.
                  Ant and Maven will use their respective template in /templates (ant.xml or maven.xml)
    * user -> user that is requesting the analysis
    * bl -> baseline for which the analysis is requested 
    * project -> project for the analysis
    * subproject -> name of the subproject
    * language -> technology or nature for the analysis

Output data:
    
    Returns an array with the following information:
    
    ( ret, rc ) where ret: Command Output, rc: return code
=cut

sub run_analysis {
    my ( $self, %p ) = @_;

    my $config     = Baseliner->model( 'ConfigStore' )->get( 'config.sqa' );
    my $config_sonar     = Baseliner->model( 'ConfigStore' )->get( 'config.sonar' );
    my $source_dir = $p{source_dir};
    my $resource   = $p{resource};
    my $run_type   = $p{run_type};
    my $user       = $p{user};
    my $language   = $p{language};
    my $version    = $p{version};
    my $filter     = $p{filter};

    my $cmd;

    if ( $run_type eq 'runner' ) {

        # sonar-runner -Dsonar.projectKey=TEST:XXX:COBOL:COBOL1
        #              -Dsonar.projectName=TEST:XXX:COBOL:COBOL1
        #              -Dsonar.projectVersion=4.0
        #              -Dsources=/Users/rick/dev/testsonar/COBOL
        #              -Dsonar.language=cobol
        #              -Dsonar.cobol.file.suffixes=cobol1.cbl
        $cmd = 'sonar-runner';
        $cmd .= " -Dsonar.projectKey=".$config_sonar->{resource_prefix}."$resource";
        $cmd .= " -Dsonar.projectName=$resource";
        $cmd .= " -Dsonar.projectVersion=$version";
        $cmd .= " -Dsources=$source_dir";
        $cmd .= " -Dsonar.language=$language";
        $cmd .= " -Dsonar.cobol.file.suffixes=$filter";
    } elsif ( $run_type eq 'ant' ) {

    } elsif ( $run_type eq 'maven' ) {

    } else {
        die _loc( 'Invalid sonar execution type: %1', $run_type );
    }

    my ( $stdout, $stderr, $success, $rc ) = capture_exec( $cmd );
    $rc = $rc >> 8;

    return ( $stdout . $stderr, $rc );
} ## end sub run_analysis

=head2 get_results

Get results of the project compared to the one given if exists or absolute last results if compare_with not filled.

Example: 
    BaselinerX::Model::SQA::sonar->get_results(
        resource => 'TEST:XXX:COBOL:COBOL1',
        [compare_with => 'PROD:XXX:COBOL:COBOL1' || 'previous']
    )

Input parameters:
    
    * resource -> name of the resource to be analyzed (i.e. TEST:XXX:COBOL:COBOL1)

Output data:
    
    Returns a structure with the following information:

    ---
    resource: TEST:XXX:COBOL:PGMCOBOL1
    indicators:
      blocker_violations: 0
      complexity: 20
      critical_violations: 0
      info_violations: 0
      major_violations: 6
      minor_violations: 1
      violations: 7
      violations_density: '86.2'
    audit: OK (evaluated depending on the rules defined in config)
    message: (Message in case of FAILURE)
    global: 86.2 (defined in config.sonar.global_indicator)
=cut

sub get_results {
    my ( $self, %p ) = @_;

    my $config       = Baseliner->model( 'ConfigStore' )->get( 'config.sonar' );
    my $resource     = $p{resource};
    my $compare_with = $p{compare_with};
    my $results;

    try {
        $results = $self->get_last_results( resource => $resource );

        if ( $compare_with ) {
            my $old_results;
            if ( $compare_with eq 'previous' ) {
                $old_results =
                    $self->get_last_results( resource => $resource, previous_analysis => 1 );
            } else {
                $old_results = $self->get_last_results( resource => $compare_with );
            }
            if ( $old_results && $results ) {
                ( $results->{audit}, $results->{message} ) = $self->compare_results(
                    new => $results->{indicators},
                    old => $old_results->{indicators}
                );
            } ## end if ( $old_results && $results)
        } else {
            if ( $results ) {
                ( $results->{audit}, $results->{message} ) =
                    $self->get_audit( indicators => $results->{indicators} );
            }
        } ## end else [ if ( $compare_with ) ]
        if ( $results->{indicators} && $results->{indicators}->{$config->{global_indicator}} ) {
            $results->{global} = $results->{indicators}->{$config->{global_indicator}};
        }
    } ## end try
    catch {
        _log "Error getting results: " . shift;
    };
    return $results;
} ## end sub get_results


=head2 get_version_results

Get results of the specific version of the project

Example: 
    BaselinerX::Model::SQA::sonar->get_results(
        resource => 'TEST:XXX:COBOL:COBOL1',
        version => '1.0'
    )

Input parameters:
    
    * resource -> name of the resource to be analyzed (i.e. TEST:XXX:COBOL:COBOL1)
    * compare_with -> name of the resource to be compared with (i.e. PROD:XXX:COBOL:COBOL1) or 'previous' that will compare with its previous analysis.

Output data:
    
    Returns a structure with the following information:

    ---
    resource: TEST:XXX:COBOL:PGMCOBOL1
    indicators:
      blocker_violations: 0
      complexity: 20
      critical_violations: 0
      info_violations: 0
      major_violations: 6
      minor_violations: 1
      violations: 7
      violations_density: '86.2'
    global: 86.2 (defined in config.sonar.global_indicator)
=cut

sub get_version_results {
    my ( $self, %p ) = @_;

    my $config = Baseliner->model( 'ConfigStore' )->get( 'config.sonar' );
    _check_parameters( \%p, qw/resource/ );
    my $resource = $p{resource};
    my $version  = $p{version};
    my $last_prefix = $p{last_prefix};
    my $results;

    try {
        my ($version_date, $real_version) = $self->_get_version_date( $config, resource => $resource, version => $version, last_prefix => $last_prefix);

        if ( $version_date ) {
            $results = $self->get_first_results( resource => $resource, from_date => $version_date );
            $results->{version} = $real_version;
        }

        if ( $results->{indicators} && $results->{indicators}->{$config->{global_indicator}} ) {
            $results->{global} = $results->{indicators}->{$config->{global_indicator}};
        }
    } ## end try
    catch {
        _log "Error getting results: " . shift;
    };
    return $results;
} ## end sub get_version_results


=head2 get_last_results

Get results of the project.  If previous_analysis is specified it returns results of the nth previous_analysis

Example: 
    BaselinerX::Model::SQA::sonar->get_last_results(
        resource => 'TEST:XXX:COBOL:COBOL1',
        [previous_analysis => N]
    )

Input parameters:
    
    * resource -> name of the resource to be analyzed (i.e. TEST:XXX:COBOL:COBOL1)
    * previous_analysis -> number of analysis to skip

Output data:
    
    Returns a structure with the following information:

    ---
    date: 2012-05-28T23:57:27+0200
    indicators: 
      blocker_violations: 0
      complexity: 20
      critical_violations: 0
      info_violations: 0
      major_violations: 7
      minor_violations: 1
      violations: 8
      violations_density: '84.1'
=cut

sub get_last_results { 
    my ( $self, %p ) = @_;

    my $config            = Baseliner->model( 'ConfigStore' )->get( 'config.sonar' );
    my $url               = $config->{url} . '/api/timemachine';
    my $resource          = $p{resource};
    my $previous_analysis = $p{previous_analysis} || 0;
    my $args              = {
        resource => $config->{resource_prefix}.$resource,
        format   => 'json',
        metrics  => $config->{metrics},
    };

    my $response = $self->_call_ws( $config, {url => $url, args => $args} );


    my @projects = _array $response;

    my @analysis = _array $projects[ 0 ]->{cells};
    my @metrics  = _array $projects[ 0 ]->{cols};

    my $history = {};

    for ( 0 .. $previous_analysis - 1 ) {

        #_log "Saltando $_ analysis";
        pop @analysis;
    }

    my $last_analysis = pop @analysis;

    #_log _dump $last_analysis;

    my $i             = 0;
    my @values        = _array $last_analysis->{v};
    my $paired_values = {};

    for my $value ( @values ) {
        $paired_values->{$metrics[ $i ]->{metric}} = $value;
        $i++;
    }
    $history->{indicators} = $paired_values;
    $history->{date}       = $last_analysis->{d};
    return $history;
} ## end sub get_last_results

=head2 get_first_results

Get first results of the project from a given timestamp

Example: 
    BaselinerX::Model::SQA::sonar->get_first_results(
        resource => 'TEST:XXX:COBOL:COBOL1',
        from_date => '2012-06-08T13:08:36+0200'
    )

Input parameters:
    
    * resource -> name of the resource to be analyzed (i.e. TEST:XXX:COBOL:COBOL1)
    * from_date -> ISO-8601 datetime (inclusive)

Output data:
    
    Returns a structure with the following information:

    ---
    date: 2012-05-28T23:57:27+0200
    indicators: 
      blocker_violations: 0
      complexity: 20
      critical_violations: 0
      info_violations: 0
      major_violations: 7
      minor_violations: 1
      violations: 8
      violations_density: '84.1'
=cut

sub get_first_results { 
    my ( $self, %p ) = @_;

    my $config            = Baseliner->model( 'ConfigStore' )->get( 'config.sonar' );
    my $url               = $config->{url} . '/api/timemachine';
    my $resource          = $p{resource};
    my $from_date         = $p{from_date};

    my $args              = {
        resource => $config->{resource_prefix}.$resource,
        fromDateTime => $from_date,
        format   => 'json',
        metrics  => $config->{metrics},
    };

    my $response = $self->_call_ws( $config, {url => $url, args => $args} );

    my @projects = _array $response;

    my @analysis = _array $projects[ 0 ]->{cells};
    my @metrics  = _array $projects[ 0 ]->{cols};

    my $history = {};

    my $first_analysis = shift @analysis;

    #_log _dump $last_analysis;

    my $i             = 0;
    my @values        = _array $first_analysis->{v};
    my $paired_values = {};

    for my $value ( @values ) {
        $paired_values->{$metrics[ $i ]->{metric}} = $value;
        $i++;
    }
    $history->{indicators} = $paired_values;
    $history->{date}       = $first_analysis->{d};
    return $history;
} ## end sub get_last_results

sub compare_results {
    my ( $self, %p ) = @_;

    my $config            = Baseliner->model( 'ConfigStore' )->get( 'config.sonar' );
    my $new            = $p{new};
    my $old            = $p{old};
    my $resource = $p{resource};
    my $metrics_stable = $config->{metrics_stable};
    my $audit          = 'OK';
    my $message;

    for my $metric ( split ",", $metrics_stable ) {
        _log "Evaluating $metric.  New: $new->{$metric}, Old: $old->{$metric}";
        if ( $new->{$metric} gt $old->{$metric} ) {
            $audit = "FAILURE";
            $message .= _loc( "Metric %1 does not pass the rule for QA ( %3 greater than %2 )",
                $metric, $old->{$metric}, $new->{$metric} )."\n";
        }
    } ## end for my $metric ( split ...)
    return {audit => $audit, message => $message, link => $config->{url}."/dashboard/index/".$config->{resource_prefix}.$resource};
} ## end sub compare_results

sub _get_version_date {
    my ( $self, $config, %p ) = @_;

    my $url      = $config->{url} . '/api/events';
    my $resource = $p{resource};
    my $version  = $p{version};
    my $last_prefix = $p{last_prefix};
    my $version_date = '';
    my $real_version;

    my $args     = {
        resource => $config->{resource_prefix}.$resource,
        format   => 'json',
        categories  => 'Version',
    };
    my $response = $self->_call_ws( $config, {url => $url, args => $args} );

    for ( _array $response ) {
        if ( $last_prefix ) {
            if ( $_->{n} =~ /^$last_prefix/ ) {
                $version_date = $_->{dt};
                $real_version = $_->{n};
               last;
            }
        } else {
            if ( $_->{n} =~ /^$version/ ) {
                $version_date = $_->{dt};
                $real_version = $_->{n};
                last;
            }
        }
    }
    return ($version_date, $real_version);
} ## end sub get_new_violations

sub get_new_violations {
    my ( $self, $config, %p ) = @_;

    my $url      = $config->{url} . '/api/violations';
    my $resource = $p{resource};
    my $args     = {
        resource => $config->{resource_prefix}.$resource,
        format   => 'json',
        metrics  => $config->{metrics},
    };
    my $response = $self->_call_ws( $config, {url => $url, args => $args} );

    return $response;
} ## end sub get_new_violations

sub get_audit {
    my ( $self, %p ) = @_;

    my $indicators     = $p{indicators};
    my $resource    = $p{resource};
    my $config         = Baseliner->model( 'ConfigStore' )->get( 'config.sonar' );
    my $metrics_limits = $config->{metrics_limits};
    my $audit          = 'OK';
    my $message;

    for my $metric ( keys %{$metrics_limits || {}} ) {
        _log "Evaluating $metric.  Checking if $indicators->{$metric} $metrics_limits->{$metric}->{comp} $metrics_limits->{$metric}->{value}";
        if (
            eval(
                "$indicators->{$metric} $metrics_limits->{$metric}->{comp} $metrics_limits->{$metric}->{value}"
            )
            )
        {
            $audit = "FAILURE";
            $message .= _loc(
                "Metric %1 does not pass the rule for QA (%4 is %2 %3 )",
                $metric,
                $metrics_limits->{$metric}->{comp},
                $metrics_limits->{$metric}->{value},
                $indicators->{$metric}
            )."\n";
        } ## end if ( eval( ...))
    } ## end for my $metric ( keys %...)
    return {audit => $audit, message => $message, link => $config->{url}."/dashboard/index/".$config->{resource_prefix}.$resource};
} ## end sub _get_audit


sub _call_ws {
    my ( $self, $config, $p ) = @_;

    my $url  = $p->{url};
    my $args = $p->{args};

    my $uri = URI->new( $url );
    $uri->query_form( $args );
    my $request = HTTP::Request->new( GET => $uri );
    $request->authorization_basic($config->{sonar_user}, $config->{sonar_password}) if $config->{use_auth};
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    my $response = $ua->request( $request );

    die sprintf qq/HTTP request failed: %s/, $response->status_line
        unless $response->is_success;

    my $content = $response->content;
    my $json    = JSON::Any->new();

    $response = $json->decode( $content );

    return $response;
} ## end sub _call_ws

=head2 grab_results

Example imput:
    --- 
    audit: 
      audit: OK
      message: ~
    date: 2012-05-31T01:05:40+0200
    global: 100
    indicators: 
      blocker_violations: 0
      complexity: 1
      critical_violations: 0
      info_violations: 0
      major_violations: 0
      minor_violations: 0
      violations: 0
      violations_density: 100
    message: ~
=cut

sub grab_results {
    my ( $self, %p ) = @_;

    my $results  = $p{results};
    my $resource = $p{resource};
    my $job_id   = $p{job_id};

    my $sqam = 'BaselinerX::Model::SQA';
    my $row  = Baseliner->model( 'Baseliner::BaliSqa' )->find( $job_id );
    $sqam->update_status( job_id => $job_id, status => 'ANALYZING RESULTS' );

    my $hash_data = _load( $row->data );

    $hash_data->{indicadores} = $results->{indicators};
    push @{$hash_data->{scores}},
        map { $_ . ":" . $results->{indicators}->{$_} } keys %{$results->{indicators}};
    $hash_data->{prev_qualification} = $row->qualification;

    #http://localhost:9000/dashboard/index/TEST:XXX:HOST:COBOL1?did=10001
    $hash_data->{link} = 'http://localhost:9000/dashboard/index/' . $resource . '?did=10001';
    $row->qualification( $results->{global} );

    _log "********* Escribiendo estos datos: \n" . $row->data( _dump $hash_data );
    $row->update;

    $sqam->update_status( job_id => $job_id, status => $results->{audit}->{audit}, tsend => 1 );
} ## end sub grab_results
1;
