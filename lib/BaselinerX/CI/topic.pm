package BaselinerX::CI::topic;
use Moose;
with 'Baseliner::Role::CI::Internal';

has title    => qw(is rw isa Any);
has id_category => qw(is rw isa Any);
has name    => qw(is rw isa Any);


sub icon { '/static/images/icons/topic.png' }

sub storage { 'BaliTopic' }

around table_update_or_create => sub {
    my ( $orig, $self, $rs, $mid, $data, @rest ) = @_;
    $data->{username} = delete $data->{name};
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
} ## end sub files
1;
