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

sub list_topics {
    my $self = shift;
    my ( $meta, $data, $user_security ) = @_;

    my $c = $self->c;

    my @topics;
    my @head;
    my %related_cis;
    my @hide_list_statuses;

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
    my $cols = ref $meta->{columns} ? $meta->{columns} : do {
        [ map { [ split /,/ ] } split /;/, ($meta->{columns} // '') ];
    };

    @head = map {
        my $nid = $_->[0];
        +{  key   => $nid,
            name  => ( $names->{$nid} // $_->[1] || $_->[0] ),
            width => $_->[3],
            type  => $_->[2]
            }
    } @$cols;
    if ( !@head ) {
        @head = map { +{ key => $_, name => ( $names->{$_} // $_ ) } }
            qw/name title name_status created_by created_on modified_by modified_on/;
    }
    my @custom_columns = _array $meta->{custom_columns};
    foreach my $custom_column (@custom_columns) {
        my $name =
          $custom_column->{display_column} ne '' ? $custom_column->{display_column} : $custom_column->{id_column};
        push @head, { key => $custom_column->{id_column}, name => $name };
    }
    @hide_list_statuses = map { [ split /,/ ] } $meta->{hide_list_statuses}
        if $meta->{hide_list_statuses};

    my @topics_mids = map { $_->{mid} } @topics;
    my @related_mids
        = map { $_->{to_mid} }
        mdb->master_rel->find( { 'from_mid' => mdb->in(@topics_mids) } )->all;
    push @related_mids,
        map { $_->{from_mid} }
        mdb->master_rel->find( { 'to_mid' => mdb->in(@topics_mids) } )->all;

    %related_cis = map { $_->{mid} => $_->{name} }
        mdb->master->find( { mid => mdb->in(@related_mids) } )->all;
    if ( @hide_list_statuses && scalar @hide_list_statuses > 0 ) {
        for my $status ( _array @hide_list_statuses ) {
            @topics
                = grep { $_->{"category_status"}{type} ne "$status" } @topics;
        }
    }

    my $permissions = Baseliner::Model::Permissions->new;

    @topics = grep {
        $permissions->user_has_action( $c->username, 'action.topics.view',
            bounds => { id_category => $_->{id_category} } )
          && $permissions->user_has_security( $c->username, $_->{_project_security} )
    } @topics;

    return {
        head        => \@head,
        topics      => \@topics,
        related_cis => \%related_cis
    };
}


1;
