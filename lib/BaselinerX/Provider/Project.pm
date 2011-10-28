package BaselinerX::Provider::Project;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Namespace::Project;

with 'Baseliner::Role::Provider';

register 'namespace.project' => {
	name	=>_loc('Project'),
};

register 'namespace.project' => {
	name	=>_loc('Projects'),
	root    => 'project',
    can_job => 0,
	domain  => domain(),
    finder =>  \&find,
	handler =>  \&list,
};

sub namespace { 'BaselinerX::Namespace::Project' }
sub domain    { 'project' }
sub icon      { '/static/images/scm/project.gif' }
sub name      { 'Project' }

sub find {
    my ($self, $item ) = @_;
    my $prj = Baseliner->model('Baseliner::BaliProject')->find( $item );
    return BaselinerX::Namespace::Project->new({ row => $prj }) if( ref $prj );
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
	

	my $rs = Baseliner->model('Baseliner::BaliProject')->search(
		{ },
		{
			%range
		}
	);
	my @ns;
	while( my $r = $rs->next ) {
            push @ns, BaselinerX::Namespace::Project->new({
                ns      => 'project/' . $r->id,
                ns_name => $r->name,
				ns_type => _loc('Project'),
				ns_id   => $r->id,
				ns_data => { $r->get_columns },
                provider=> 'namespace.project',
                related => [  ],
			});
	}
	my $cnt = scalar @ns;
	my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;
	_log "provider list finished (records=$cnt/$total).";
    return { data=>\@ns, total=>$total, count=>$cnt };
}

1;

