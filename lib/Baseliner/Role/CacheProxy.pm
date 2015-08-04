package Baseliner::Role::CacheProxy;
use MooseX::Role::Parameterized;
use Clarive::cache;

parameter methods => (
    isa      => 'ArrayRef',
    required => 1,
);

parameter cache_key_cb => (
    isa      => 'CodeRef',
    required => 1,
);

role {
    my $p = shift;

    my $methods      = $p->methods;
    my $cache_key_cb = $p->cache_key_cb;

    foreach my $method (@$methods) {
        around $method => sub {
            my ( $orig, $self, @args ) = @_;

            my $cache_key = $cache_key_cb->($self, @args);

            my $cached = cache->get($cache_key);
            return $cached if $cached;

            my $retval = $self->$orig(@args);

            cache->set( $cache_key, $retval );

            return $retval;
        };
    }
};

1;
