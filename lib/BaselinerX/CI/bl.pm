package BaselinerX::CI::bl;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging);
use Try::Tiny;
with 'Baseliner::Role::CI::Internal';

has bl          => qw(is rw isa Any default *);
has seq         => qw(is rw isa Any default 100);

sub icon { '/static/images/icons/baseline.gif' }
sub collection { 'bl' }
sub has_bl { 0 }

before save => sub {
    my ($self, $master_row, $data ) = @_;
    $self->moniker( $self->bl );
};
    
1;
