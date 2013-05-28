package BaselinerX::Type::Controller::Service;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' };
use utf8;

sub begin : Private {
    my ($self,$c)=@_;
    my $api_key = $ENV{BASELINER_API_KEY};
    if( defined $api_key ) {
        if( $c->req->params->{api_key} eq $api_key ) {
            $c->stash->{auth_skip} = 1;
        }
    } else {
        $c->stash->{auth_skip} = 1;
    }
}

sub list_services : Path('/admin/type/service/list_services') {
    my ($self,$c)=@_;
    $c->res->body( "<pre>" . _dump( $c->registry->starts_with( 'service' ) ) );
}

sub rest : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    _log "=== Starting Service $p->{service}";
    _log _dump $p;

    my $quiet_mode = exists $p->{quiet_mode};

    # create a temporary logger
    local $Baseliner::_thrower = sub { 
        die @_,"\n";
    } if $quiet_mode;
    local $Baseliner::_logger = sub { 
        my ($cl,$li,$fi,@msg) = @_;
        print STDERR @msg, "\n";
    } if $quiet_mode;


    # run the service, capturing output
    my ($output ,$stderr, $stdout);
    #open(my $olderr, ">&STDERR") ;
    #open(my $oldout, ">&STDOUT") ;
    #close STDOUT;
    #close STDERR;
    #open(STDOUT, ">>", $tf) or die "Can't open STDOUT: $!";
    #open(STDERR, ">>", $tf) or die "Can't open STDERR: $!";
    my $verbose = exists $p->{v};
    
    #$output= capture_merged {
    use IO::CaptureOutput;
    IO::CaptureOutput::capture( sub {
    require Baseliner::Core::Logger::Quiet;
    my $logger = Baseliner::Core::Logger::Quiet->new;
        try {
            local $ENV{BASELINER_DEBUG} = $verbose; 
            local $Baseliner::DebugForceOff = $verbose; 
            Baseliner->model('Services')->launch(
                    $p->{service},
                    logger       => $logger,
                    quiet        => 1,
                    data         => $p
                );
            $c->stash->{json} = { msg=>$logger->msg, rc=>$logger->rc };
        } catch {
            my $err = shift;
            $c->stash->{json} = { msg=>$logger->msg . "\n$err", rc=>255 };
        };
    }, \$output, \$output );
    #};
    #$output = $stdout . $stderr;
    #open(STDOUT, ">&", $oldout);
    #open(STDERR, ">&", $olderr);

    utf8::downgrade( $output );
    $c->stash->{json}->{output} = $output;
    $c->forward('View::JSON');
}

sub launch : Regex('^service.') {
    my ($self,$c)=@_;
    my $service_name = $c->request->path;
    my $ns = $c->request->params->{ns} || '/';
    my $bl = $c->request->params->{bl} || '*';
    _log "Invoking service '$service_name'";
    my $service = $c->registry->get($service_name) || die _loc("Could not find service %1",  $service_name);
    my $config = $c->registry->get( $service->config ) if( $service->{config} );
    my $config_data;
    if( $config ) {
        $config_data = $config->factory( $c, ns=>$ns, bl=>$bl, data=>$c->request->params );
    }
    #warn "Configdata:" . Dumper $config_data;
    my $ret = $service->run( $c, $config_data );
    $c->res->body( "<h1>Resultado de la ejecución del servicio $service_name: $ret->{rc}</h1><p><pre>$ret->{msg}</pre>" );
}

sub tree : Local {
    my ($self,$c)=@_;
    my $list = $c->registry->starts_with( 'service' ) ;
    my $p = $c->req->params;
    my @tree;
    my $field = $p->{field} || 'name';
    foreach my $key ( $c->registry->starts_with( 'service' ) ) {
        my $service = Baseliner::Core::Registry->get( $key );
        _debug _dump $service;
        push @tree,
          {
            id   => $key,
            leaf => \1,
            text => ( $field eq 'key' ? $key : $service->{$field} ) || $key,
            attributes => { key => $key, name=>$service->{name}, id=>$service->{id} }
          };
    }
    $c->stash->{json} = { data => [ sort { $a->{text} cmp $b->{text} } @tree ], totalCount=>scalar @tree };
    $c->forward("View::JSON");
}

# sub tree : Local {
# 	my ($self,$c)=@_;
#     my $list = $c->registry->starts_with( 'service' ) ;
#     my $p = $c->req->params;
#     my @tree;
#     my $field = $p->{field} || 'name';
#     foreach my $key ( $c->registry->starts_with( 'service' ) ) {
#         my $service = Baseliner::Core::Registry->get( $key );
#         _debug _dump $service;
#         push @tree,
#           {
#             id   => $key,
#             leaf => \1,
#             text => ( $field eq 'key' ? $key : $service->{$field} ) || $key,
#             attributes => { key => $key, name=>$service->{name}, id=>$service->{id} }
#           };
#     }
#     $c->stash->{json} = { data => [ sort { $a->{text} cmp $b->{text} } @tree ], totalCount=>scalar @tree };
#     $c->forward("View::JSON");
# }

sub combo : Local {
    my ($self,$c)=@_;
    my $list = $c->registry->starts_with( 'service' ) ;
    my $p = $c->req->params;
    my $query = qr/$p->{query}/ if defined $p->{query};
    my @data;
    foreach my $key ( $c->registry->starts_with( 'service' ) ) {
        my $service = Baseliner::Core::Registry->get( $key );
        my $name = length $service->{name} ? "$key - $service->{name}" : $key;
        next if defined $query && $name !~ $query;
        push @data, { id=>$key, name=>$name };
    }
    $c->stash->{json} = { data => [ sort { $a->{id} cmp $b->{id} } @data ], totalCount=>scalar @data };
    $c->forward("View::JSON");
}

1;
