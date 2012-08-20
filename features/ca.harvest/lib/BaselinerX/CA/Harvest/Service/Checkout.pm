package BaselinerX::CA::Harvest::Service::Checkout;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Job::Elements;
use BaselinerX::CA::Harvest::CLI;
use BaselinerX::Job::Service::Runner;
use File::Spec;

with 'Baseliner::Role::Service';

register 'service.harvest.checkout' => {
    name => 'Job Service for Harvest Packages',
    config=> 'config.ca.harvest.cli',
    handler => \&run 
};

register 'config.harvest.checkout' => {
    name => 'Harvest Checkout Configuration',
    metadata => [
        { id=>'full_checkout', label=>'Paths that need a full checkout Regex' },    
        { id=>'not_full_checkout', label=>'Paths that does not need a full checkout Regex' },
        { id=>'branch_checkout', label=>'Checkout from branch', default=>0 },
    ]
};

has 'cli' => (is=>'rw', isa=>'Object');
has 'data' => (is=>'rw', isa=>'HashRef');
has 'job' => (is=>'rw', isa=>'Object');
has 'log' => (is=>'rw', isa=>'Object');
has 'config' => (is=>'rw', isa=>'Any');
has 'viewpaths' => (is=>'rw', isa=>'HashRef');
has 'allviewpaths' => (is=>'rw', isa=>'HashRef');

sub run {
    my ($self,$c,$config) =@_;

    my $job = $c->stash->{job};
    my $log = $job->logger;
    $self->job( $job );
    $self->log( $log );
    $self->config( $config );

    my @contents = _array $job->job_stash->{contents};
    my ( @elements, %co_packages );

    my $myEnv;
    $myEnv .= $_ . '=' . $ENV{$_} . "\n" for  keys %ENV;
    $log->debug( 'Iniciando Servicio de Paquetes de Harvest path=' . $job->{job_stash}->{path} );
    $log->debug( 'Variables de entorno',$myEnv);

    my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$config->{broker}, login=>$config->{login} });

    my %vp;
    my $package_cnt;
    my %nature;
    my @version_report;
    my %vptree;

    foreach my $job_item ( @contents ) {
        my $item = $job_item->{item};
        my ( $domain, $package ) = ns_split( $item );
        next unless $domain eq 'harvest.package'; 
        my $data = $job_item->{data} ;
        
        my $ns_package = Baseliner->model('Namespaces')->get( $item ); 
        next unless ref $ns_package;
        next unless $ns_package->isa('BaselinerX::CA::Harvest::Namespace::Package');
        $package_cnt++;
        $log->debug( "Item data for $item", data=>_dump($job_item->{data}) );

        # get viewpaths for checkout
        my @paths = $ns_package->viewpaths(2);
        my @all_paths = $ns_package->viewpaths(3);

        foreach my $app (_unique @all_paths){
           next unless $app =~ m/\/.*\/.*\/.+/g;
          for my $path ( @paths ) {
            warn "$path = $app";
            if ($app =~ m/$path/) {
            push @{$vptree{$path}},$app;
                } 
            } 
         }
        
        # @vp{ @paths } = (); -- Si mezclamos paquetes de varias aplicaciones mezcla los paths.
        $vp{ $ns_package->environmentname } = \@paths;
        $log->debug( "Paths for package", data=>_dump(\@paths) );

        my $r = Baseliner->model('Harvest::Harpackage')->search(
            { packageobjid => $data->{packageobjid} },
            {
                join     => [ 'state', 'modifier', 'envobjid' ],
                prefetch => [ 'state', 'modifier', 'envobjid' ]
            }
        )->first;
        my $project = $r->envobjid->get_column('environmentname');
        my $state   = $r->state->get_column('statename');
        my $vp      = '/';
        $package or _throw 'Missing package name';
        my $mask = '*';

        # element list
        my $sv = $cli->select_versions(
            project => $project,
            state   => $state,
            vp      => $vp,
            package => $package,
            mask    => $mask
        );

        # report versions
        push @version_report, { package=>$package, data=>$sv->{msg} } ;
        #$log->debug( "Versiones en el paquete '$package' (struct)",
        #    data => _dump( $sv->{versions} ) );
        push @elements, @{ $sv->{versions} };

        # group packages 
        $co_packages{$project}{$state}{$package} = $data;
        for my $nat ( $ns_package->nature ) {
            push @{ $nature{$nat} }, $package;
        }
    }
    if( $package_cnt ) {
        unless( scalar @elements ) {
            $log->warn( 'No hay elementos para checkout de Harvest' );
            return;
        }
    } else {
        $log->debug( _loc('No harvest packages to checkout') );
        return;
    }
    
    $log->info( "Versiones en los paquetes de Harvest", data=>$self->_version_report( @version_report ) );
    # put elements into stash
    $log->info( "Listado de elementos de Harvest", data=>$self->_elements_list(\@elements) );
    my $e = $job->job_stash->{elements} || BaselinerX::Job::Elements->new;
    $e->push_elements( @elements );
    $job->job_stash->{elements} = $e;
    my @natures = $e->list('nature');
    $log->info( _loc('Naturalezas incluidas en el pase'), data=>_dump(\@natures) );

    # checkouts
    unless( %co_packages ) {
        $log->warn( 'No hay paquetes para checkout' );
    } else {
        $self->data( \%co_packages );
        $self->viewpaths( \%vp );
        $self->allviewpaths( \%vptree );
        $self->cli( $cli );
        $self->checkout;
    }
}

