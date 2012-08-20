package BaselinerX::Type::Service;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Core::Registrable';

register_class 'service' => __PACKAGE__;
sub service_noun { 'service' };

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'name' => ( is=> 'rw', isa=> 'Str' );
has 'desc' => ( is=> 'rw', isa=> 'Str' );
has 'handler' => ( is=> 'rw', isa=> 'CodeRef' );
has 'config' => ( is=> 'rw', isa=> 'Str' );
has 'logger_class' => ( is=> 'rw', isa=> 'Str', default=>'Baseliner::Core::Logger::Base' );  # class
has 'logger' => ( is=> 'rw', isa=> 'Any' );

has 'frequency' => ( is=> 'rw', isa=> 'Int' );  # frequency value in seconds
has 'frequency_key' => ( is=> 'rw', isa=> 'Str' );  # frequency config key
has 'scheduled' => ( is=> 'rw', isa=> 'Bool' );  # true for a scheduled job

has 'log' => ( is=> 'rw', isa=> 'Object' );
has 'show_in_menu' => ( is=> 'rw', isa=> 'Bool' );

has 'quiet' => (is=>'rw', isa=>'Bool', default=>0 );
has 'type' => (is=>'rw', isa=>'Str', default=>'std');
has 'alias' => ( 
    is=> 'rw', isa=> 'Str',
    trigger=> sub {
        my ($self,$alias,$meta)=@_;
        my $alias_key = 'alias.'.$alias;
        register $alias_key => { link => $self->id };
        Baseliner::Plug->registry->initialize($alias_key);
    }
);

sub BUILD {
    my ($self, $params) = @_;
    ## handler should always point to some code
    unless( $self->handler ) {
        $self->handler( \&{ $self->module().'::'.$self->id } );
    }
    ## add service to admin menu
    if( $self->show_in_menu ) {
        register 'menu.admin.service.'.$self->id => { label=>$self->name || $self->key, url=>'/'.$self->key, title=>$self->name || $self->key }; 
        #register 'menu.admin.dfldfj' => { init_rc=>9999, label=>'asdfd', url=>'/ldkfjd', title=>'asdfasdf' }; 
    }
}

register 'menu.admin.service' => { label=>'Services', title=>'Services' }; 

sub dispatch {
    my ($self, %p )=@_;
    my $c = $p{app};
    my $config;
    my $config_data;
    if( $self->config ) {
        $config = Baseliner::Core::Registry->get( $self->config ) or die "Could not find config '$self->{config}' for service '$self->{name}'";
    } else {
        _log "Missing config for service '$self->{name}'";
        ## service will have to deal with @ARGV by itself
    }

    if( $p{'-cli'} ) {
        ## the command line is an overwrite of the usual stash system
        $config_data = $config->getopt;
        #$config_data->{argv} = \@argv_noservice;
        print "===Config $self->{config}===\n",_dump($config_data),"\n";
    } 
    elsif( $p{'-ns'} ) {
        $config_data = $config->load_from_ns($p{'-ns'} );
    }
    else {
        $config_data = $config->load_from_ns('/');
    }

    $self->run($c, $config_data);
}

=head2 run

Run module services subs ( service->code or sub module::service ). $self is an instance of the package where the service is located.

=cut
sub run {
    my $self= shift;  # 
    my $c = shift;
    my $service = $self->id;
    my $key = $self->key;
    my $version = $self->registry_node->version;
    my $handler = $self->handler;
    my $module = $self->module;
    my $args = $_[0] || {}; 
    my $service_noun = service_noun();

    # load logger
    my $logger;
    if( ref $self->logger ) {
        $logger = $self->logger;
    } else {
        my $logger_class = $self->logger_class;
        eval "require $logger_class"; 
        _throw _loc('Error requiring logger class %1', $logger_class) if $@;
        $logger = $logger_class->new(); 
    }

    # setup a dummy job if needed
    try {
        unless( ref $c->stash->{job} ) {
            $c->stash->{job} ||= BaselinerX::Job::Service::Runner->new;
            $c->stash->{job}->logger( $logger );
        }
    } catch {};


    $logger->verbose( exists($args->{v}) || exists($args->{debug}) );
    delete $args->{v};  # assume I'm the only one using this

    print "\n=== running $service_noun: $key | $version | $service | $module ===\n" 
        unless $self->quiet;

    # instanciate the service
    my $instance = $module->new( log=>$logger );

    if( ref($handler) eq 'CODE' ) {
        my $rc = $handler->( $instance, $c, @_ );
        $rc = 0 unless is_number $rc; # the service may return anything...
        $instance->log->rc( $rc );
        #_log $instance->log->msg;
        return $instance->log;
    } 
    elsif( $handler && $module ) {
        my $rc = $module->$handler( $instance, $c, @_);  
        $rc = 0 unless is_number $rc; # the service may return anything...
        $instance->log->rc( $rc );
        #_log $instance->log->msg;
        return $instance->log;
    }
    else {
        die "Can't find sub $service {...} nor a handler directive for the $service_noun '$service'";
    }
}


1;
