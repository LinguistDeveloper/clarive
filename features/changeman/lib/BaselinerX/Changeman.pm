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
use Encode;

has 'host' => ( is=>'rw', isa=>'Str', required=>1 );
has 'port' => ( is=>'rw', isa=>'Str', required=>1, default=>58765 );
has 'key' => ( is=>'rw', isa=>'Str|CodeRef', default=>'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');


=head2 list_pkgs ( filter=>Str, job_type=> p|m, to_env=> 'PROD|PREP...', projects=>Array )

Get a package using a USS REXX routine.

=cut
sub get_pkg {
	my ($self, %args) = @_;
    my $host = $self->host; #'prue';
    my $port = $self->port; #58765;
    my $key = $self->key; #'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=';
    my $timeout;
    my $prompt;

    _log _dump %args;
    
    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$host, port=>$port|58765, key=>$key|'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');
    #$sem->release;

    my $filter = $args{filter} || '*';
    # my $job_type = $args{job_type} || 'p';
    # my $to = $args{to_env} eq 'ANTE'?'PREP':$args{to_env};

    my $cmd = '/u/aps/chm/llpackage' . ' ' . $filter;

    _log 'get_pkg' . $cmd;
    
    my $flag=0;
    my ($RC,$RET)=$bx->execute( $cmd );

    $RET =~ s/IKJ566(.*?)\n//s;
    Encode::from_to($RET,"iso-8859-1", "utf8");

    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $RET;
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
    my $host = $self->host; #'prue';
    my $port = $self->port; #58765;
    my $key = $self->key; #'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=';
    my $timeout;
    my $prompt;

    # _log _dump %args;
    
    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$host, port=>$port|58765, key=>$key|'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');
    #$sem->release;

    # *,p|m,PREP|FORM|PROD,CAM1 CAM2
    # *,p,PROD,XXX SCT
    my $filter = $args{filter} || '*';
    my $job_type = $args{job_type} || 'p';
    # my $to = $args{to_env} || 'PROD';
    my $to = $args{to_env} eq 'ANTE'?'PREP':$args{to_env};
    my $apps = join ' ', _array( $args{projects} );
    my $cmd = '/u/aps/chm/ll01' . ' ' . join(',', $filter, $job_type, $to, $apps ) ;

    _log  "list_pkgs: " . $cmd;
    
    my $flag=0;
    my ($RC,$RET)=$bx->execute( $cmd );

    $RET =~ s/IKJ566(.*?)\n//s;
    Encode::from_to($RET,"iso-8859-1", "utf8");

    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $RET;
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
    my $xml_str = $self->list_pkgs( %args );
    # _log $xml_str;
    require XML::Simple;
    my $xml = XML::Simple::XMLin( $xml_str, ForceArray => [qw(Package)] );

    # _log "list_pkgs: " . _dump $xml;

    $xml
}

=head2 $chm->xml_addToJob(job=>$job_name, items=>[ARRAY], options=>[ARRAY]) ;

Associates packages to SCM job

=cut
sub addToJob {
    my ($self, %args) = @_;
    my $host = $self->host; #'prue';
    my $port = $self->port; #58765;
    my $key = $self->key; #'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=';
    my $timeout;
    my $prompt;

    my $job = Baseliner->model('Baseliner::BaliJob')->search({ name=>$args{job} })->first;
    
    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$host, port=>$port|58765, key=>$key|'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');
    #$sem->release;
    
    # N.TEST-00000250,p|m,PREP|FORM|PROD,S|N, YYYYMMDDHHMISS, PACKAGE_1, PACKAGE_2,... PACKAGE_N
    my $pase = $job->name;
    my $date = $job->starttime->strftime("%Y%m%d%H%M%S");
    my $job_type = $job->type eq 'promote'?'p':'m';
    my $to = $job->bl eq 'ANTE'?'PREP':$job->bl;
    my $refresh='N';
    my $items=undef;
    
    if ($to eq 'PROD') {
        foreach (_array $args{options}) {
            if ($_ =~ 'chm_rf_ll') {
                $refresh='S';
                last;
                }
            }
        }
    foreach ( _array $args{items} ) {
        $items.=$_->{item}."," if $_->{provider} eq 'namespace.changeman.package';
        }
        chop $items;

    my $cmd = '/u/aps/chm/ll02' . ' ' . join(',', $pase, $job_type, $to, $refresh, $date, $items ) ;
    
    _log "AddToJob: $cmd";
    
    my ($RC,$RET)=$bx->execute( $cmd );
   
    $RET =~ s/IKJ566(.*?)\n//s;
    Encode::from_to($RET,"iso-8859-1", "utf8");
    
    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $RET;
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
    my $host = $self->host; #'prue';
    my $port = $self->port; #58765;
    my $key = $self->key; #'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=';
    my $timeout;
    my $prompt;

    my $job = Baseliner->model('Baseliner::BaliJob')->search({ name=>$args{job} })->first;
    
    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$host, port=>$port|58765, key=>$key|'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');
    #$sem->release;
    
    # N.TEST-00000250, PACKAGE_1, PACKAGE_2,... PACKAGE_N
    my $pase = $job->name;
    my $job_type = $job->type eq 'promote'?'p':'m';
    my $to = $job->bl eq 'ANTE'?'PREP':$job->bl;

    my $cmd = '/u/aps/chm/ll05' . ' ' . join(',', $job_type, $to, $pase, $args{items} ) ;

    _log "cancelJob: $cmd";
    
    my ($RC,$RET)=$bx->execute( $cmd );
    $RET =~ s/IKJ566(.*?)\n//s;
    Encode::from_to($RET,"iso-8859-1", "utf8");
    
    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $RET;
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
    my $xml = XML::Simple::XMLin( $xml_str );

    # _log "cancelJob: " . _dump $xml;

    $xml
}

