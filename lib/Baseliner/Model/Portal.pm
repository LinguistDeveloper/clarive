package Baseliner::Model::Portal;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Model' }

sub list_portlets {
    my $self     = shift;
    my %p = @_ ;
    
    my (@portlets, @actions);
    if ( $p{username} ) {

    }
    else {
        @portlets = Baseliner->model('Registry')->search_for( key => 'portlet.', allowed_actions => [@actions] );
        @portlets = grep { $_->active } @portlets if $p{active};
    }
    return wantarray ? @portlets : \@portlets;
}

1;
