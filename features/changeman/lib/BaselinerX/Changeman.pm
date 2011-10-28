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

has 'host' => ( is=>'rw', isa=>'Str', required=>1 );
has 'port' => ( is=>'rw', isa=>'Str', required=>1, default=>623 );
has 'user' => ( is=>'rw', isa=>'Str', required=>1 );
has 'password' => ( is=>'rw', isa=>'Str|CodeRef' );

=head2 list_pkgs ( filter=>Str, job_type=> p|m, to_env=> 'PROD|PREP...', projects=>Array )

List packages using a USS REXX routine.

=cut
sub list_pkgs {
	my ($self, %args) = @_;
    my $host = $self->host; #'prue';
    my $user = $self->user; #'vpchm';
    my $timeout;
    my $prompt;
    my $port = $self->port; #24;

    _log _dump %args;
    
    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $pw = ref($self->password) eq 'CODE'
        ? $self->password->()
        : $self->password;

    my $uss = MVS::USS->new( host=>$host, port=>$port||623, user=>$user, password=>$pw, Timeout => $timeout || 60, Prompt  => $prompt || '/\$/' );
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
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $uss->cmd( $cmd );
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
    my $host = $self->host; #'prue';
    my $user = $self->user; #'vpchm';
    my $timeout;
    my $prompt;
    my $port = $self->port; #24;

    my $job = Baseliner->model('Baseliner::BaliJob')->search({ name=>$args{job} })->first;
    
    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $pw = ref($self->password) eq 'CODE'
        ? $self->password->()
        : $self->password;

    my $uss = MVS::USS->new( host=>$host, port=>$port||623, user=>$user, password=>$pw, Timeout => $timeout || 60, Prompt  => $prompt || '/\$/' );
    #$sem->release;
    
    # N.TEST-00000250,p|m,PREP|FORM|PROD,S|N, YYYYMMDDHHMISS, PACKAGE_1, PACKAGE_2,... PACKAGE_N
    my $pase = $job->name;
    my $date = $job->starttime->strftime("%Y%m%d%H%M%S");
    my $job_type = $job->type eq 'promote'?'p':'d';
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
    
    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $uss->cmd( $cmd );
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

    _log "addToJob: " . _dump $xml;
    
    $xml
}

=head2 cancelJob ( pase=>Str, job_type=> p|m, to_env=> 'PROD|PREP|FORM', urgente=>'S|N', packages=>Array )

Removes association betwen job and packages

=cut
sub cancelJob {
    my ($self, %args) = @_;
    my $host = $self->host; #'prue';
    my $user = $self->user; #'vpchm';
    my $timeout;
    my $prompt;
    my $port = $self->port; #24;

    my $job = Baseliner->model('Baseliner::BaliJob')->search({ name=>$args{job} })->first;
    
    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $pw = ref($self->password) eq 'CODE'
        ? $self->password->()
        : $self->password;

    my $uss = MVS::USS->new( host=>$host, port=>$port||623, user=>$user, password=>$pw, Timeout => $timeout || 60, Prompt  => $prompt || '/\$/' );
    #$sem->release;
    
    # N.TEST-00000250, PACKAGE_1, PACKAGE_2,... PACKAGE_N
    my $pase = $job->name;
    my $job_type = $job->type eq 'promote'?'p':'d';
    my $to = $job->bl eq 'ANTE'?'PREP':$job->bl;

    my $cmd = '/u/aps/chm/ll05' . ' ' . join(',', $pase, $args{items} ) ;

    _log "cancelJob: $cmd";

    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $uss->cmd( $cmd );
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

    _log "cancelJob: " . _dump $xml;

    $xml
}


=head2 cache

Recover Changeman cache

=cut
sub cache {
    my ($self) = @_;
    my $host = $self->host; #'prue';
    my $user = $self->user; #'vpchm';
    my $timeout;
    my $prompt;
    my $port = $self->port; #24;

    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $pw = ref($self->password) eq 'CODE'
        ? $self->password->()
        : $self->password;

    my $uss = MVS::USS->new( host=>$host, port=>$port||623, user=>$user, password=>$pw, Timeout => $timeout || 60, Prompt  => $prompt || '/\$/' );
    #$sem->release;
    
    my $cmd = '/u/aps/chm/llcache' ;

    _log "cache: $cmd";

    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $uss->cmd( $cmd );
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
    _log "cache: " . _dump $xml_str;
    require XML::Simple;
    # my $xml = XML::Simple::XMLin( $xml_str );
    my $xml = XML::Simple::XMLin( $xml_str, ForceArray => [qw(Package MarchaAtras Promote content)] );

    # _log "cache: " . _dump $xml;

    $xml
}

=head2 listApplications

Recover Changeman applications

=cut
sub listApplications {
    my ($self) = @_;
    my $host = $self->host; #'prue';
    my $user = $self->user; #'vpchm';
    my $timeout;
    my $prompt;
    my $port = $self->port; #24;

    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
    my $pw = ref($self->password) eq 'CODE'
        ? $self->password->()
        : $self->password;

    my $uss = MVS::USS->new( host=>$host, port=>$port||623, user=>$user, password=>$pw, Timeout => $timeout || 60, Prompt  => $prompt || '/\$/' );
    #$sem->release;
    
    my $cmd = '/u/aps/chm/llaplics' ;

    _log "aplications: $cmd";

    my $flag=0;
    my $out = join '', grep { 
		$flag = 1 if !$flag && /^\</; 
		$flag;
		} map { s{\n}{}g; $_ } $uss->cmd( $cmd );
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
    _log "applications: " . _dump $xml_str;
    require XML::Simple;
    my $xml = XML::Simple::XMLin( $xml_str );

    _log "applications: " . _dump $xml;

    $xml
}
1;
