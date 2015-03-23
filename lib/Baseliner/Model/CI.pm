package Baseliner::Model::CI;
use Baseliner::Plug;
use Baseliner::Utils qw(packages_that_do _fail _array _warn _loc _log);
with 'Baseliner::Role::Service';
use v5.10;

BEGIN { extends 'Catalyst::Model' }

register 'registor.action.ci' => {
    generator => sub {
		my %actions_admin_cis;
		for my $role ( Baseliner::Controller::CI->list_roles ) {

			my $name = $role->{role};
			for my $class ( packages_that_do( $role->{role} ) ) {
		    	my ($collection) = $class =~ /::CI::(.*?)$/;
		    	my $id_action_admin = "action.ci.admin.".$role->{name}.".".$collection;
		    	$actions_admin_cis{$id_action_admin} = { name => $id_action_admin };
		    	my $id_action_view = "action.ci.view.".$role->{name}.".".$collection;
		    	$actions_admin_cis{$id_action_view} = { name => $id_action_view };
		    }
		}
        return \%actions_admin_cis;    
    }
};

register 'service.ci.update' => {
    handler=>sub{
        my ($self,$c,$config)=@_;
        my $args = $config->{args};
        my $coll = $args->{collection} || $args->{coll} || _fail _loc 'Missing parameter: collection';
        my $ci = ci->$coll->search_ci( %{ $args->{query} || _fail('Missing parameter: query') } );
        _fail _loc 'User not found for query %1', JSON::XS->new->encode($args->{query}) unless $ci;
        $ci->update( %{ $args->{update} || _fail('Missing parameter: update') } );
        _log _loc "Update user ok";
    }
};
1;

