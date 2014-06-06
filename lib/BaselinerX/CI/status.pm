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
has bind_releases => qw(is rw isa Any), default=>'0';
has ci_update     => qw(is rw isa Any), default=>'0';
has frozen        => qw(is rw isa Any), default=>'0';
has readonly      => qw(is rw isa Any), default=>'0';
has seq           => qw(is rw isa Any);
has type          => qw(is rw isa Any), default=>'G';
has color         => qw(is rw isa Any);

sub icon { '/static/images/icons/baseline.gif' }
sub collection { 'status' }
sub rel_type {
    { 
        bls   => [ from_mid => 'status_bl' ]
    };
}

before save_data => sub {
    my ($self, $master_row, $data ) = @_;
    if( !length $$data{id_status} ) {
        # new save, use mid as id_status
        $$data{id_status} = $$data{mid};
        $self->id_status( $$data{id_status} );
    }
    if( !length $$data{moniker} ) {
        $$data{moniker} = uc $self->name;
        $self->moniker( $$data{moniker} );
    }
};
    
after delete => sub {
    my ($self, $mid ) = @_;
    Baseliner::Core::Registry->reload_all;
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

sub name_with_bl {
    my ($self) = @_;
    sprintf '%s (%s)', $self->name, $self->bl;
}

sub statuses {
    my ($self, %p ) = @_;
    
    if( my $id_cat = delete $p{id_category} ) {
        my $cat = mdb->category->find_one({ id=>mdb->in($id_cat) },{ statuses=>1 });
        return () unless $cat;
        my $in = mdb->in($$cat{statuses});
        if( $p{id_status} ) {
            $p{'$and'} = [{id_status=>$p{id_status}},{id_status=>$in}]
        } else {
            $p{id_status} = $in;
        }
    }
    my %statuses = map { $$_{id_status} => $_ } $self->find(\%p)->fields({ _id=>0, yaml=>0 })->all;
    return %statuses;
}

1;
