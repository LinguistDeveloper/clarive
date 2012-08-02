package Baseliner::Role::ReleaseContent;
use Moose::Role;

=head2 release_items

Returns the releases to there an item may belong to.

=cut
sub release_items {
    my ($self, %p ) = @_;
    my @releases;

    my $where = { ns=> $self->ns };

    my $rs_rel = Baseliner->model('Baseliner::BaliReleaseItems')->search($where,{ prefetch=>'id_rel' });
    $rs_rel->result_class('DBIx::Class::ResultClass::HashRefInflator');

    while( my $r = $rs_rel->next ) {
        try {
            for my $release ( _array $r->{id_rel} ) {
                push @releases, $release;
            }
        };
    }
    return @releases;
}

1;


