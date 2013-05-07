package Baseliner::CI;
use strict;
use Baseliner::Utils;
use Module::Loaded;

our $_no_record = 0;
our $scope = {};
our $mid_scope;

sub new {
    my $class = shift;
    my %args;
    if( @_ == 0 ) {
        _throw "Missing node URI";
    } elsif( @_ == 1 && ref $_[0] eq 'HASH' ) {
        %args = %{ $_[0] };
    } elsif( @_ == 1 && is_number( $_[0] ) ) {   # mid! a CI!
        local $Baseliner::CI::mid_scope = {} unless defined $Baseliner::CI::mid_scope;
        my $rec = Baseliner::Role::CI->load( $_[0] );
        my $ci_class = $rec->{ci_class}; 
        # instantiate
        my $obj = $ci_class->new( $rec );
        # add the original record to _ci
        unless( $Baseliner::CI::_no_record ) {
            delete $rec->{yaml}; # lots of useless data
            $obj->{_ci} = $rec; 
            $obj->{_ci}{ci_icon} = $obj->icon;
        }

        return $obj;
    } elsif( @_ == 1 && ref( $_[0] ) =~ /^Baseliner.?::CI/ && $_[0]->does('Baseliner::Role::CI') ) {
        return $_[0];
    } elsif( @_ == 1 && ! ref $_[0] ) {
        $args{uri} = $_[0];
    } elsif( @_ == 2 && ! ref $_[0] && ref $_[1] eq 'HASH' ) {
        %args = %{ $_[1] };
        $args{uri} = $_[0];
    } else {
        %args = @_;
    }
    if( $args{uri} && ! exists $args{resource} ) {
        require Baseliner::URI;
        $args{resource} = Baseliner::URI->new( $args{uri} );
    }
    ref $args{resource} or _throw "Missing or invalid resource";
    # merge resource params ?k=v&... into args
    %args = ( 
        %args,
        %{ $args{resource}{params} },
    );
    # load agent class
    my $agent_class =  "Baseliner::CI::" . $args{resource}->agent;
    unless ( is_loaded $agent_class ) {
        eval "require $agent_class"; 
        _throw _loc "Error loading node class %1: %2", $agent_class, $@ if $@;
    }
    # instantiate agent
    $agent_class->new( %args );
}

1;

