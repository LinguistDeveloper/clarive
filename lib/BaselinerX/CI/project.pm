package BaselinerX::CI::project;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Project';

sub icon { '/static/images/icons/project.png' }
sub storage { 'BaliProject' }

has repositories => qw(is rw isa CIs coerce 1);

sub rel_type { { repositories=>[ from_mid => 'project_repository'] } }

around table_update_or_create => sub {
   my ($orig, $self, $rs, $mid, $data, @rest ) = @_;
 
   my $row_mid = $self->$orig( $rs, $mid, $data, @rest );
   $mid //= $row_mid;  # necessary when creating

   my $row = DB->BaliProject->find( $mid );
   $row->ns('project/' . $mid );
   $row->update;
   $row_mid;
};

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
