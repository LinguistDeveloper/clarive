package Baseliner::Model::Favorites;
use Moose;
BEGIN { extends 'Catalyst::Model' }

use Baseliner::Utils qw(_decode_json);

sub rename_favorite {
    my $self = shift;
    my ( $user, $id_favorite, $text ) = @_;

    my $favorite = $user->favorites->{$id_favorite};
    $favorite->{text} = $text;
    $user->save;
}

sub add_favorite_item {
    my $self = shift;
    my ( $user, $favorite ) = @_;

    my $id = time . '-' . int rand(9999);
    defined $favorite->{$_} && $favorite->{$_} eq 'null' and delete $favorite->{$_} for qw/data menu/;

    if ( delete $favorite->{is_folder} ) {
        $favorite->{id_folder} = $id;
        $favorite->{icon}      = '/static/images/icons/folder-collapsed.svg';
        $favorite->{url}       = '/lifecycle/tree_favorites?id_folder=' . $id;
    }

    defined $favorite->{$_} and $favorite->{$_} = _decode_json( $favorite->{$_} ) for qw/data menu/;
    $favorite->{id_favorite} = $id;
    $favorite->{position}    = $self->_get_last_position($user);

    $user->favorites->{$id} = $favorite;
    $user->save;

    return $favorite;
}

sub get_children {
    my $self = shift;
    my ( $user, $id_parent ) = @_;

    $id_parent //= '';

    my $favorites = $user->favorites;
    my @children;

    foreach my $folder (
        sort { $favorites->{$a}->{position} <=> $favorites->{$b}->{position} }
        keys %{$favorites}
        )
    {
        if ( ( $favorites->{$folder}->{id_parent} // '' ) eq $id_parent ) {
            push @children, $favorites->{$folder};
        }
    }

    return \@children;
}

sub delete_nodes {
    my $self = shift;
    my ( $user, $id_favorite, $id_parent ) = @_;

    my $favorites             = $user->favorites;
    my $current_position_tree = $favorites->{$id_favorite}->{position};

    my @nodes_to_remove = $self->get_children_recursive( $user, $id_favorite );
    foreach my $id (@nodes_to_remove) {
        delete $favorites->{$id};
    }

    $self->remove_position( $user, $current_position_tree, $id_parent );
    $user->save;
}

sub get_children_recursive {
    my $self = shift;
    my ( $user, $id_favorite ) = @_;

    my $favorites = $user->favorites;
    my @nodes;

    push @nodes, $id_favorite;
    foreach my $id ( keys %$favorites ) {
        if ( defined $favorites->{$id}->{id_parent}
            && $favorites->{$id}->{id_parent} eq $favorites->{$id_favorite}->{id_favorite} )
        {
            push @nodes, $self->get_children_recursive( $user, $id );
        }
    }

    return @nodes;
}

sub remove_position {
    my $self = shift;
    my ( $user, $current_position_tree, $id_current_parent ) = @_;

    my $favorites = $user->favorites;

    my $children = $self->get_children( $user, $id_current_parent );
    foreach my $child (@$children) {
        $favorites->{ $child->{id_favorite} }->{position} = $child->{position} - 1
            if $child->{position} gt $current_position_tree;
    }

    $user->save;
}

sub update_position {
    my ( $self, $user, $id_favorite, $id_parent, %params ) = @_;

    my $favorites     = $user->favorites;
    my $action        = $params{action};
    my $nodes_ordered = $params{nodes_ordered};

    my $current_position_tree = $favorites->{$id_favorite}->{position};
    my $id_current_parent     = $favorites->{$id_favorite}->{id_parent};

    if ( ( $id_current_parent // '' ) ne $id_parent ) {
        $self->remove_position( $user, $current_position_tree, $id_current_parent );
    }

    $favorites->{$id_favorite}->{id_parent} = $id_parent;

    if ( $action && $action eq 'append' ) {
        $favorites->{$id_favorite}->{position} = $self->_get_last_position( $user, $id_parent );
    }
    else {
        foreach my $data_favorite (@$nodes_ordered) {
            $favorites->{ $data_favorite->{id_favorite} }->{position} = $data_favorite->{position};
        }
    }
    $user->save;
}

sub _get_last_position {
    my $self = shift;
    my ( $user, $id_parent ) = @_;

    $id_parent //= '';

    my $favorites = $user->favorites;
    my $position  = 0;

    foreach my $id ( keys %$favorites ) {
        $position++ if ( $favorites->{$id}->{id_parent} // '' ) eq $id_parent;
    }

    return $position;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
