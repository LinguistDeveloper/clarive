package BaselinerX::CI::itemset;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Group';

sub icon { '/static/images/icons/ci-green.svg' }

sub ci_form { '/ci/itemset.js' }

has_cis items => 'Baseliner::Role::CI::Item';    #qw(is rw isa ArrayRef[Baseliner::Role::CI::Item]);

sub rel_type {
    { items => [ from_mid => 'itemset_item' ] };
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my $name   = $AUTOLOAD;
    my @a      = reverse( split( /::/, $name ) );
    my $method = $a[0];
    my @results;
    for my $chi ( @{ $self->items || [] } ) {
        push @results, $chi->$method(@_);
    }
    return @results;
}

1;
