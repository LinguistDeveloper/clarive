package Baseliner::Model::CI;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(packages_that_do _fail _array _warn _loc _log);
with 'Baseliner::Role::Service';
use v5.10;

BEGIN { extends 'Catalyst::Model' }

register 'service.ci.update' => {
    handler=>sub{
        my ($self,$c,$config)=@_;
        my $args = $config->{args};
        my $coll = $args->{collection} || $args->{coll} || _fail _loc('Missing parameter: collection');
        my $ci = ci->$coll->search_ci( %{ $args->{query} || _fail _loc('Missing parameter: query') } );
        _fail _loc('User not found for query %1', JSON::XS->new->encode($args->{query})) unless $ci;
        $ci->update( %{ $args->{update} || _fail _loc('Missing parameter: update') } );
        _log _loc("Update user ok");
    },
     icon => '/static/images/icons/service-ci-update.svg',
};

sub bounds_role {
    my $self = shift;

    my @roles;
    for my $role ( Baseliner::Controller::CI->list_roles ) {
        push @roles, $role->{role};
    }

    return sort { $a->{title} cmp $b->{title} } map { { id => $_, title => $_ } } @roles;
}

sub bounds_collection {
    my $self = shift;
    my (%params) = @_;

    my @roles = $params{role} ? ( { role => $params{role} } ) : ( Baseliner::Controller::CI->list_roles );

    my @collections;

    for my $role ( @roles ) {
        my $name = $role->{role};
        for my $class ( packages_that_do( $role->{role} ) ) {
            my ($collection) = $class =~ /::CI::(.*?)$/;

            push @collections, $collection;
        }
    }

    return sort { $a->{title} cmp $b->{title} } map { { id => $_, title => $_ } } @collections;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
