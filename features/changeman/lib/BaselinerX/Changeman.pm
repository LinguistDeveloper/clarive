package BaselinerX::Changeman;
=head1 

BaselinerX::Changeman - Changeman USS interface

=head1 DESCRIPTION

This module is the main bridge between Baseliner and Changeman.

    use BaselinerX::Changeman;
    my $chm = BaselinerX::Changeman->new( host=>'mainframe', port=>623,
        user=>'chmuser', 
        password=>sub{ passgen() } );
    my $pkgs = $chm->xml_pkgs( filter=>'*', to_env=>'PROD', job_type=>'p', projects=>['XXX' ] );

=head1 METHODS 

=cut
use Moose;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use MVS::USS;
use Try::Tiny;
use Encode;

has 'host' => ( is=>'rw', isa=>'Str', required=>1 );
has 'port' => ( is=>'rw', isa=>'Str', required=>1, default=>58765 );
has 'key' => ( is=>'rw', isa=>'Str|CodeRef', default=>'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');

=head2 list_pkgs ( filter=>Str, job_type=> p|m, to_env=> 'PROD|PREP...', projects=>Array )

Get a package using a USS REXX routine.

=cut
sub get_pkg {
    my ($self, %args) = @_;
    # _log _dump %args;
    
    my $filter = $args{filter} || '*';
    my $cmd = 'llpackage ' . $filter;

    return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.ListItems', frequency=>3} );
}

=head2 xml_getPkg

Wrapper for list_pkgs to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   PackList: 
     Package: 
        - pkg1
        - pkg2 
        - ...
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_getPkg {
    my ($self, %args) = @_;
    my $xml_str = $self->get_pkg( %args );
    # _log $xml_str;
    require XML::Simple;
    my $xml = XML::Simple::XMLin( $xml_str, ForceArray => [qw(Package)] );

    # _log "list_pkgs: " . _dump $xml;

    $xml
}

=head2 list_pkgs ( filter=>Str, job_type=> p|m, to_env=> 'PROD|PREP...', projects=>Array )

List packages using a USS REXX routine.

=cut
sub list_pkgs {
    my ($self, %args) = @_;
    # _log _dump %args;
    
    my $filter = '"'.($args{filter} || '*').'"';
    my $job_type = $args{job_type} || 'p';
    my $to = $args{to_env};
    my $apps = join ' ', _array( $args{projects} );
    my $cmd=undef;
    my $ret=undef;
   
    for ( _array $to) {
        $cmd = 'll01 ' . join(',', $filter, $job_type, $_, $apps ) ;
        _debug "Invoco a la lista: $cmd"; 
        my $xml= $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.ListItems', frequency=>1} );

        if ( ref $ret ) {
            for ($xml->{PackList}->{Package}) {
                print "Adding package " . _dump $_ . " to XML";
                $ret->{PackList}->{Package} = $_;
            }
        } else {
            $ret = $xml;
        }
    }
    return $ret;
}

=head2 xml_pkgs

Wrapper for list_pkgs to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   PackList: 
     Package: 
        - pkg1
        - pkg2 
        - ...
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_pkgs {
    my ($self, %args) = @_;
    _log "xml_pkgs";
    my $xml_str = $self->list_pkgs( %args );
    _log $xml_str;
    require XML::Simple;
    my $xml = XML::Simple::XMLin( $xml_str, ForceArray => [qw(Package)] );

    _log "list_pkgs: " . _dump $xml;

    $xml
}

=head2 $chm->xml_addToJob(job=>$job_name, items=>[ARRAY], options=>[ARRAY]) ;

Associates packages to SCM job

=cut
sub addToJob {
    my ($self, %args) = @_;
    my $job = Baseliner->model('Baseliner::BaliJob')->search({ name=>$args{job} })->first;

    # N.TEST-00000250,p|m,PREP|FORM|PROD, R, YYYYMMDDHHMISS, PACKAGE_1, PACKAGE_2,... PACKAGE_N
    my $pase = $job->name;
    my $date = $job->starttime->strftime("%Y%m%d%H%M%S");
    my $job_type = $job->type eq 'promote'?'p':'m';
    my $to = $job->bl;
    my $refresh='R';
    my $items=undef;

    foreach ( _array $args{items} ) {
        $items.=$_->{item}."," if $_->{provider} eq 'namespace.changeman.package';
    }
    chop $items;

    my $cmd = 'll02 ' . join(',', $pase, $job_type, $to, $refresh, $date, $items ) ;

    return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', frequency=>3} );
}

=head2 xml_addToJob

Wrapper for list_pkgs to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_addToJob {
    my ($self, %args) = @_;
    my $xml_str = $self->addToJob( %args );
    require XML::Simple;
    my $xml = XML::Simple::XMLin( $xml_str );

    # _log "addToJob: " . _dump $xml;
    
    $xml
}

=head2 cancelJob ( pase=>Str, job_type=> p|m, to_env=> 'PROD|PREP|FORM', urgente=>'S|N', packages=>Array )

Removes association betwen job and packages

