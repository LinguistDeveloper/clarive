package BaselinerX::CA::Harvest::Provider::Project;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::Project;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.project' => {
	name	=>_loc('Harvest Project'),
};

register 'namespace.harvest.project' => {
	name	=>_loc('Harvest Projects'),
	root    => 'harvest.project',
    can_job => 0,
	domain  => domain(),
    finder =>  \&find,
	handler =>  \&list,
};

sub namespace { 'BaselinerX::CA::Harvest::Namespace::Project' }
sub domain    { 'harvest.project' }
sub icon      { '/static/images/scm/project.gif' }
sub name      { 'Project' }

sub find {
    my ($self, $item ) = @_;
    my $env = Baseliner->model('Harvest::Harenvironment')->search({ environmentname=>$item })->first;
    return BaselinerX::CA::Harvest::Namespace::Project->new({ row => $env }) if( ref $env );
}

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};
    my $sql_query;

	_log "provider list started...";

	# paging 
	my %range = defined $p->{start} && defined $p->{limit}
		? ( page => (abs( $p->{start} / $p->{limit} ) + 1), rows=>$p->{limit} )
		: ();
	

	my $rs = Baseliner->model('Harvest::Harenvironment')->search(
		{ envobjid=>{ '>', '0'}, envisactive=>'Y' },
		{
			%range
		}
	);
	my @ns;
	while( my $r = $rs->next ) {
			( my $env_short = $r->environmentname )=~ s/\s/_/g;
            push @ns, BaselinerX::CA::Harvest::Namespace::Project->new({
                ns      => 'harvest.project/' . $env_short,
                ns_name => $env_short,
				ns_type => _loc('Harvest Project'),
				ns_id   => $r->envobjid,
				ns_data => { $r->get_columns },
                provider=> 'namespace.harvest.project',
                related => [  ],
			});
	}
	my $cnt = scalar @ns;
	my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;
	_log "provider list finished (records=$cnt/$total).";
    return { data=>\@ns, total=>$total, count=>$cnt };
}

1;
