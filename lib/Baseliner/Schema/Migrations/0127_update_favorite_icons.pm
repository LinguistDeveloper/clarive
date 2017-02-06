package Baseliner::Schema::Migrations::0127_update_favorite_icons;
use Baseliner::Schema::Migrations::0119_modify_structure_favorite_tree;
use Moose;

my $DEFAULT_ICON = '/static/images/icons/favorite.svg';

sub upgrade {
    my $self = shift;

    my $all_users = ci->user->find;

    while ( my $user_doc = $all_users->next ) {
        my $user      = ci->new( $user_doc->{mid} );
        my $favorites = $user->favorites;

        foreach my $favorite ( keys %$favorites ) {
            my $current_icon = $favorites->{$favorite}->{icon};
            if(!$self->_exists_icon($current_icon)){
                my $new_icon = Baseliner::Schema::Migrations::0119_modify_structure_favorite_tree->get_icon($current_icon);
                $current_icon =  $new_icon ? $new_icon : $DEFAULT_ICON;
                $favorites->{$favorite}->{icon} = $current_icon;
                $favorites->{$favorite}->{data}->{click}->{icon} = $current_icon;
            }
        }
        $user->save;
    }
}

sub _exists_icon {
    my $self = shift;
    my ($icon) = @_;

    return 0 unless $icon;

    return 1 if -e "root/$icon";

    my ($feature_path) = $icon =~ m{^(.*)/};
    return 1 if -e "$ENV{CLARIVE_BASE}/features/$feature_path/root/$icon";

    return 0;
};


sub downgrade {
}

1;