=cut
sub cancelJob {
    my ($self, %args) = @_;
    my $job = Baseliner->model('Baseliner::BaliJob')->search({ name=>$args{job} })->first;
    
    # N.TEST-00000250, PACKAGE_1, PACKAGE_2,... PACKAGE_N
    my $pase = $job->name;
    my $job_type = $job->type eq 'promote'?'p':'m';
    my $to = $job->bl;

    my $cmd = 'll05 ' . join(',', $job_type, $to, $pase, _array( $args{items} ) ) ;

    if ( $args{jobName} ) {
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', job=>$args{jobName}, log=>$args{logger}, frequency=>3} );
    } else {
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', frequency=>3} );
    }
}

=head2 xml_addToJob

Wrapper for cancelJob to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_cancelJob {
    my ($self, %args) = @_;
    my $xml_str = $self->cancelJob( %args );
    require XML::Simple;
    my $xml = try {
        XML::Simple::XMLin( $xml_str );
    } catch {
        my $err = shift;
        _throw _loc_xml_chm( $err, 'cancel_job', $xml_str, _dump(\%args)  );
    };


    # _log "cancelJob: " . _dump $xml;

    $xml
}

=head2 $chm->runPackageInJob(job=>$job_name, package=>$package, job_type=>$job_type, bl=>$job_bl) ;

Execute a Changeman Package

=cut
sub runPackageInJob {
    my ($self, %args) = @_;
    
    print "runPackageInJob: "._dump %args;

    # p|m, PREP|FORM|PROD, PACKAGE_1, N.TEST-00000250 
    my $job_type = $args{job_type};
    my $job = $args{job};
    my $to = $args{bl};
    my $package = $args{package};
    
    my $cmd = 'll03 ' . join(',', $job_type, $to, $package, $job ) ;
    
    if ( $args{jobName} ) {
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', job=>$args{jobName}, log=>$args{logger}, frequency=>3} );
    } else {
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', frequency=>3} );
    }
}

=head2 xml_runPackageInJob

Wrapper for runPackageInJob to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_runPackageInJob {
    my ($self, %args) = @_;
    my $xml_str = $self->runPackageInJob( %args );
    require XML::Simple;
    my $xml = try {
        XML::Simple::XMLin( $xml_str );
    } catch {
        my $err = shift;
        _throw _loc_xml_chm( $err, 'runpackageinjob', $xml_str, _dump(\%args) );
    };

    # _log "runPackageInJob: " . _dump $xml;
    
    $xml
}

=head2 $chm->refreshLLA() ;

Refresh LLA

=cut
sub refreshLLA {
    my ($self, %args) = @_;
    _throw 'Missing sites' unless length $args{sites};

    my $cmd = 'llreflla '. $args{sites};
    
    if ( $args{jobName} ) {
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', job=>$args{jobName}, log=>$args{logger}, frequency=>3} );
    } else {
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', frequency=>3} );
    }
}

=head2 xml_refreshLLA

Wrapper for refreshLLA to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_refreshLLA {
    my ($self, %args) = @_;
    my $xml_str = $self->refreshLLA( %args );
    require XML::Simple;
    my $xml = try {
        XML::Simple::XMLin( $xml_str );
    } catch {
        my $err = shift;
        _throw _loc_xml_chm( $err, 'refreshlla', $xml_str, _dump(\%args)  );
    };

    # _log "refreshLLA: " . _dump $xml;
    
    $xml
}


=head2 cache

Recover Changeman cache

=cut
sub cache {
    my ($self) = @_;
    
    my $cmd = 'llcache';

    return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.ListItems', frequency=>3} );
}

=head2 xml_cache

Wrapper for cache to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_cache {
    my ($self, %args) = @_;
    my $xml_str = $self->cache();
    # _log "cache: " . _dump $xml_str;
    require XML::Simple;
    # my $xml = XML::Simple::XMLin( $xml_str );
    my $xml = try {
        XML::Simple::XMLin( $xml_str, ForceArray => [qw(Package MarchaAtras Promote content)] );
    } catch {
        my $err = shift;
        _throw _loc_xml_chm( $err, 'cache', $xml_str );
    };

    # # _log "cache: " . _dump $xml;

    $xml
}

=head2 listApplications

Recover Changeman applications

=cut
sub listApplications {
    my ($self) = @_;
    my $cmd = 'llaplics';

    return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.ListItems', frequency=>3} );
}
=head2 xml_applications

Wrapper for cache to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_applications {
    my ($self, %args) = @_;
    my $xml_str = $self->listApplications();
    # _log "applications: " . _dump $xml_str;
    require XML::Simple;
    my $xml = try { 
        XML::Simple::XMLin( $xml_str );
    } catch {
        my $err = shift;
        _throw _loc_xml_chm( $err, 'applications', $xml_str );
    };

    # _log "applications: " . _dump $xml;

    $xml
}

=head2 listComponents

Recover Changeman Package components

