package BaselinerX::Type::Model::Menus;
use strict;
use base qw/Catalyst::Model/;
use Baseliner::Utils;

sub menus {
    my ( $self, %p ) = @_;
    my @menus;
    foreach (
        sort { $a->index <=> $b->index }
        Baseliner->model('Registry')->search_for(
            key             => 'menu.',
            allowed_actions => $p{allowed_actions},
            depth           => 1,
            check_enabled   => 1
        )
      )
    {
        my $item =  $_->ext_menu_json( top_level=>1 );
        next unless $item;  # discard items without children at top menu level
        push @menus, $item;
    }
    return \@menus;
}

1;
