package BaselinerX::Service::LDAPServices;
use Moose;
use Net::LDAP;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::CI;
use Baseliner::Sugar;
use Try::Tiny;
with 'Baseliner::Role::Service';

register 'service.ldap.search' => {
    name => 'Search in LDAP server',
    form => '/forms/ldap_search.js',
    icon => '/static/images/icons/page_lens.png',
    #icon => '/static/images/icons/package_add.png',
    handler => \&run_search_ldap,
};


sub run_search_ldap {
    my ($self, $c, $config ) = @_;
    my $stash = $c->stash;
    my $ldap = Net::LDAP->new( $config->{server_ip}, port=> $config->{ldap_port} ); ##  or die "$@"
    my $connection_mesg = $ldap->bind( $config->{ldap_user}, password => $config->{password} );
    my $search_result = $ldap->search(
        base   => $config->{ldap_base},
        filter => $config->{filter}
    );
    $stash->{ldap_search_return_code} = $connection_mesg->{resultCode};
    $stash->{ldap_search_result} = $search_result->{entries};
}

1;
