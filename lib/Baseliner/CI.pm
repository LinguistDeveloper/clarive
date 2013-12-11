package Baseliner::CI;
use strict;
use Baseliner::Utils;
use Try::Tiny;

our $_no_record = 1;
our $no_throw_on_search = 1;

our $scope = {};


=head2

    Baseliner::CI->new( 1212 ); # mid
    Baseliner::CI->new({ ci_class=>'BaselinerX::CI::whatever', ... }); # record
    Baseliner::CI->new( ns=>'domain/id' );   # new from ns
    Baseliner::CI->new( moniker=>'monkey' );   # new from moniker

=cut

sub find {
    my $class = shift;
    my %args;
    if( @_ == 0 ) {
        _throw "Missing CI mid";
    } elsif( @_ == 1 && ref $_[0] eq 'HASH' ) {
        # ci record
        my $rec = $_[0];
        return Baseliner::Role::CI->_build_ci_instance_from_rec( $rec );
    } elsif( @_ == 1 && is_number( $_[0] ) ) {
        # mid
        my $mid = $_[0];
        my $rec = Baseliner::Role::CI->load( $mid );
        _throw _loc('CI record not found for mid %1', $mid) unless ref $rec;
        return Baseliner::Role::CI->_build_ci_instance_from_rec( $rec );
    } elsif( @_ == 1 && ref( $_[0] ) =~ /^Baseliner.?::CI/ && $_[0]->does('Baseliner::Role::CI') ) {
        # already a full grown CI
        return $_[0];
    } elsif( @_ == 1 && $_[0] =~ /^(\w+):(.+)/ ) {
        # name, moniker, etc.
        my ($parm,$val) = ($1,$2);
        my $rec = try { Baseliner::Role::CI->load_from_search({ $parm=>$val }, single=>1 ) };
        _throw _loc('CI record not found for search %1', _to_json(\%args) ) if !ref $rec && !$Baseliner::CI::no_throw_on_search;
        return undef if !ref $rec;
        return Baseliner::Role::CI->_build_ci_instance_from_rec( $rec );
    } elsif( @_ == 1 && ! ref $_[0] ) {
        # NOP: could be moniker?
        _throw _loc("Could not instanciate CI from parameter %1", $_[0] );
    } elsif( @_ == 1 && ref $_[0] eq 'ARRAY' ) {
        # several CIs at once  TODO optimize loading in load for array, using a BaliMaster->search
        my $mids = $_[0];
        # master data
        my @rows = DB->BaliMaster->search({ mid=>$mids })->hashref->all;
        my %mids_found = map { $_->{mid} =>$_ } @rows;
        # check mids were found
        for( @$mids ) {
            _throw _loc('CI record not found for mid %1', $_) unless exists $mids_found{$_};
        }
        # rel data
        my @rel_rows = DB->BaliMasterRel->search( 
            { -or=>[ to_mid=>$mids, from_mid=>$mids ]},
            { select=> ['from_mid', 'to_mid', 'rel_type' ] } )->hashref->all;
        my %rel_data;
        for my $rel_row ( @rel_rows ) { 
            push @{ $rel_data{ $rel_row->{mid} } }, $rel_row;
        }
        # now inflate, making sure order is the same as in the original array
        my @cis;
        for my $mid ( keys %mids_found ) {
            my $rec = Baseliner::Role::CI->load( $mid, undef, $mids_found{$mid}, undef, \%rel_data );
            push @cis, Baseliner::Role::CI->_build_ci_instance_from_rec( $rec );
        }
        return @cis;
    } else {
        # search %hash 
        %args = @_;
        my $rec = try { Baseliner::Role::CI->load_from_search( \%args, single=>1 ) };
        _throw _loc('CI record not found for search %1', _to_json(\%args) ) if !ref $rec && !$Baseliner::CI::no_throw_on_search;
        return undef if !ref $rec;
        return Baseliner::Role::CI->_build_ci_instance_from_rec( $rec );
    }
}

*new = \&find;

1;

