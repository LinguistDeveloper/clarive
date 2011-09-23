package BaselinerX::Service::RoleServices;
use v5.10;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'service.user.view' => {
	name => 'List all roles users',
	handler => \&user_view,
};

register 'service.role.view' => {
	name => 'List all roles',
	handler => \&role_view,
};

register 'service.role.grant' => {
	name => 'Add a user to a role',
	handler => \&user_add,
};

register 'service.role.add' => {
	name => 'Add an action to a role',
	handler => \&role_add,
};

sub role_add {
	my ( $self, $c, $p ) = @_;
	$p->{role} or _throw 'Missing parameter role';
	$p->{action} or _throw 'Missing parameter action';
	unless( $c->model('Permissions')->role_exists( $p->{role} ) ) {
		$p->{description} or _throw 'A new role will be created, but it is missing the parameter description.';
		$c->model('Permissions')->create_role( $p->{role} );
		say _loc('Role %1 created.', $p->{role} );
	}
	my $data = $c->model('Permissions')->add_action( $p->{action}, $p->{role} );
	say _loc('Action %1 added to role %2.', $p->{action}, $p->{role} );
}

sub role_view {
	my ( $self, $c, $p ) = @_;
	my $data = $c->model('Permissions')->role( $p->{role} );
	_throw "No data found for role $p->{role}" unless ref $data;
	print _dump $data;
}

sub user_view {
	my ( $self, $c, $p ) = @_;
	if( $p->{username} ) {	
		my $data = $c->model('Permissions')->list( username=>$p->{username}, );
		_throw "No data found for user $p->{username}" unless ref $data;
		print _dump $data;
	} else {
		my @users = $c->model('Permissions')->all_users;
		foreach my $username ( @users )  {
			print "---------| $username";
			my @roles = $c->model('Permissions')->user_roles($username);
			if( scalar @roles ) {
				print "\n";
				print join '', map { _dump $_ } @roles;
			} else {
				print " --> no data\n";
			}
		}
	}
}

sub user_add {
	my ( $self, $c, $p ) = @_;
	my $username = $p->{username} or _throw 'Missing parameter username';
	my $role = $p->{role} or _throw 'Missing parameter role';
	my $ns = $p->{ns};
	unless( $ns ) {
		$ns ||= '/';
		print "No namespace ns provided, granting role to all namespaces\n";
	}
	print _loc("Granting role %1 to user %2...", $role, $username);
    my $ret = $c->model('Permissions')->grant_role( username=>$username, role=>$role, ns=>$ns );
	print $ret ? "\nDone.\n" : "\nError\n";
}

1;
