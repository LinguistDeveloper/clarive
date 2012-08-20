package BaselinerX::CA::Harvest::Provider::User;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::User;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.user' => {
	name	=>_loc('Harvest Users'),
	domain  => domain(),
    can_job => 0,
    finder  => \&find,
	handler => \&list, 
};

sub namespace { 'BaselinerX::CA::Harvest::Namespace::User' }
sub domain    { 'harvest.user' }
sub icon      { '/static/images/icon/user.gif' }
sub name      { 'HarvestUsers' }

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;
    my $rs = Baseliner->model('Harvest::Haruser')->search(undef,{ cache=>1 });
    my @ns;
    while( my $r = $rs->next ) {
        my $username = _trim $r->username;
        push @ns, BaselinerX::CA::Harvest::Namespace::User->new({
                ns      => 'harvest.user/' . $username,
                ns_name => $username,
                ns_type => _loc('Harvest User'),
                ns_id   => $r->usrobjid,
                ns_data => { $r->get_columns },
                provider=> 'namespace.harvest.user',
                related => [  ],
                });
    }
    return \@ns;
}

sub find {
    my ($self, $item ) = @_;
	my $rs = Baseliner->model('Harvest::Haruser')->search({ username=>$item });
	my $row = $rs->first;
	if( ref $row ) {
        my $username = $row->username;
		return BaselinerX::CA::Harvest::Namespace::User->new({
				ns      => 'harvest.user/' . $username,
				ns_name => $username,
				ns_type => _loc('Harvest User'),
				ns_id   => $row->usrobjid,
				ns_data => { $row->get_columns },
				provider=> 'namespace.harvest.user',
				related => [  ],
				});
	}
}

1;
