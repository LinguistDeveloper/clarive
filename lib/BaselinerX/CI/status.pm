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
has status_icon    => qw(is rw isa Str), default=>'';
has max_inactivity_time => => qw(is rw isa Str), default=>'0';
has max_time_in_status => => qw(is rw isa Str), default=>'0';
has view_in_tree  => qw(is rw isa BoolCheckbox);

sub icon { '/static/images/icons/status.png' }
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
    
after save_data => sub {
    my ($self, $master_row, $data, $opts, $old ) = @_;
    # update statuses in topics
    if( $$opts{changed}{name} && defined $$old{name} ) {
        my $ret = mdb->topic->update(
            { 'category_status.id'=>mdb->in($self->mid) },
            { '$set'=>{ 'category_status.name'=>$self->name, name_status=>$self->name } },
            { multiple => 1 });
    }
};

after delete => sub {
    my ($self, $mid ) = @_;
    my @cats = mdb->category->find({statuses => mdb->in($self->{id_status})})->all;
    foreach my $cat (@cats){
        my $index = 0;
        my @arr = _array $cat->{statuses};
        foreach my $elem (_array $cat->{statuses}){
            last if ($elem eq $self->{id_status});
            $index++;
        }    
        delete $arr[$index];
        mdb->category->update({_id => $cat->{_id}}, {'$set' => {statuses => \@arr}});
    }
    Baseliner::Core::Registry->reload_all;
};

sub combo_list {
    my ($self, $p) = @_;
_warn $p;
    my $where = {};

    if ( $p->{category} ) {
        my $category = mdb->category->find_one({ name => $p->{category} });
        my @statuses_in_category = _array($category->{statuses}) if $category;
        $where->{id_status} = mdb->in(@statuses_in_category) if @statuses_in_category;
    }
    {
        data => [
            map { +{ id_status => $_->id_status, name => $_->name } } 
            sort { lc $a->name cmp lc $b->name } 
            $self->search_cis(%$where)
        ]
    };
}

sub name_with_bl {
    my ($self, %p) = @_;
    my $bl = $self->bls->[0] if Util->_array($self->bls);
    return $self->name if $p{no_common} && $bl->moniker eq '*';
    length $bl 
        ? sprintf( '%s (%s)', $self->name, ($bl->moniker || $bl->name) )
        : $self->name; 
}

=head2 names_with_bl

Returns:
     
     ThisStateName (BL1)
     ThisStateName (BL2)

=cut
sub names_with_bl {
    my ($self) = @_;
    my @bls = map { $_->moniker || $_->name } Util->_array( $self->bls );
    return @bls 
        ? ( map { sprintf( '%s (%s)', $self->name,$_ ) } @bls )
        : ( $self->name );
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
    my %statuses = map { $$_{id_status} => $_ } grep { length $$_{id_status} } $self->find(\%p)->fields({ _id=>0, yaml=>0 })->all;
    return %statuses;
}

1;