=head2 $chm->runPackageInJob(job=>$job_name, package=>$package, job_type=>$job_type, bl=>$job_bl) ;

Execute a Changeman Package

=cut
sub runPackageInJob {
    my ($self, %args) = @_;
    my $host = $self->host; #'prue';
    my $port = $self->port; #58765;
    my $key = $self->key; #'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=';

    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$host, port=>$port|58765, key=>$key|'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');
    #$sem->release;
    
    # p|m, PREP|FORM|PROD, PACKAGE_1, N.TEST-00000250 
    my $job_type = $args{job_type};
    my $job = $args{job};
    my $to = $args{bl};
    my $package = $args{package};
    
    my $cmd = '/u/aps/chm/ll03' . ' ' . join(',', $job_type, $to, $package, $job ) ;
    
    _log "runPackageInJob: $cmd";
    
    my ($RC,$RET)=$bx->execute( $cmd );
   
    $RET =~ s/IKJ566(.*?)\n//s;
    Encode::from_to($RET,"iso-8859-1", "utf8");
    
    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $RET;
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
    my $xml = XML::Simple::XMLin( $xml_str );

    # _log "runPackageInJob: " . _dump $xml;
    
    $xml
}

=head2 $chm->refreshLLA() ;

Refresh LLA

=cut
sub refreshLLA {
    my ($self, %args) = @_;
    my $host = $self->host; #'prue';
    my $port = $self->port; #58765;
    my $key = $self->key; #'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=';

    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$host, port=>$port|58765, key=>$key|'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');
    #$sem->release;
    
    my $cmd = '/u/aps/chm/llreflla' ;
    
    _log "refreshLLA: $cmd";
    
    my ($RC,$RET)=$bx->execute( $cmd );
   
    $RET =~ s/IKJ566(.*?)\n//s;
    Encode::from_to($RET,"iso-8859-1", "utf8");
    
    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $RET;
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
    my $xml = XML::Simple::XMLin( $xml_str );

    # _log "refreshLLA: " . _dump $xml;
    
    $xml
}


=head2 cache

Recover Changeman cache

=cut
sub cache {
    my ($self) = @_;
    my $host = $self->host; #'prue';
    my $port = $self->port; #58765;
    my $key = $self->key; #'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=';
    my $timeout;
    my $prompt;

    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$host, port=>$port|58765, key=>$key|'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');
    #$sem->release;
    
    my $cmd = '/u/aps/chm/llcache' ;
    my ($RC,$RET)=$bx->execute( $cmd );
    $RET =~ s/IKJ566(.*?)\n//s;
    Encode::from_to($RET,"iso-8859-1", "utf8");
    
    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $RET;
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
    my $xml = XML::Simple::XMLin( $xml_str, ForceArray => [qw(Package MarchaAtras Promote content)] );

    # # _log "cache: " . _dump $xml;

    $xml
}

=head2 listApplications

Recover Changeman applications

=cut
sub listApplications {
    my ($self) = @_;
    my $host = $self->host; #'prue';
    my $port = $self->port; #58765;
    my $key = $self->key; #'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=';
    my $timeout;
    my $prompt;

    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$host, port=>$port|58765, key=>$key|'Si5JVWprYWRsYWooKCUzMi4rODdmai4uMTklZCQpM2RmbrfnZWG3anNhMTE6OTgsMUBqaHUoaGhIdDJqRXE=');
    #$sem->release;
    
    my $cmd = '/u/aps/chm/llaplics' ;

    # _log "aplications: $cmd";
    my ($RC,$RET)=$bx->execute( $cmd );
    $RET =~ s/IKJ566(.*?)\n//s;
    Encode::from_to($RET,"iso-8859-1", "utf8");
    
    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $RET;
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
    my $xml = XML::Simple::XMLin( $xml_str );

    # _log "applications: " . _dump $xml;

    $xml
}
1;
