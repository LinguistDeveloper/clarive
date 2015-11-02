package Baseliner::CI;
use strict;
use Baseliner::Utils;
use Try::Tiny;

our $_no_record = 1;
our $no_throw_on_search = 1;

our $scope = {};

our $password_hide_str = 'clarive_hidden_pass: ' . ('*' x 30);

use Moose::Util::TypeConstraints;
use Baseliner::Role::CI;
subtype CI    => as 'Baseliner::Role::CI';
subtype CIs   => as 'ArrayRef[CI]';
subtype BoolCheckbox   => as 'Bool';
subtype Date  => as 'Class::Date';
subtype HashJSON       => as 'HashRef';
subtype TS    => as 'Str';
subtype DT    => as 'DateTime';
subtype BL    => as 'Maybe[Str]';
    
coerce 'Date' => 
    from 'Str' => via { Class::Date->new( $_ ) },
    from 'Num' => via { Class::Date->new( $_ ) },
    from 'Undef' => via { Class::Date->now };
    
coerce 'BL' => 
    from 'ArrayRef' => via { join ',', @$_ },
    from 'Undef' => via { '*' };

coerce 'TS' => 
    from 'DT' => via { Class::Date->new( $_->set_time_zone( Util->_tz ) )->string },
    from 'Class::Date' => via { $_->string },
    from 'Num' => via { Class::Date->new( $_ )->string },
    from 'Undef' => via { Class::Date->now->string },
    from 'Any' => via { Class::Date->now->string };

coerce 'BoolCheckbox' =>
  from 'Str' => via { $_ eq 'on' ? 1 : 0 };

coerce 'HashJSON' =>
  from 'Str' => via { Util->_from_json($_) },
  from 'Undef' => via { +{} };

# deprecated, but kept for future reference
coerce 'CI' =>
  from 'Str' => via { length $_ ? Baseliner::CI->new( $_ ) : BaselinerX::CI::Empty->new()  }, 
  from 'Num' => via { Baseliner::CI->new( $_ ) }, 
  from 'ArrayRef' => via { my $first = [_array( $_ )]->[0]; defined $first ? Baseliner::CI->new( $first ) : BaselinerX::CI::Empty->new() }; 

coerce 'CIs' => 
  from 'Str' => via { length $_ ? [ Baseliner::CI->new( $_ ) ] : [ BaselinerX::CI::Empty->new() ]  }, 
  from 'ArrayRef[Num]' => via { my $v = $_; [ map { Baseliner::CI->new( $_ ) } _array( $v ) ] },
  from 'Num' => via { [ Baseliner::CI->new( $_ ) ] }; 

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
    require Baseliner::Role::CI; 
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
        my $err = shift;
        Util->_error( $err );
        Util->_error( Util->_whereami );
        undef;   
    };
}

sub is_ci {
    my ($class,$obj) = @_;
    ref($obj) =~ /^BaselinerX::CI::/;
}

1;

# Attribute Trait 
package Baseliner::Role::CI::TraitCI;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Scalar::Util; # 'looks_like_number', 'weaken';

Moose::Util::meta_attribute_alias('CI');

our $gscope;

my $init = sub {
    my ($val) = @_;
    my $obj = $gscope->{$val} if ref $gscope;
    if( defined $obj ) {
        $_[1] = 1;
        return $obj;
    } else {
        $_[1] = 0;
        return ci->new( $val );
    }
};

