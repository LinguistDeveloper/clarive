package Baseliner::Model::Relationships;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

*set = \&add;

sub add {
    my $self = shift;
    if( @_> 1 && $_[0] eq 'from' ) {
        my %p = @_;
        if( ref $p{to} eq 'ARRAY' ) {
            $self->add_one( from=>$p{from}, to=>$_, type=>$p{type} )
                for _array $p{to};
        } else {
            $self->add_one( @_ );
        }
    } else {
        # bulk mode
        $self->add_one( %$_ ) for @_;
    }
}

sub add_one {
    my ($self, %p ) = @_;
    $p{from} or _throw "Missing 'from' parameter";
    $p{to} or _throw "Missing 'to' parameter";
    Baseliner->model('Baseliner::BaliRelationship')->find_or_create({
        from_ns => $p{from},
        to_ns => $p{to},
        type => $p{type},
    });
}

sub all {
    my ($self, %p ) = @_;
    my $rs = Baseliner->model('Baseliner::BaliRelationship')->search( \%p );
    rs_hashref($rs);
    return $rs->all;
}

sub get {
    my $self = shift;
    #$p{from} or $p{to} or _throw "Missing 'from' or 'to' parameter";
    my $where = {};
    if( @_> 1 && ( $_[0] eq 'from' || $_[0] eq 'to' ) ) {
        my %p = @_;
        defined $p{from} and $where->{from_ns} = $p{from};
        defined $p{to} and $where->{to_ns} = $p{to};
        defined $p{type} and $where->{type} = $p{type};
    } else {
        $where->{'-or'} = {
            from_ns => \@_,
            to_ns   => \@_
        };
    }
    my $rs = Baseliner->model( 'Baseliner::BaliRelationship' )->search( $where );
    rs_hashref( $rs );
    return wantarray
        ? $rs->all
        : $rs;
}

sub get_to {
    my $self = shift;
    my $rs = $self->get( @_ );
    if( my $r = $rs->first ) {
        return $r->{to_ns};
    }
    return undef;
}

sub get_from {
    my $self = shift;
    my $rs = $self->get( @_ );
    if( my $r = $rs->first ) {
        return $r->{from_ns};
    }
    return undef;
}

sub delete {
    my $self = shift;
    my $where = {};
    if( @_> 1 && ( $_[0] eq 'from' || $_[0] eq 'to' ) ) {
        my %p = @_;
        defined $p{from} and $where->{from_ns} = $p{from};
        defined $p{to} and $where->{to_ns} = $p{to};
        defined $p{type} and $where->{type} = $p{type};
    }
    elsif( @_ > 0  ) {
        $where->{'-or'} = {
            from_ns => \@_,
            to_ns   => \@_
        };
    }
    my $rs = Baseliner->model('Baseliner::BaliRelationship')->search($where);
    while( my $r = $rs->next ) { $r->delete }
}

=head1 NAME

Baseliner::Model::Relationships

=head1 SYNOPSIS

    Baseliner->model('Relationships')->set( from=>'user/100', to=>'file/22' );
    
    # or with Baseliner::Sugar

    relation->set( ... );
    relation->get( ... );
    my @all = relation->all;

=head1 DESCRIPTION

A generic store for keeping relationships in between namespaces. 

=head1 METHODS

=head2 set

The same as C<add>

=head2 add

Adds a relationship, if it doesn't exist already.

    relation->add( from=>'user/1', to=>'file/2' );
    
    # or in bulk mode

    relation->add(
        { from=>'user/1', to=>'file/1' },
        { from=>'user/1', to=>'file/2' },
        { from=>'user/1', to=>'file/3' },
    );

    relation->add( 
        from=>'user/1', 
        to => [
            'file/1', 'file/2', 'file/3'
        ]
    );

    # give it a type, for better control 

    relation->add( from=>'file/1', to=>'user/1',
        type=>'file_to_user' );

=head2 get

Retrieves a relationship.

Returns: ARRAY of hashes, or a ResultSet of hashes.

    use Baseliner::Sugar;

    my @rels = relation->get( from=>'user/23' );
    say $rels[0]->{from_ns};
    
    my $rs = relation->get( from=>'user/23' );
    while( my $r = $rs->next ) {
        say $r->{from_ns} . ' ---> ' . $r->{to_ns};
    }

You can also use the bulk mode, which checks for both C<from> and C<to> sides 
of a relationship:

    # bulk get
    my $rs = relation->get( 'user/23', 'file/333' );
    while( my $r = $rs->next ) {  ... }

=head2 get_to 

Retrieves the first C<to_ns> field of a relationship.

    my $to_ns = relation->get( from=>'file/123' );  # $to_ns is user/1

    my $to_ns = relation->get( from=>'file/123', type=>'file_for_user' );  # more specific

=cut
1;
