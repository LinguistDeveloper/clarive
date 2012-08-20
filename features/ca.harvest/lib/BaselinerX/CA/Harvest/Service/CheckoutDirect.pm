package BaselinerX::CA::Harvest::Service::CheckoutDirect;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Job::Elements;
use BaselinerX::CA::Harvest::CLI;
use BaselinerX::CA::Harvest::Sync;
use BaselinerX::Job::Service::Runner;
use File::Spec;
use Try::Tiny;
use Path::Class;

with 'Baseliner::Role::Service';

register 'service.harvest.checkout.direct' => {
    name => 'Job Service for Harvest Direct Checkout',
    config=> 'config.ca.harvest.cli',
    handler => \&run 
};

register 'config.harvest.checkout.direct' => {
    name => 'Harvest Checkout Direct Configuration',
    metadata => [
        { id=>'full_checkout', label=>'Paths that need a full checkout Regex' },    
        { id=>'not_full_checkout', label=>'Paths that do not need a full checkout Regex' },
        { id=>'states', label=>'States form which to checkout a full state', type=>'hash' },
        { id=>'branch_checkout', label=>'Checkout from branch', default=>0 },
        { id=>'sed_include_path', label=>'Paths included for checkout substitutions' },
        { id=>'sed_exclude_path', label=>'Paths excluded for checkout substitutions' },
        { id=>'sed_re', label=>'Checkout substitution regex' },
    ]
};

has 'cli'          => ( is => 'rw', isa => 'Object' );
has 'data'         => ( is => 'rw', isa => 'HashRef' );
has 'job'          => ( is => 'rw', isa => 'Object' );
has 'log'          => ( is => 'rw', isa => 'Object' );
has 'config'       => ( is => 'rw', isa => 'Any' );
has 'viewpaths'    => ( is => 'rw', isa => 'HashRef' );
has 'allviewpaths' => ( is => 'rw', isa => 'HashRef' );

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
    $log->debug( 'Iniciando Servicio de Checkout de Harvest path=' . $job->{job_stash}->{path} );
    $log->debug( 'Variables de entorno',$myEnv);
    
    my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$config->{broker}, login=>$config->{login} });

    my %vp;
    my $package_cnt;
    my %nature;
    my %vptree;

    my @package_ids;
    my @version_report;

    foreach my $job_item ( @contents ) {
        my $item = $job_item->{item};
        my ( $domain, $package ) = ns_split( $item );
        next unless $domain eq 'harvest.package'; 
        my $data = $job_item->{data} ;
        $log->debug(_loc("Processing package '%1'", $package) );
        
        my $ns_package = Baseliner->model('Namespaces')->get( $item ); 
        next unless ref $ns_package;
        next unless $ns_package->isa('BaselinerX::CA::Harvest::Namespace::Package');
        $package_cnt++;
        $log->debug( "Item data for $item", data=>_dump($job_item->{data}) );

        # get viewpaths for checkout
        my @paths = $ns_package->viewpaths(2);
        my @all_paths = $ns_package->viewpaths(3);

        foreach my $app ( _unique @all_paths ) {
            next unless $app =~ m/\/.*\/.*\/.+/g;
            for my $path (@paths) {
                warn "$path = $app";
                if ( $app =~ m/$path/ ) {
                    push @{ $vptree{$path} }, $app;
                }
            }
        }
        
        # @vp{ @paths } = (); -- Si mezclamos paquetes de varias aplicaciones mezcla los paths.
        $vp{ $ns_package->environmentname } = \@paths;
        # $log->debug( "Paths for package", data=>_dump(\@paths) );  # GDF 71223

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
        push @package_ids, $data->{packageobjid};

        # group packages 
        $co_packages{$project}{$state}{$package} = $data;
        for my $nat ( $ns_package->nature ) {
            push @{ $nature{$nat} }, $package;
        }
    }

    unless( $package_cnt ) {
        $log->debug( _loc('No Harvest packages to checkout') );
        return;
    }

    # select package elements
    my $job_type = $job->job_type;
    $log->debug( "Selecting package elements for package-ids (job_type: $job_type): " . join',',@package_ids );
    my $hs = BaselinerX::CA::Harvest::Sync->new( dbh=>Baseliner->model('Harvest')->storage->dbh );
    my @e = $hs->elements( mode=> $job_type || 'promote', packageobjid=>\@package_ids );
    @elements = map { BaselinerX::CA::Harvest::Version->new( $_ ) } @e;
    
    unless( scalar @elements ) {
        $log->warn( _loc('No Harvest items to checkout') );
        return;
    }
 
    $log->info( "Versiones en los paquetes de Harvest", data=>$self->_version_report( elements=>\@e ) );

    # put elements into stash
    $log->info( "Listado de elementos de Harvest", data=>$self->_elements_list(\@elements) );
    my $e = $job->job_stash->{elements} || BaselinerX::Job::Elements->new;
    $e->push_elements( @elements );
    $job->job_stash->{elements} = $e;
    $log->debug( "Harvest elements", data=>_dump( $e ) );
    my @natures = $e->list('nature');
    $log->info( _loc('Naturalezas incluidas en el pase'), data=>_dump(\@natures) );

    # checkout state
    unless( %co_packages ) {
        $log->warn( _loc('No Harvest packages to checkout') );
    } else {
        $self->data( \%co_packages );
        $self->viewpaths( \%vp );
        $self->allviewpaths( \%vptree );
        $self->cli( $cli );
        $self->checkout;
    }

    # deletes - need to do this first, as there may be old deletes
    my @deletes;
    for my $elem ( grep { $_->{action} eq 'delete' } @elements ) {
        my $path = $job->job_stash->{path} or _throw 'Invalid job path in stash';
        my $epath = $elem->fullpath;
        my $file = file $path, $epath;
        push @deletes, "$file";
        unlink "$file"; 
    }
    $log->debug(_loc("Deleted files" ), data=>join('<li>',@deletes) )
        if @deletes;

    # checkout package items (action=write)
    my $inf = Baseliner->model('ConfigStore')->get('config.harvest.checkout.direct', ns=>"/");
    my ($sed_include_path, $sed_exclude_path, $sed_re)
        = ( $inf->{sed_include_path}, $inf->{sed_exclude_path}, $inf->{sed_re} );
    my @sed_files;
    scalar(@elements) > 0 
        ? $log->info(_loc("Harvest Package checkout of %1 items in %2 packages", scalar(@elements), scalar(@package_ids) ) )
        : $log->warn(_loc("No Harvest Package elements detected. Checkout skipped.") );
    for my $elem ( grep { $_->{action} eq 'write' } @elements ) {
        my $path = $job->job_stash->{path} or _throw 'Invalid job path in stash';

        if( $sed_re ) {  # replace string?
            if ( $sed_include_path && $elem->fullpath =~ m{$sed_include_path} && $elem->fullpath !~ m{$sed_exclude_path}) {
                my $ret = $elem->checkout( path=> $path, sed=>$sed_re );
                push @sed_files, $elem->fullpath if $ret->{sed_found};
            } else {
                # if $sed_exclude_path && $elem->fullpath =~ m{$sed_exclude_path} { Si esta en excluded o no esta en included hay que hacer checkout normal ¿no?
                $elem->checkout( path=> $path );
            }
        } else {
            $elem->checkout( path=> $path );
        }
    }
    $log->info(_loc("String Replace %1 in files detected", $sed_re), data=>_dump(\@sed_files) )
        if @sed_files;
}

