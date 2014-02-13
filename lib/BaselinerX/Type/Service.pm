package BaselinerX::Type::Service;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Registrable';

register_class 'service' => __PACKAGE__;
sub service_noun { 'service' };

has id           => ( is => 'rw', isa => 'Str', default => '' );
has name         => ( is => 'rw', isa => 'Str' );
has desc         => ( is => 'rw', isa => 'Str' );
has handler      => ( is => 'rw', isa => 'CodeRef' );
has config       => ( is => 'rw', isa => 'Str' );
has form         => ( is => 'rw', isa => 'Str', default => '' );
has logger_class => ( is => 'rw', isa => 'Str', default => 'Baseliner::Core::Logger::Base' );    # class
has logger       => ( is => 'rw', isa => 'Any' );
has data         => ( is => 'rw', isa => 'HashRef' );

has frequency     => ( is => 'rw', isa => 'Int' );                                               # frequency value in seconds
has frequency_key => ( is => 'rw', isa => 'Str' );                                               # frequency config key
has scheduled     => ( is => 'rw', isa => 'Bool' );                                              # true for a scheduled job

has log          => ( is => 'rw', isa => 'Object' );
has show_in_menu => ( is => 'rw', isa => 'Bool' );
has daemon       => ( is => 'rw', isa => 'Bool', default => 0 );
has job_service  => ( is => 'rw', isa => 'Bool', default => 0 );  # service is meant to be used in a job

has quiet => ( is => 'rw', isa => 'Bool', default => 0 );
has type  => ( is => 'rw', isa => 'Str',  default => 'std' );
has alias => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub {
        my ( $self, $alias, $meta ) = @_;
        my $alias_key = 'alias.' . $alias;
        register $alias_key => { link => $self->id };
        Baseliner::Plug->registry->initialize($alias_key);
    }
);

has js_input  => ( is=> 'rw', isa=> 'Str', default=>'' );
has js_output => ( is=> 'rw', isa=> 'Str', default=>'' );

has icon => (is=>'rw', isa=>'Str', default=>'/static/images/icons/service.png');

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

register 'menu.admin.service' => { label=>'Services', title=>'Services', action => 'menu.admin.service.%', index=>1000 }; 

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
        _log "===Config $self->{config}===\n",_dump($config_data),"\n";
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
    my @args = @_;

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
            $c->stash->{job} ||= BaselinerX::Service::Runner->new;   # XXX dispatcher is creating this with every service, bummer
            $c->stash->{job}->logger( $logger );
            $c->stash->{job}->job_stash( $c->stash );
        }
    } catch {};

    # logfile
    $c->stash->{job}->job_stash->{logfile} = $c->stash->{logfile} if $c->stash->{job};

    $logger->verbose( exists($args->{v}) || exists($args->{debug}) );
    delete $args->{v};  # assume I'm the only one using this

    _log "\n=== running $service_noun: $key | $version | $service | $module ===\n" 
        unless $self->quiet;

    # instanciate the service
    my $instance = $module->new( log=>$logger );

    # check the service implements role
    _throw qq{Service '$key' doesn't implement Baseliner::Role::Service. Please, put:

        with 'Baseliner::Role::Service'; 
        
    within your class.} unless $instance->does('Baseliner::Role::Service');

    # try to set the job for the service (a Baseliner::Role::Service attribute)
    try { $c->stash->{job} and $instance->job( $c->stash->{job} ); } catch {};

    my $rc = try {
        ref $handler eq 'CODE' and return $handler->( $instance, $c, @args );
        $handler && $module and return $module->$handler( $instance, $c, @args );
        die "Can't find sub $service {...} nor a handler directive for the service '$service'";
    } catch {
        _fail shift();
    };
    _debug "RC1=$rc" if $rc;
    if( ! is_number( $rc ) ) { # the service may return anything...
        $instance->log->data( $rc );
        $rc = 0;
    }
    _debug "RC2=$rc" if $rc;
    $instance->log->rc( $rc );
    return $instance->log;
}

sub run_container {
    my ($self,$stash,$config,$obj) = @_;
    my $handler = $self->handler ;
    _fail _loc 'Service handler missing' unless ref $handler eq 'CODE';
    _fail _loc 'Missing argument 1, stash' unless ref $stash eq 'HASH';
    $config //= {};
    # create dummy job if we don't have one
    $stash->{job} or local $stash->{job} = BaselinerX::Type::Service::Container::Job->new( job_stash=>$stash );
    my $container = BaselinerX::Type::Service::Container->new( stash=>$stash, config=>$config ); 
    my $pkg = $self->module;
    $obj ||= $pkg->new(); 
    return $handler->( $obj, $container, $config );
}

######################################################################
package BaselinerX::Type::Service::Container;
use Baseliner::Moose;
has stash  => qw(is rw isa HashRef required 1);
has config => qw(is rw isa HashRef), default=>sub{ +{} };
sub job { $_[0]->stash->{job} }
sub logger { $_[0]->job->logger }

package BaselinerX::Type::Service::Container::Job;
use Baseliner::Moose;
has job_dir => qw(is rw isa Str lazy 1), default=>sub{ Util->_tmp_dir() };
has job_stash  => qw(is rw isa HashRef required 1 weak_ref 1);
has exec => qw(is rw isa Num default 1);
has backup_dir         => qw(is rw isa Any lazy 1), default => sub { 
    my ($self) = @_;
    return ''.Util->_file( $self->job_dir, '_backups' );
};
sub logger { 'BaselinerX::Type::Service::Container::Job::Logger' }

package BaselinerX::Type::Service::Container::Job::Logger;
#use Moose;  # no need for a new
our $AUTOLOAD;
sub AUTOLOAD {
    shift;
    my $name = $AUTOLOAD;
    my @a = reverse(split(/::/, $name));
    my $lev = $a[0];
    my ($cl,$fi,$li) = caller(0);
    Util->_log_me( $lev // 'info', $cl, $fi, $li, @_ );
}
1;
