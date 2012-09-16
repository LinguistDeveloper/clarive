package BaselinerX::CI::project;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Project';

sub icon { '/static/images/icons/project.png' }
sub storage { 'BaliProject' }

has repositories => qw(is rw isa CIs coerce 1);

sub rel_type { { repositories=>[ to_mid => 'project_repository'] } }

#around table_update_or_create => sub {
#    my ($orig, $self, $rs, $mid, $data, @rest ) = @_;
#    my $repos = delete $data->{repository};
#
#    my $row_mid = $self->$orig( $rs, $mid, $data, @rest );
#    $mid //= $row_mid;  # necessary when creating
#
#    my $row = DB->BaliProject->find( $mid );
#    my @rs_repos = DB->BaliMaster->search( { mid => $repos } )->all;
#    $row->set_repositories( \@rs_repos, { rel_type => 'project_repository' } )
#};

#around load => sub {
#    my ($orig, $self ) = @_;
#
#	my $data = $self->$orig();
#    
#    $data->{repository} = [ map { values %$_ }  DB->BaliMasterRel->search( { from_mid => $self->mid, rel_type => 'project_repository' }, { select=>'to_mid'} )->hashref->all ];
#
#    _error $data;
#
#    return $data;
#};

1;
