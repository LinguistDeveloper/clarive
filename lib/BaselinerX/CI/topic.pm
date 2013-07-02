package BaselinerX::CI::topic;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Topic';

has title       => qw(is rw isa Any);
has id_category => qw(is rw isa Any);
has name        => qw(is rw isa Any);
has category    => qw(is rw isa Any);

#has_ci 'projects';
sub rel_type {
    { 
        projects => [ from_mid => 'topic_project' ] ,
    };
}


sub icon { '/static/images/icons/topic.png' }

sub storage { 'BaliTopic' }

around load => sub {
    my ($orig, $self ) = @_;
    my $data = $self->$orig();
    #$data->{category} = { DB->BaliTopic->find( $self->mid )->categories->get_columns };
    return $data;
};

around table_update_or_create => sub {
    my ( $orig, $self, $rs, $mid, $data, @rest ) = @_;
    my $name = delete $data->{name};
    #$data->{title} //= $name; 
    $data->{created_by} //= 'internal';
    delete $data->{title};
    delete $data->{active};
    delete $data->{versionid};
    delete $data->{moniker};
    delete $data->{data};
    delete $data->{ns};
    $self->$orig( $rs, $mid, $data, @rest );
};

sub files {
    my $self  = shift;
    my @files = Baseliner->model( 'Baseliner::BaliMasterRel' )->search(
        {from_mid => [ $self->mid ], rel_type => 'topic_file_version'},
        {

            #                join    => [ 'topic_file_version_to' ],
            join    => {'topic_file_version_to' => {'file_projects' => {'directory'}}},
            +select => [
                'topic_file_version_to.filename', 'max(topic_file_version_to.versionid)',
                'max(topic_file_version_to.mid)', 'max(directory.name)'
            ],
            +as      => [ 'filename', 'version', 'mid', 'path' ],
            group_by => 'topic_file_version_to.filename',
        }
    )->hashref->all;
    return @files;
} 

sub topic_name {
    my ($self) = @_;
    return sprintf '%s #%s - %s', 'Cmbio', $self->mid, $self->name; 
}

1;