sub checkout {
    my ($self,%p)=@_;
    my $cli = $self->cli;
    my $job = $self->job;
    my $bl  = $job->bl;
    my $path = $job->job_stash->{path} or _throw 'Invalid job path in stash';
    my $log = $self->log;
    my $config = $self->config;
    my %co_packages = %{ $self->data };
    my %vp = %{ $self->viewpaths };
    my %allvp = %{ $self->allviewpaths };
    
    # process co on a project and state basis
    foreach my $project ( keys %co_packages ) {
        my $inf = Baseliner->model('ConfigStore')->get('config.harvest.checkout.direct', ns=>"harvest.project/$project", bl=>$bl);
        # workaround - config store ns default no funciona
        $inf = Baseliner->model('ConfigStore')->get('config.harvest.checkout.direct', ns=>"/", bl=>$bl)
            unless keys( %{ $inf->{states} || {} } ) > 0;
        my $job_co_states = $inf->{states};
        my $co_state;
        next unless try {
            my $job_type = $self->job->job_type;
            $co_state = $job_co_states->{ $job_type };
            $co_state = $job_co_states->{ 'promote' } if !defined $co_state && $job_type eq 'static'; 
            defined $co_state
                or die _loc("Checkout job state not found for baseline %1, job type %2 (config.harvest.checkout.direct.state)", $bl, $job_type) . "\n"; 
            return 1;
        } catch {
            my $err = shift;
            $log->error( _loc( "Checkout skipped. Error during direct checkout configuration: %1", $err ) );
            return 0;
        };

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
                    
                    my $cp = File::Spec->catdir( $path, $vp);
                    #$cp = File::Spec->catpath( $cp, $vp );
                    $log->info( "Inicio Checkout del Viewpath $project:$co_state:$vp a '$cp'. Espere...");
                    my $co = $cli->run(
                            cmd      => 'hco', 
                            -en      => $project,
                            -st      => $co_state,
                            -vp      => $vp,
                            -cp      => $cp,
                            -ced     => undef,
                            -br      => undef,
                            '-s'     => '*',
                            );
                    _throw _loc 'Error during state checkout: %1', $co->{msg} if $co->{rc};
                    $log->debug( "Resultado del Checkout del Viewpath $project:$co_state:$vp", data=>$co->{msg}, data_name=>'CheckoutState' );
                    last;    ## para q haga CO completo 1 sola vez.
                }
            }
     
            # change permissions 
            my @files = File::Find::Rule->file()->name('*','.*')->in( $path );
            my $file_cnt = chmod( oct($config->{permissions}) , @files ); 
            $log->debug("Permisos cambiados a $config->{permissions} en $file_cnt fichero(s) en $path", data=>join("\n",@files) );
        } else {
            $log->debug( _loc("State checkout ignored. Configuration value 'full_checkout' is unset.") );
        }

        # change permissions 
        my @files = File::Find::Rule->file()->name('*','.*')->in( $path );
        my $file_cnt = chmod( oct($config->{permissions}) , @files ); 

        # my $file_cnt=0;
        # foreach (@files) {
           # chmod( oct($config->{permissions}) , "$_" );
           # $file_cnt++;
           # }

        $log->debug("Permisos cambiados a $config->{permissions} en $file_cnt fichero(s) en $path", data=>join("\n",@files) );
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
    my ($self, %p ) = @_;
    my $ret;
    for( _array $p{elements} ) {
        my $pkg = $_->{package};
        $ret .= qq{
$_->{packagename}:$_->{username}: $_->{fullpath};v$_->{mappedversion} ($_->{modifytime} - $_->{action})};
    }
    return $ret;
}

1;

