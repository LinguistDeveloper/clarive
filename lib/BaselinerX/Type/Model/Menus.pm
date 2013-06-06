package BaselinerX::Type::Model::Menus;
use strict;
use base qw/Catalyst::Model/;
use Baseliner::Utils;

sub menus {
    my ( $self, %p ) = @_;
    my @menus;

    # foreach allowed menu
    foreach (
        sort { $a->index <=> $b->index } Baseliner->model( 'Registry' )->search_for(
            key             => 'menu.',
            allowed_actions => $p{allowed_actions},
            depth           => 1,
            check_enabled   => 1,
            username        => $p{username},
        )
        )
    {
        my $item = $_->ext_menu_json( username => $p{username}, top_level => 1 );
        next unless $item;    # discard items without children at top menu level
        push @menus, $item;
    } ## end foreach ( sort { $a->index ...})
    return \@menus;
} ## end sub menus

1;
