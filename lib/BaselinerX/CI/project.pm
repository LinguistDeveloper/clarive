package BaselinerX::CI::project;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Project';
with 'Baseliner::Role::CI::VariableStash';

sub icon { '/static/images/icons/project.png' }

has_cis 'repositories';
has_ci 'parent_project';

sub rel_type { 
    { 
        repositories=>[ from_mid => 'project_repository'],
        parent_project =>[ from_mid => 'project_project'] 
    },
}

service 'scan' => 'Run Scanner' => sub {
    return 'Project scanner disabled';   
};

around save_data => sub {
    my ($orig, $self, $master_row, $data  ) = @_;

    my $mid = $master_row->mid;
    
	my $ret = $self->$orig($master_row, $data);
    
    my $row = DB->BaliProject->update_or_create({
        mid         => $mid,
        data        => undef,
        domain      => undef,
        active      => 1,
        id_parent   => $data->{parent_project},
        nature      => undef,
        name        => $master_row->name,
        description => $data->{description},
        bl          => $master_row->bl,
        ns          => 'project/' . $mid
    });
    
    return $ret;
};

around delete => sub {
    my ($orig, $self, $mid ) = @_;
    my $row = DB->BaliProject->find( $mid // $self->mid );  
    my $cnt = $row->delete if $row; 
    Baseliner->cache_remove( qr/^ci:/ );
    # bali project deletes CI from master, no orig call then 
    return $cnt;
};
    
around load => sub {
    my ($orig, $self ) = @_;

	my $data = $self->$orig();
    
    #$data->{repository} = [ map { values %$_ }  DB->BaliMasterRel->search( { from_mid => $self->mid, rel_type => 'project_repository' }, { select=>'to_mid'} )->hashref->all ];
    $data->{data} = _load( $data->{data} ) if length $data->{data};

    return $data;
};

method user_has_action( :$username, :$action=undef ) {
    return scalar grep { $_ == $self->mid } Baseliner->model( 'Permissions' )
        ->user_projects_with_action( username=>$username, action=>$action );
}

1;
