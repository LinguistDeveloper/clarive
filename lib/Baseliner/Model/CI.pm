package Baseliner::Model::CI;
use Baseliner::Plug;
use Baseliner::Utils qw(packages_that_do _fail _array _warn);
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

1;

