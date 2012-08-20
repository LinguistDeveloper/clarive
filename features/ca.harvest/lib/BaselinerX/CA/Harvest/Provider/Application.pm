package BaselinerX::CA::Harvest::Provider::Application;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::Application;
use Try::Tiny;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.application' => {
	name	=>_loc('Application'),
	domain  => domain(),
	can_job => 0,
    finder =>  \&find,
	handler =>  \&list,
};

sub namespace { 'BaselinerX::CA::Harvest::Namespace::Application' }
sub domain    { 'harvest.application' }
sub icon      { '/static/images/scm/project.gif' }
sub name      { 'HarvestApplication' }

sub find {
    my ($self, $item ) = @_;
	my $rs = Baseliner->model('Harvest::Harenvironment')->search({ environmentname=>{ -like => "$item%" } });
	my $row = $rs->first;
	if( ref $row ) {
		my $app = BaselinerX::CA::Harvest::Project::get_apl_code($row->environmentname);
		return BaselinerX::CA::Harvest::Namespace::Application->new({
				ns      => 'application/' . $app,
				ns_name => $app,
				ns_type => _loc('Application'),
				ns_id   => $app,
				ns_data => { $row->get_columns },
				provider=> 'namespace.harvest.application',
				related => [  ],
				});
	} else {
		# try the repository
		return Baseliner->model('Repository')->get( ns=>"application/$item" );
	}
	#$self->not_implemented;
    #my $package = Baseliner->model('Harvest::Harpackage')->search({ packagename=>$item })->first;
    #return BaselinerX::CA::Harvest::Namespace::Package->new({ row => $package }) if( ref $package );
}

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};

	_log "provider list started...";
	
	my $hardb = BaselinerX::CA::Harvest::DB->new;

	my $sql_query = { envobjid=>{ '>', '0'}, envisactive=>'Y' };

	# user control
	if( $p->{username} && ! $hardb->is_superuser($p->{username}) ) {
		my @envs = $hardb->envs_for_user( $p->{username} ); 
		$sql_query->{envobjid} = { -in => [ @envs ] }; 
	}

	# paging 
	my %range = defined $p->{start} && defined $p->{limit}
		? ( page => (abs( $p->{start} / $p->{limit} ) + 1), rows=>$p->{limit} )
		: ();

	# searching
	if( $query ) {
		$query = lc $query;
		$sql_query->{"lower(environmentname)"} = { -like => "%$query%" };
	}

	# query
	my $rs = Baseliner->model('Harvest::Harenvironment')->search( $sql_query , { %range });
	my %apps;
	while( my $r = $rs->next ) {
		my $env_short = BaselinerX::CA::Harvest::Project::get_apl_code($r->environmentname);
		$apps{ $env_short }{ $r->environmentname } = { data=>{ $r->get_columns } };
	}
	my @ns;
	foreach my $app ( keys %apps ) {
		push @ns, BaselinerX::CA::Harvest::Namespace::Application->new({
			ns      => 'application/' . $app,
			ns_name => $app,
			ns_type => _loc('Application'),
			ns_id   => $app,
			icon    => '/static/images/scm/project.gif',
			ns_data => $apps{ $app },
			provider=> 'namespace.harvest.application',
			related => [  ],
		});
	}

	my $cnt = scalar @ns;
	my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;

	_log "provider list finished (records=$cnt/$total).";
	return { data=>\@ns, total=>$total, count=>$cnt };
}

1;
