package Baseliner::CI;
use strict;
use Baseliner::Utils;
use Try::Tiny;

our $_no_record = 1;
our $no_throw_on_search = 1;

our $scope = {};


=head2 new

The new instanciates a CI or throws an error otherwise. 

    ci->new( 1212 ); # mid
    ci->new({ ci_class=>'BaselinerX::CI::whatever', ... }); # record
    ci->new( ns=>'domain/id' );   # new from ns
    ci->new( moniker=>'monkey' );   # new from moniker
    ci->generic_server->new( name=>'Local', hostname=>'localhost' );   # new for class BaselinerX::CI::generic_server

=cut

sub new {
    my $class = shift;
    my %args;
    if( @_ == 0 ) {
        _throw "Missing CI mid";
    } elsif( @_ == 1 && ref $_[0] eq 'HASH' ) {
        # ci record
        my $rec = $_[0];
        return Baseliner::Role::CI->_build_ci_instance_from_rec( $rec );
    } elsif( @_ == 1 && ( is_number( $_[0] ) || $_[0] !~ /^(name|moniker):/ ) ) {
        # mid, number or any string that does not start with "name:xxxx", "moniker:xxxx"
        my $mid = $_[0];
        my $rec = Baseliner::Role::CI->load( $mid );
        _throw _loc('CI record not found for mid %1', $mid) unless ref $rec;
        return Baseliner::Role::CI->_build_ci_instance_from_rec( $rec );
    } elsif( @_ == 1 && ref( $_[0] ) =~ /^Baseliner.?::CI/ && $_[0]->does('Baseliner::Role::CI') ) {
        # already a full grown CI
        return $_[0]->can('mid') ? $class->new( $_[0]->mid ) : $_[0];  # renew if it has mid, otherwise just keep it as-is (it's a handmade CI)
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
        # several CIs at once  TODO optimize loading in load for array, using a mdb->master->find
        my @mids = Util->_array($_[0]);
        return map { ci->new($_) } @mids;
    } else {
        # search %hash 
        %args = @_;
        my $rec = try { Baseliner::Role::CI->load_from_search( \%args, single=>1 ) };
        _throw _loc('CI record not found for search %1', _to_json(\%args) ) if !ref $rec && !$Baseliner::CI::no_throw_on_search;
        return undef if !ref $rec;
        return Baseliner::Role::CI->_build_ci_instance_from_rec( $rec );
    }
}

=head2 find

Instanciates a CI or returns undef. If it errors, 
a message is printed out to STDERR, but no throwing. 

    ci->find( ... )

=cut
sub find {
    my ($class,@args)=@_;
    return try {
        ci->new( @args );
    } catch {
        Util->_error( shift );
        undef;   
    };
}

sub is_ci {
    my ($class,$obj) = @_;
    ref($obj) =~ /^BaselinerX::CI::/;
}

1;

