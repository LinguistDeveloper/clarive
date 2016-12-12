package BaselinerX::Service::UserServices;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;
with 'Baseliner::Role::Service';

register 'service.user.load' => {
    name => _locl('Load CI User Data'),
    form => '/forms/user_load.js',
    icon => '/static/images/icons/service-user-load.svg',
    handler => \&user_load,
};

sub user_load {
    my ( $self, $c, $config ) = @_;

    my $username = $config->{username} // _fail( _loc("Missing username") );

    my $mid_only  = $config->{mid_only};

    my $user_doc = ci->user->find_one({username => $username});

    _fail("User with username $username not found") unless $user_doc;

    return $mid_only && $user_doc ? $user_doc->{mid} : $user_doc;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