sub checkout {
    my ($self,%p)=@_;
    my $cli = $self->cli;
    my $job = $self->job;
    my $path = $job->job_stash->{path} or _throw 'Invalid job path in stash';
    my $log = $self->log;
    my $config = $self->config;
    my %co_packages = %{ $self->data };
    my %vp = %{ $self->viewpaths };
    my %allvp = %{ $self->allviewpaths };
    
    # process co on a project and state basis
    foreach my $project ( keys %co_packages ) {
        my $inf = Baseliner->model('ConfigStore')->get('config.harvest.checkout', ns=>"harvest.project/$project");
        foreach my $state ( keys %{ $co_packages{$project} || {} } ) {
            # CO state
            my $packages = $co_packages{$project}{$state}; 

            # CO full viewpaths trunk
            if ( my $full_checkout = $inf->{full_checkout} ) {
                my $not_full_checkout = $inf->{not_full_checkout};
                my $re = qr{$full_checkout};
                my $re_not = qr{$not_full_checkout};
                # foreach my $vp ( keys %vp ){ -- -- Si mezclamos paquetes de varias aplicaciones mezcla los paths.
                foreach my $vpnat ( _array $vp{$project} ) {
                    foreach my $vp ( _array $allvp{$vpnat} ) {
                        $log->debug(
                            "Full state CHECKOUT harvest.project/$project : $vp = $re && $vp != $re_not ==>"
                            . ( $vp =~ $re && $vp !~ $re_not )
                        );
                        
                        unless ( $vp =~ $re && $vp !~ $re_not ) {
                            $log->debug( _loc('Skipping Viewpath "%1" - no full checkout needed.', $vp) );
                            next;
                        }
   
                        $vp = $1 if $vp =~ m/(.*)\/.*$/;
                        
                        my $cp = File::Spec->catdir ( $path, $vp);
                        #$cp = File::Spec->catpath( $cp, $vp );
                        $log->info( "Inicio Checkout del Viewpath $project:$state:$vp a '$cp'. Espere...");
                        my $co = $cli->run(
                                cmd      => 'hco', 
                                -en      => $project,
                                -st      => $state,
                                -vp      => $vp,
                                -cp      => $cp,
                                -ced     => undef,
                                -br      => undef,
                                );
                        _throw _loc 'Error during state checkout: %1', $co->{msg} if $co->{rc};
                        $log->debug( "Resultado del Checkout del Viewpath $project:$state:$vp", data=>$co->{msg}, data_name=>'CheckoutState' );
                        last;    ## para q haga CO completo 1 sola vez.
                    }
                }
            }
    
            # CO packages trunk
            #if( $state =~ /^Desarrollo$/i ) {   #TODO state where package checkout is needed....
                $packages = $co_packages{$project}{$state}; 
                $log->info( "Inicio Checkout de Tronco de Paquetes $project:$state. Espere...", _dump $packages );
                foreach my $vp ( '/' ) {
                    my $co = $cli->run(
                            cmd       => 'hco', 
                            -en       => $project,
                            -st       => $state,
                            -to       => undef,
                            -vp       => $vp,
                            -cp       => $path, # FileSpec->cat( $job->job_stash->{path}, $vp )
                            -pf => [ keys %{$packages} ],
                            -po => undef,
                            -ced     => undef,
                            -br      => undef,
                            );
                    _throw _loc 'Error during trunk checkout: %1', $co->{msg} if $co->{rc};
                    $log->debug( "Resultado del Checkout de Tronco de Paquetes $project:$state", data=>$co->{msg}, data_name=>'CheckoutTronco' );
                }
            #}

            if( $inf->{branch_checkout} ) {
                # CO packages branch  TODO multiple packages with branches will co randomly ?
                $packages = $co_packages{$project}{$state}; 
                $log->info( "Inicio Checkout de Rama de Paquetes $project:$state. Espere...", _dump $packages );
                my $co = $cli->run(
                        cmd       => 'hsync', 
                        -en       => $project,
                        -st       => $state,
                        -bo       => undef,
                        -vp       => '/',
                        -cp       => $job->job_stash->{path},
                        -pf       => [ keys %{$packages} ],
                        -po       => undef,
                        -ced      => undef,
                        -br       => undef,
                        );
                _throw _loc 'Error during branch checkout: %1', $co->{msg} if $co->{rc};
                $log->debug( "Resultado del Checkout de Rama de Paquetes $project:$state", data=>$co->{msg}, data_name=>'CheckoutRama' );
            }
            # change permissions 
            my @files = File::Find::Rule->file()->name('*','.*')->in( $path );
            my $file_cnt = chmod( oct($config->{permissions}) , @files ); 

            # my $file_cnt=0;
            # foreach (@files) {
               # chmod( oct($config->{permissions}) , "$_" );
               # qx (sh -c "chmod oct($config->{permissions})  \"$_\"");
               # $file_cnt++;
               # }
 
            $log->debug("Permisos cambiados a $config->{permissions} en $file_cnt fichero(s) en $path", data=>join("\n",@files) );

        }
    }
}

sub _elements_list {
    my ($self,$list)=@_;
    my @ret;
    push @ret,
    qq{PACKAGE\tPATH\tITEM\tVERSION\tTAG\tMODIFIER};
    for my $i ( _array $list ) {
        my $rec;
        $rec .= $i->package . "\t";
        $rec .= $i->path    . "\t";
        $rec .= $i->name    . "\t";
        $rec .= $i->version . "\t";
        $rec .= $i->tag     . "\t";
        $rec .= $i->modifier;
        push @ret, $rec; 
    }
    return join "\n", @ret;
}

sub _version_report {
    my $self = shift;
    my $ret = '';
    for( @_ ) {
        my $pkg = $_->{package};
        my $data = $_->{data};
        $ret .= qq{
-------------------------| PACKAGE $pkg

$data

};
    }
    return $ret;
}

1;
