package BaselinerX::CA::Harvest::Service::ApprovalRequest;
use v5.10;
use Baseliner::Plug;
use Baseliner::Utils;

use utf8;

with 'Baseliner::Role::Service';

register 'action.harvest.approve' => { name=>'Approve packages in Harvest' };

register 'service.harvest_approval.new' => {
    name => 'Request Package Approval',
    handler => \&run,
};

register 'service.harvest_approval.callback' => {
    name => 'React to Approved Packages',
    handler => \&callback,
};

sub run {
    my ( $self, $c, $p ) = @_;
	_check_parameters( $p, qw/username package bl project/ );
	local *STDERR = *STDOUT;  # send stderr to stdout to avoid false error msg logs
	my ($table,$field);
	if( $p->{comments} ) {
		($table,$field) = split /:/,$p->{comments};
	}
	foreach my $pkg ( _array( $p->{package} ) ) {
		say "Checking $pkg...";
		my $ns = "harvest.package/$pkg"; 
		my $item = Baseliner->model('Namespaces')->get( $ns );

		# get comments, if available
		my $comments;
		if( $p->{table} && $p->{field} ) {
			$comments = $item->form_data( table=>$p->{table}, field=>$p->{field} );
		}
        $p->{state} ||= $item->state;
		_throw _loc 'Could not find package "%1"', $_ unless ref $item;
		say "Requesting approval for Package $item->{ns_name}";
		my $app = $item->application or _throw _loc 'Could not find application for %1', $item->{item};
		Baseliner->model('Request')->request(
				name   => "Aprobación del item $item->{ns_name} en la aplicación $app",
				action => 'action.harvest.approve',
				data   => $p,
				callback => 'service.harvest.approval.callback',
				#template => 'email/package_approval.html',
				vars   => { reason=>$comments },
				username => $p->{username},
				#TODO role_filter => $p->{role},    # not working, no user selected??
				ns     => $ns,
				bl     => $p->{bl}, 
		);
	}
}

sub callback {
    my ( $self, $c, $p ) = @_;

	_log 'Starting package callback...';

    my $data    = $p->{data};
    my $request = $p->{request};
    my $item    = $p->{item};

	my $ns = Baseliner->model('Namespaces')->get( $item );
	return unless ref $ns;
	foreach my $action ( _array $data->{action} ) {
		if( $action eq 'promote' ) {
			$ns->promote;
		}
		elsif( $action eq 'approve' ) {
			$ns->approve( username=>$request->finished_by );
		}
	}
}

1;
