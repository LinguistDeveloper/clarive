package BaselinerX::Project;
use Moose;
with 'Baseliner::Role::Namespace::Project';
sub checkout { }
=head1 DESCRIPTION

A Baseliner Project, defined in BALI_PROJECT.

Namespace and provider for getting a Project as a Namespace.  

    ns_get 'project/1'; 

Returns the namespace object for the first row of Project.

=cut

package BaselinerX::Project::Provider;
use Moose;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Provider';

register 'namespace.project' => {
    name    =>_loc('Baseliner Project'),
};

register 'namespace.project' => {
    name    =>_loc('Baseliner Projects'),
    root    => 'project',
    can_job => 0,
    domain  => domain(),
    finder =>  \&find,
    handler =>  \&list,
};

sub namespace { 'BaselinerX::Project' }
sub domain    { 'project' }
sub icon      { '/static/images/scm/project.gif' }
sub name      { 'Baseliner Project' }

sub find {
    my ($self, $ns ) = @_;
    my ($provider, $item ) =  ns_split $ns;
    my $r = Baseliner->model('Baseliner::BaliProject')->find( $item );
    return BaselinerX::Project->new(
        {   ns       => 'project/' . $r->id,
            ns_name  => $r->name,
            ns_type  => _loc('Baseliner Project'),
            ns_id    => $r->id,
            ns_data  => { $r->get_columns },
            provider => 'namespace.project',
            related  => [],
        }
    );
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
	
	my $rs = Baseliner->model('Baseliner::BaliProject')->search( {  }, { %range });
	my @ns;
	while( my $r = $rs->next ) {
            push @ns, BaselinerX::Project->new({
                ns      => 'project/' . $r->id,
                ns_name => $r->name,
				ns_type => _loc('Baseliner Project'),
				ns_id   => $r->id,
				ns_data => { $r->get_columns },
                provider=> 'namespace.project',
                related => [ ],
			});
	}
	my $cnt = scalar @ns;
	my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;
	_log "provider list finished (records=$cnt/$total).";
    return { data=>\@ns, total=>$total, count=>$cnt };
}

1;

