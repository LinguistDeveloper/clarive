package BaselinerX::Model::CI;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use Array::Utils qw(:all);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

register 'registor.action.admin_ci' => {
    generator => sub {
		my %actions_admin_cis;
		for my $role ( Baseliner::Controller::CI->list_roles ) {

			my $name = $role->{role};
			for my $class ( packages_that_do( $role->{role} ) ) {
		    	my ($collection) = $class =~ /::CI::(.*?)$/;
		    	my $id_action = "action.ci.admin.".$role->{name}.".".$collection;
		    	$actions_admin_cis{$id_action} = { name => $id_action };
		    }
		}
        return \%actions_admin_cis;    
    }
};