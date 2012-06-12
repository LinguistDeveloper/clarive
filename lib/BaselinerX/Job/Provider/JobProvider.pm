package BaselinerX::Job::Provider::JobProvider;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use BaselinerX::Job::Namespace::JobNamespace;

with 'Baseliner::Role::Provider';

register 'namespace.job' => {
	name	=>_loc('Job'),
	domain  => domain(),
	can_job => 0,
    finder =>  \&find,
	handler =>  \&list,
};

sub namespace { 'BaselinerX::Job::Namespace::JobNamespace' }
sub domain    { 'job' }
sub icon      { '/static/images/icon/job.gif' }
sub name      { 'Jobs' }

sub find {
    my ($self, $item ) = @_;
	my $rs = Baseliner->model('Baseliner::BaliJob')->search({ name=>{ -like => "$item%" } });
	my $row = $rs->first;
	if( ref $row ) {
		return BaselinerX::Job::Namespace::JobNamespace->new({ row=> $row });
	}
}

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};

	_log "provider list started...";
	
	# user control
	if( $p->{username} && ! Baseliner->model('Permissions')->is_superuser($p->{username}) ) {
		#FIXME job lookup
	}

	# paging 
	my %range = defined $p->{start} && defined $p->{limit}
		? ( page => (abs( $p->{start} / $p->{limit} ) + 1), rows=>$p->{limit} )
		: ();

	# searching
	my $sql_query = {};
	if( $query ) {
		$query = lc $query;
		$sql_query->{"lower(name)"} = { -like => "%$query%" };
	}

	# go
	my @ns;
	my $rs = Baseliner->model('Baseliner::BaliJob')->search( $sql_query , { %range });
	while( my $r = $rs->next ) {
		#push @ns, BaselinerX::CA::Harvest::Namespace::Application->new({ row=> $r });
	}

	my $cnt = scalar @ns;
	my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;

	_log "provider list finished (records=$cnt/$total).";
	return { data=>\@ns, total=>$total, count=>$cnt };
}

1;

