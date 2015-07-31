package Baseliner::Model::Activity;
use Moose;
use Try::Tiny;
use Baseliner::Core::Registry;
use Baseliner::Utils qw(_loc _error);
use Clarive::cache;
use Clarive::mdb;

sub find {
    my $self = shift;
    my ( $mid, %p ) = @_;

    my $cache_key = { mid => "$mid", d => 'activities', opts => \%p };    # [ "activities:$mid:", \%p ];

    my $cached = cache->get($cache_key);
    return $cached if $cached;

    my $purged = $self->find_not_cached(@_);

    cache->set( $cache_key, $purged );

    return $purged;
}

sub find_not_cached {
    my $self = shift;
    my ( $mid, %p ) = @_;

    my $min_level = $p{min_level} // 0;

    my @acts = mdb->activity->find( { mid => "$mid" } )->sort( { ts => -1 } )->all;

    my @filtered_acts = grep { $_->{ev_level} == 0 || $_->{level} >= $min_level } @acts;

    my @elems;
    foreach my $act (@filtered_acts) {
        my $ev = Baseliner::Core::Registry->get( $act->{event_key} );

        if ( !$ev || !%$ev ) {
            _error( _loc('Error in event text generator: event not found') );
            next;
        }

        my %res = map { $_ => $act->{vars}->{$_} } @{$ev->vars};

        $res{ts}       = $act->{ts};
        $res{username} = $act->{username};

        my %merged = ( %$act, %{ $act->{vars} || {} } );
        $res{text} = $ev->event_text( \%merged );

        push @elems, \%res;
    }

    return \@elems;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
