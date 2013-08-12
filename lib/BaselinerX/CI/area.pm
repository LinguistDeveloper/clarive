package BaselinerX::CI::area;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Project';

sub icon { '/static/images/icons/area.png' }
sub storage { 'BaliProject' }

service 'scan' => 'Run Scanner' => sub {
    return 'Project scanner disabled';   
};

around table_update_or_create => sub {
    my ($orig, $self, $rs, $mid, $data, @rest ) = @_;

    my $temp_data; 
    delete $data->{versionid};
    delete $data->{ts};
    if( $data->{data} ) {
        # json to yaml
        $temp_data = _dump( _decode_json( $data->{data} ) );
        delete $data->{data};
    }

    my $row_mid = $self->$orig( $rs, $mid, $data, @rest );
    $mid //= $row_mid;  # necessary when creating
        my $row = DB->BaliProject->find( $mid );
    $row->ns('project/' . $mid );

    $row->data($temp_data);
    $row->update;
    $row_mid;
};

around load => sub {
    my ($orig, $self ) = @_;

	my $data = $self->$orig();
    
    #$data->{repository} = [ map { values %$_ }  DB->BaliMasterRel->search( { from_mid => $self->mid, rel_type => 'project_repository' }, { select=>'to_mid'} )->hashref->all ];
    $data->{data} = _load( $data->{data} ) if length $data->{data};

    return $data;
};

1;
