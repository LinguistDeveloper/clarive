package Baseliner::Model::Users;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub get {
    my ($self, $username ) = @_;

    {
        # try locally
        my $rs = Baseliner->model('Baseliner::BaliUser')->search({ username=>$username });
        rs_hashref( $rs );
        my $user = $rs->first;
        $user->{data} = _load( $user->{data} ) if defined $user->{data};
        return $user if defined $user;
    }
    {
        # FIXME this is old
	my $rs = Baseliner->model('Harvest::Harallusers')->search({ username=>$username });
    rs_hashref( $rs );
	my $u = $rs->first;
	return {} unless ref $u;
	return $u;
}
}

# get user data from the database
sub populate_from_ldap {
    my ($self, $who ) = @_;
	
	my $where = defined $who ? { username=>$who } : {};
	my $rs = Baseliner->model('Baseliner::BaliUser')->search($where);
	while( my $r = $rs->next ) {
		my $username = $r->username;
		next unless $username;
		my $u = $self->get( $username );
		next unless defined $u->{realname};
		$u->{realname} =~ tr/0-9a-zA-Z //dcs; # sanitize
		$r->realname( $u->{realname} );
		$r->update;
	}
}

1;
