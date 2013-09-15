package Baseliner::CI;
use strict;
use Baseliner::Utils;
use Module::Loaded;

our $_no_record = 0;
our $scope = {};

=head2

    Baseliner::CI->new( 1212 ); # mid
    Baseliner::CI->new({ ci_class=>'BaselinerX::CI::whatever', ... }); # record
    Baseliner::CI->new( ns=>'domain/id' );   # new from ns
    Baseliner::CI->new( moniker=>'monkey' );   # new from moniker

=cut

sub new {
    my $class = shift;
    my %args;
    if( @_ == 0 ) {
        _throw "Missing CI mid";
    } elsif( @_ == 1 && ref $_[0] eq 'HASH' ) {
        # ci record
        my $rec = $_[0];
        return $class->_build_ci_instance_from_rec( $rec );
    } elsif( @_ == 1 && is_number( $_[0] ) ) {
        # mid
        my $mid = $_[0];
        my $rec = Baseliner::Role::CI->load( $mid );
        _throw _loc('CI record not found for mid %1', $mid) unless ref $rec;
        return $class->_build_ci_instance_from_rec( $rec );
    } elsif( @_ == 1 && ref( $_[0] ) =~ /^Baseliner.?::CI/ && $_[0]->does('Baseliner::Role::CI') ) {
        # already a full grown CI
        return $_[0];
    } elsif( @_ == 1 && ! ref $_[0] ) {
        # NOP: could be moniker?
        _throw _loc("Could not instanciate CI from parameter %1", $_[0] );
    } else {
        %args = @_;
        my $rec = Baseliner::Role::CI->load_from_search( \%args, single=>1 );
        _throw _loc('CI record not found for search %1', _to_json(\%args) ) unless ref $rec;
        return $class->_build_ci_instance_from_rec( $rec );
    }
}

sub _build_ci_instance_from_rec {
    my ($class,$rec) = @_;
    local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;
    if( $Baseliner::CI::_record_only ) {
        delete $rec->{yaml};
        return $rec;
    }
    my $ci_class = $rec->{ci_class}; 
    # instantiate
    my $obj = $ci_class->new( $rec );
    # add the original record to _ci
    if( $Baseliner::CI::_no_record ) {
        delete $rec->{yaml}; # lots of useless data
    } else {
        delete $rec->{yaml}; # lots of useless data
        $obj->{_ci} = $rec; 
        $obj->{_ci}{ci_icon} = $obj->icon;
    }
    if( $Baseliner::CI::_merge_record ) {
        my $_ci = delete $obj->{_ci};
        if( ref $_ci eq 'HASH' ) { 
            $obj->{$_} //= $_ci->{$_} for keys %$_ci;
        }
    }

    return $obj;
}

1;