my $ci_coerce = sub {
    my ($tc,$val,$params,$init_arg,$weaken) = @_;
    
    local $SIG{__DIE__} = undef; # avoid Moose::Util "isa" errors popping up

    # needs coersion?
    if( ! $tc->check( $val ) ) {
        # CIs
        if( $tc->is_a_type_of('ArrayRef') ) {
            match_on_type $val => (
                'Undef' => sub {
                    $params->{$init_arg} = [ BaselinerX::CI::Empty->new ];
                },
                'Object' => sub {
                    $params->{$init_arg} = [ $val ];
                },
                'Num|Str' => sub {
                    if( length $val ) {
                        $params->{$init_arg} = [ map { $init->( $_, $weaken ) } split /,/, $val ];
                        Scalar::Util::weaken( $params->{$init_arg}->[0] ) if $weaken;
                        $weaken = 0;
                    } else {
                        $params->{$init_arg} = [ BaselinerX::CI::Empty->new ];
                    }
                },
                'ArrayRef[Str]' => sub {
                    my $arr = [];
                    my $i = 0;
                    for( @$val ) {
                        if( defined $_ && length $_ ) {
                            $arr->[ $i ] = $init->( $_, $weaken );
                            Scalar::Util::weaken( $arr->[$i] ) if $weaken;
                        } else {
                            $arr->[ $i ] = BaselinerX::CI::Empty->new;
                        }
                        $i++;
                    }
                    $params->{$init_arg} = $arr;
                    $weaken = 0;
                },
                # => sub { _fail 'not found...' } 
            );
        }
        # CI
        else {
            match_on_type $val => (
                'Undef' => sub {
                    $params->{$init_arg} = BaselinerX::CI::Empty->new;
                },
                'Object' => sub {
                    $params->{$init_arg} = $val;
                },
                'Num|Str' => sub {
                    if( length $val ) {
                        $params->{$init_arg} = $init->( $val, $weaken );
                    } else {
                        $params->{$init_arg} = BaselinerX::CI::Empty->new;
                    }
                },
                'ArrayRef[Str]' => sub {
                    if( length $val->[0] ) {
                        $params->{$init_arg} = $init->( $val->[0], $weaken );
                    } else {
                        $params->{$init_arg} = BaselinerX::CI::Empty->new;
                    }
                },
                'ArrayRef[CI]' => sub {
                    $params->{$init_arg} = $init->( $val->[0], $weaken );
                    Scalar::Util::weaken( $params->{$init_arg}->[0] ) if $weaken;
                    $weaken = 0;
                },
            );
        }
    }
}; 
around initialize_instance_slot => sub {
    my ($orig, $self) = (shift,shift);   # $self isa Moose::Meta::Attribute
    my ($meta_instance, $instance, $params) = @_;
    
    my $init_arg = $self->init_arg();
    $gscope or local $gscope = {};
    my $mid = $instance->mid // $params->{mid};
    my $weaken = 0;
    if( defined($init_arg) and exists $params->{$init_arg} ) {
        $gscope->{ $mid } //= $instance if defined $mid;  # this is the scope, so that we cache while loading and avoid deep recursion errors
        my $val = $params->{$init_arg};
        my $tc = $self->type_constraint;

        if( !exists $instance->meta->{_ci_around_modifiers}{$init_arg} ) {  # make sure defined only once for each object
            Moose::Util::add_method_modifier( $instance->meta, 'around', [ $init_arg => sub{  
                my $orig = shift;
                my $self = shift;
                my @vals = @_;
                if( @vals ) {
                    my $p2 = { $init_arg =>( @vals>1 ? \@vals : $vals[0] ) };
                    $ci_coerce->($tc, $p2->{$init_arg},$p2,$init_arg,0);
                    return $self->$orig( $p2->{$init_arg} ); 
                } else {
                    return $self->$orig(@vals);
                }
            }]);
            $instance->meta->{_ci_around_modifiers}{$init_arg} = 1;
        }
        
        $ci_coerce->($tc,$val,$params,$init_arg,$weaken);
        
    }
    $self->$orig( @_ );
    $self->_weaken_value($instance) if $weaken;
};

# CIs
package Baseliner::Role::CI::TraitCIs;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Scalar::Util; # 'looks_like_number', 'weaken';

with 'Baseliner::Role::CI::TraitCI';

Moose::Util::meta_attribute_alias('CIs');

1;
