package BaselinerX::CI::itemset;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Group';
sub icon       { '/static/images/icons/ci.png' }

has_cis children => 'ArrayRef[Baseliner::Role::CI::Item]'; #qw(is rw isa ArrayRef[Baseliner::Role::CI::Item]);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p = @_;
    $self->$orig( %p );
};

1;
