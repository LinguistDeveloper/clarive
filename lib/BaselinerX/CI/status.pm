package BaselinerX::CI::status;
use Baseliner::Moose;
use Baseliner::Utils;
use Try::Tiny;
with 'Baseliner::Role::CI::Internal';

# - bind_releases: '0'
#   bl: '*'
#   ci_update: '0'
#   description: ~
#   frozen: '0'
#   id: '94'
#   name: Parametrización
#   readonly: '0'
#   seq: ~
#   type: G

has_cis "bls";
has id_status     => qw(is rw isa Any);
has bind_releases => qw(is rw isa Any);
has ci_update     => qw(is rw isa Any);
has frozen        => qw(is rw isa Any);
has readonly      => qw(is rw isa Any);
has seq           => qw(is rw isa Any);
has type          => qw(is rw isa Any);

sub icon { '/static/images/icons/baseline.gif' }
sub collection { 'status' }
sub rel_type {
    { 
        bls   => [ from_mid => 'status_bl' ]
    };
}

before save_data => sub {
    my ($self, $master_row, $data ) = @_;

    _log _dump $data;
    my @bls = _array $data->{bls};

    my $bl = $bls[0]->{moniker};


    my $r = {
        name          => $data->{name},
        description   => $data->{description},
        bind_releases => $data->{bind_releases} eq 'on' ? '1' : '0',
        ci_update     => $data->{ci_update} eq 'on' ? '1' : '0',
        readonly      => $data->{readonly} eq 'on' ? '1' : '0',
        frozen        => $data->{frozen} eq 'on' ? '1' : '0',
        seq           => $data->{seq},
        type          => $data->{type},
        bl            => $bl
    };
    my $row;
    if( $row = DB->BaliTopicStatus->find( $self->id_status ) || DB->BaliTopicStatus->search({ name=>$r->{name} })->first ) {
        $row->update($r);
    } else {
        $row = DB->BaliTopicStatus->create($r);
    }
    $self->moniker( uc($self->name) );
    $self->id_status( $row->id );  
};
    
after delete => sub {
    my ($self, $mid ) = @_;
    Baseliner::Core::Registry->reload_all;
    if( my $row = DB->BaliTopicStatus->find( $self->id_status ) ) {
        $row->delete;
    }
};

sub combo_list {
    my ($self) = @_;
    {
        data => [
            map { +{ id_status => $_->id_status, name => $_->name } } 
            sort { lc $a->name cmp lc $b->name } 
            $self->search_cis
        ]
    };
}

1;
