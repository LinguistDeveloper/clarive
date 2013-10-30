package CHI::Driver::BaselinerRedis;
use Mouse;
use Check::ISA;
extends 'CHI::Driver::Redis';

sub _verify_redis_connection {
    my ($self) = @_;
    return 1 if $self->redis && $self->redis->ping;
    my $params = $self->_params;
    my $redis = Redis->new(
        server => $params->{server} || '127.0.0.1:6379',
        debug => $params->{debug} || 0
    );
    if(obj($redis, 'Redis')) {
        # We apparently connected, success!
        $self->redis($redis);
        return 1;
    } else {
        die('Failed to connect to Redis');
    }
    return 1;
} 

1;


