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

after save => sub {
    my ($self, $master_row, $data ) = @_;

    _log _dump @_;
    my @bls = _array $self->{bls};

    my $bl = $bls[0]->{moniker};


    my $r = {
        name          => $self->{name},
        description   => $self->{description},
        bind_releases => $self->{bind_releases} eq 'on' ? '1' : '0',
        ci_update     => $self->{ci_update} eq 'on' ? '1' : '0',
        readonly      => $self->{readonly} eq 'on' ? '1' : '0',
        frozen        => $self->{frozen} eq 'on' ? '1' : '0',
        seq           => $self->{seq},
        type          => $self->{type},
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
    my ($self)=@_;
    { data=>[ map { +{ id_status=> $_->id_status, name=>$_->name } } sort { $a->name <=> $b->name } $self->search_cis ] };
}

1;
