package BaselinerX::CI::bl;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging);
use Try::Tiny;
with 'Baseliner::Role::CI::Internal';

has bl          => qw(is rw isa Any default *);
has seq         => qw(is rw isa Any default 100);
has id_bl       => qw(is rw isa Any);

sub icon { '/static/images/icons/baseline.gif' }
sub collection { 'bl' }
sub has_bl { 0 }

before save => sub {
    my ($self, $master_row, $data ) = @_;
    my $r = {
        bl          => $self->bl,
        name        => $self->name,
        description => $self->description,
        seq         => $self->seq,
    };
    my $row;
    if( $row = DB->BaliBaseline->find( $self->id_bl ) || DB->BaliBaseline->search({ bl=>$r->{bl} })->first ) {
        $row->update($r);
    } else {
        $row = DB->BaliBaseline->create($r);
    }
    $self->moniker( $self->bl );
    $self->id_bl( $row->id );  
};
    
after delete => sub {
    my ($self, $mid ) = @_;
    if( my $row = DB->BaliBaseline->find( $self->id_bl ) ) {
        $row->delete;
    }
};

1;