=cut
sub listComponents {
    my ($self, %args) = @_;
    my $package = $args{package};
    my $cmd = 'llcomponentes ' . $package;

    #_log "components: $cmd";
    if ( defined $args{jobName} ) {
        _debug "1";
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.ListItems', job=>$args{jobName}, log=>$args{logger}, frequency=>3} );
    } else {
        _debug "2";
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.ListItems', frequency=>3} );
    }
}
=head2 xml_components

Wrapper for cache to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_components {
    my ($self, %args) = @_;
    my $xml_str = $self->listComponents( %args );
    #_log "Components: " . _dump $xml_str;
    require XML::Simple;
    my $xml = try {
        XML::Simple::XMLin( $xml_str, ForceArray => [qw(result)] );
    } catch {
        my $err = shift;
        _throw _loc_xml_chm( $err, 'components', $xml_str, _dump(\%args)  );
    };


    #_log "Components: " . _dump $xml;

    $xml
}


=head2 getUser

Recover user for changeman job

=cut
sub getUser {
    my ($self, %args) = @_;
    my $package = $args{package};
    my $cmd = 'll07 ' . $package;

    #_log "components: $cmd";
    if ( defined $args{jobName} ) {
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', job=>$args{jobName}, log=>$args{logger}, frequency=>3} );
    } else {
        return $self->execute_cmd( {cmd=>$cmd, sem=>'CHM.JobAction', frequency=>3} );
    }
}
=head2 xml_getUser

Wrapper for cache to return the generated xml 
as a Hash with the following structure:

   Name: "Changeman service name"
   ReasonCode: 00
   ReturnCode: 00
   Xmlserv: {}

=cut
sub xml_getUser {
    my ($self, %args) = @_;
    my $xml_str = $self->getUser( %args );
    _log "getUser " . _dump $xml_str;
    require XML::Simple;
    my $xml = try {
        XML::Simple::XMLin( $xml_str, ForceArray => [qw(sites)] );
    } catch {
        my $err = shift;
        _throw _loc_xml_chm( $err, 'getUser', $xml_str, _dump(\%args)  );
    };


    #_log "Components: " . _dump $xml;

    $xml
}

# ( xmlerr, modulename, data_received )
sub _loc_xml_chm {
   my ( $xmlerr, $modulename, $data_received, $sent ) = @_;
   $xmlerr = 'empty data' if $xmlerr eq 'File does not exist';
   my $log_msg = _loc('Changeman xml parse error (Module: %1. Data received: %2): %3. Data sent: %4', $modulename, $data_received, $xmlerr, $sent );
   BaselinerX::ChangemanUtils->log( _loc('Changeman xml parse error in %1', $modulename),
       data_received=>$data_received, xmlerr=>$xmlerr, sent=>$sent, );
   $log_msg;
}

sub execute_cmd {
    my ($self, $args) = @_;

    my ($oper,$top,$xml,$basecmd);

    my $utildir = Baseliner->model('ConfigStore')->get( 'config.changeman.connection' )->{utildir};
    my $cmd=File::Spec->catfile($utildir, $args->{cmd});

    my $who = $args->{job}||'changeman benchmark';
    my $logger = $args->{log}||undef;


_debug "CHM CMD: $cmd";
    CMD: {
### Critical region
        #my $sem = Baseliner->model('Semaphores')->request( sem=>$args->{sem}, who=>$who, logger=>$logger, frequency=>$args->{frequency} );
        my $sem = Baseliner->model("Semaphores")->request( sem=>$args->{sem}, who=>$who, logger=>$logger, bl=>"*", no_wait=>1); 

        my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$self->host, port=>$self->port, key=>$self->key);

        $logger->debug( _loc("Running"), data=>$cmd ) if defined $logger;
        my ($RC,$RET)=$bx->execute( $cmd );
        my @cal = caller(1);
        $oper = $cal[3];  # calling sub name 
        if( ref $oper ) {
            $oper='__ANON__';
        } else {
            $oper=~s{^.*::(.*?)$}{$1}g;
        }
        $RET =~ s/IKJ566(.*?)\n//s;
        Encode::from_to($RET,"iso-8859-1", "utf8");
        ($top,$xml) = $RET =~ m{^(.*)(\<\?xml.*)$}gs;
        # log this to the repository
        $basecmd = $cmd =~ m{^.*/(\w+) .*$};
        $basecmd ||= $cmd;

        _debug "Changeman Command " . _loc('%2: USS command "%1"', $basecmd, $oper) . "\ncmd: $cmd\n$top: $top\nxml: $xml";
        $sem->release(logger=>$logger);
### Critical region

        redo CMD if $top=~m{IKJ56225I};
    }
    if( $oper ne 'get_pkg' || length $top ) {
        try {
            BaselinerX::ChangemanUtils->log( _loc('%2: USS command "%1"', $basecmd, $oper), cmd=>$cmd, top=>$top, xml=>$xml);
        } catch {
            _debug "Can't store command " . _loc('%2: USS command "%1"', $basecmd, $oper) . "\ncmd: $cmd\n$top: $top\nxml: $xml";
        };
    }
    return $xml;
}

1;
