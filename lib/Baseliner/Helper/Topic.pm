package Baseliner::Helper::Topic;
use Moose;
use Baseliner::Utils qw(_array _loc);

has c => qw(is ro weak_ref 1);

sub topic_grid {
    my $self = shift;
    my ( $meta, $data, $user_security ) = @_;

    my $c = $self->c;

    my @topics;
    my @head;

    my $names = {
        name        => 'ID',
        title       => _loc('Title'),
        name_status => _loc('Status'),
        created_by  => _loc('Created By'),
        created_on  => _loc('Created On'),
        modified_by => _loc('Modified By'),
        modified_on => _loc('Modified On')
    };

    @topics = Util->_array( $data->{ $meta->{id_field} } );

    $meta->{columns} //= '';
    my $cols = ref $meta->{columns} ? $meta->{columns} : do {
        [ map { [ split /,/ ] } split /;/, $meta->{columns} ];
    };
    @head = map {
        my $nid = $_->[0];
        +{  key   => $nid,
            name  => ( $names->{$nid} // $_->[1] || $_->[0] ),
            width => $_->[3],
            type  => $_->[2]
            }
    } @$cols;

    my $permissions = Baseliner::Model::Permissions->new;

    @topics = grep {
        $permissions->user_has_action( $c->username, 'action.topics.view',
            bounds => { id_category => $_->{id_category} } )
          && $permissions->user_has_security( $c->username, $_->{_project_security} )
    } @topics;

    if ( !@head ) {
        @head = map { +{ key => $_, name => ( $names->{$_} // $_ ) } }
            qw/name title name_status created_by created_on modified_by modified_on/;
    }
    return { head => \@head, topics => \@topics };
}


1;
