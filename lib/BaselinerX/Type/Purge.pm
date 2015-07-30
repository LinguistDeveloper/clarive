package BaselinerX::Type::Purge;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
with 'Baseliner::Role::Registrable';

register_class 'purge' => __PACKAGE__;

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'name' => ( is=> 'rw', isa=> 'Str' );
has 'desc' => ( is=> 'rw', isa=> 'Str' );
has 'handler' => ( is=> 'rw', isa=> 'CodeRef' );
has 'config' => ( is=> 'rw', isa=> 'Str' );

sub run {
    my $self= shift;  # 
    my $c = shift;
    my $service = $self->id;
    my $key = $self->key;
    my $version = $self->registry_node->version;
    my $handler = $self->handler;
    my $module = undef; # TODO
    my $logger = undef; # TODO

    # instanciate the service
    my $instance = $module->new( log=>$logger );

    if( ref($handler) eq 'CODE' ) {
        $handler->( $instance, $c, @_ );
        #_log $instance->log->msg;
        return $instance->log;
    } 
    elsif( $handler && $module ) {
        $module->$handler( $instance, $c, @_);	
        #_log $instance->log->msg;
        return $instance->log;
    }
    else {
        die "Can't find sub $service {...} nor a handler directive for the service '$service'";
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

