package Baseliner::Role::CI;
use Moose::Role;

use Moose::Util::TypeConstraints;
require Baseliner::CI;

subtype CI    => as 'Baseliner::Role::CI';
subtype CIs   => as 'ArrayRef[CI]';
subtype BoolCheckbox   => as 'Bool';

# deprecated, but kept for future reference
#coerce 'CI' =>
#  from 'Str' => via { length $_ ? Baseliner::CI->new( $_ ) : BaselinerX::CI::Empty->new()  }, 
#  from 'Num' => via { Baseliner::CI->new( $_ ) }, 
#  from 'ArrayRef' => via { my $first = [_array( $_ )]->[0]; defined $first ? Baseliner::CI->new( $first ) : BaselinerX::CI::Empty->new() }; 
#
#coerce 'CIs' => 
#  from 'Str' => via { length $_ ? [ Baseliner::CI->new( $_ ) ] : [ BaselinerX::CI::Empty->new() ]  }, 
#  from 'ArrayRef[Num]' => via { my $v = $_; [ map { Baseliner::CI->new( $_ ) } _array( $v ) ] },
#  from 'Num' => via { [ Baseliner::CI->new( $_ ) ] }; 

coerce 'BoolCheckbox' =>
  from 'Str' => via { $_ eq 'on' ? 1 : 0 };

has mid      => qw(is rw isa Num);
#has ci_class => qw(is rw isa Maybe[Str]);
#has _ci      => qw(is rw isa Any);          # the original DB record returned by load() XXX conflicts with Utils::_ci

requires 'icon';
#requires 'collection';

has name    => qw(is rw isa Maybe[Str]);
has job     => qw(is rw isa Baseliner::Role::JobRunner),
    lazy    => 1,
    default => sub {
        require Baseliner::Core::JobRunner;
        Baseliner::Core::JobRunner->new;
    };

# methods 
sub has_bl { 1 } 
sub has_description { 1 } 
sub icon_class { '/static/images/ci/class.gif' }
sub rel_type { +{} }   # { field => rel_type, ... }

sub collection {
    my $self = shift;
    ref $self and $self = ref $self;
    my ($collection) = $self =~ /^BaselinerX::CI::(.+?)$/;
    $collection =~ s{::}{/}g;
    return $collection;
}

sub save {
    use Baseliner::Utils;
    use Baseliner::Sugar;
    my $self = shift;
    my %p;
    if( ref $_[0] eq 'HASH' ) {
        %p = %{ $_[0] };
    } else {
        %p = @_;
    }
    my ($mid,$name,$data,$bl,$active,$versionid) = @{\%p}{qw/mid name data bl active versionid/};
    $mid = $self->mid if !defined $mid && ref $self;
    my $collection = $self->collection;
    my $ret = $mid;

    # transaction bound, in case there are foreign tables
    Baseliner->model('Baseliner')->txn_do(sub{
        if( length $mid ) { 
            ######## update
            #_debug "****************** CI UPDATE: $mid";
            my $row = Baseliner->model('Baseliner::BaliMaster')->find( $mid );
            $row->bl( join ',', _array $bl ) if defined $bl; # TODO mid rel bl (bl) 
            $row->name( $name ) if defined $name;
            $row->active( $active ) if defined $active;
            $row->versionid( $versionid ) if defined $versionid;
            $row->update;
            if( $row ) {
                $self->save_data( $row, $data );
                ##_log _dump { $row->get_columns };
            }
            else {
                _fail _loc "Could not find master row for mid %1", $mid;
            }
        } else {  
            ######## new
            #_debug "****************** CI NEW: $collection";
            my $row = Baseliner->model('Baseliner::BaliMaster')->create({
                collection => $collection, name=> $name, 
                active => $active // 1, versionid=>$versionid // 1
            });
            my $mid = $row->mid;
            $row->bl( join ',', _array $bl ) if defined $bl; # TODO mid rel bl (bl) 
            if( defined $name ) {
                $row->name( $name );
            } else {
                $row->name( "${collection}:${mid}" );
            }
            $self->save_data( $row, $data );
            $ret = $row->mid;
        }
    });
    return $ret;  # mid
}

sub update {
    my ( $self, %p ) = @_;
}

# save data to table or yaml
sub save_data {
    my ( $self, $master_row, $data ) = @_;
    return unless ref $data;
    my $storage = $self->storage;
    # peek into if we need to store the relationship
    my @master_rel;
    my $meta = $self->meta;
    for my $field ( keys %$data ) {
        my $attr = $meta->get_attribute( $field );
        next unless $attr;
        my $type = $attr->type_constraint->name;
        if( $type eq 'CI' || $type eq 'CIs') {
            my $rel_type = $self->rel_type->{ $field };
            next unless $rel_type;
            push @master_rel, { field=>$field, type=>$type, rel_type=>$rel_type, value=>delete($data->{$field}) };
            #_fail( "$field is $type - $rel_type" );
        }
    }
    # attribute specific conversions
    for my $attr ( $meta->get_all_attributes ) {
        if( $attr->type_constraint->name eq 'BoolCheckbox' ) {
            my $attr_name = $attr->name;
            # fix the on versus nothing on form submit
            $data->{ $attr_name } = 0 unless exists $data->{ $attr_name };
        }
    }
    # now store the data
    if( $storage eq 'yaml' ) {
        $master_row->yaml( _dump( $data ) );
        $master_row->update;
    }
    elsif( $storage eq 'fields' ) {
       # TODO  
    }
    else {  # dbic result source
        my $rs = Baseliner->model("Baseliner::$storage");
        $data->{name} //= $master_row->name;
        my $pk = $self->storage_pk;
        $data->{ $pk } //= $master_row->mid;
        $self->table_update_or_create( $rs, $master_row->mid, $data );
    }
    # master_rel relationships, if any
    for my $rel ( @master_rel ) {
        # delete previous relationships
        my $my_rel = $rel->{rel_type}->[0];
        my $other_rel = $my_rel eq 'from_mid' ? 'to_mid' : 'from_mid';
        my $rel_type_name = $rel->{rel_type}->[1];
        DB->BaliMasterRel->search({ $my_rel, $master_row->mid, rel_type=>$rel_type_name })->delete;
        for my $other_mid ( _array $rel->{value} ) {
            #_debug ">>>>>>>> SAVING REL $rel_type_name - FROM $my_rel => $other_rel ( $other_mid )";
            #_debug { $my_rel, $master_row->mid, $other_rel, $other_mid, rel_type=>$rel_type_name };
            DB->BaliMasterRel->create({ $my_rel => $master_row->mid, $other_rel => $other_mid, rel_type=>$rel_type_name })
        }
    }
    return $master_row->mid;
}

sub table_update_or_create {
    my ($self, $rs, $mid, $data ) = @_;
    #_error( $data );
    # find or create
    if( my $row = $rs->find( $mid ) ) {
        return $self->table_update( $row, $data );
    } else {
        return $self->table_create( $rs, $data );
    }
} 
sub table_create { $_[1]->create( $_[2] ) } 
sub table_update { $_[1]->update( $_[2] ) } 

sub load {
    use Baseliner::Utils;
    my ( $self, $mid ) = @_;
    $mid ||= $self->mid;
    _fail _loc( "Missing mid %1", $mid ) unless length $mid;
    my $row = Baseliner->model('Baseliner::BaliMaster')->find( $mid );
    _fail _loc( "Master row not found for mid %1", $mid ) unless ref $row;
    # find class, so that we are subclassed correctly
    my $class = "BaselinerX::CI::" . $row->collection;
    # fix static generic calling from Baseliner::CI
    $self = $class if $self eq 'Baseliner::Role::CI';
    # check class is available, otherwise use a dummy ci class
    $self = $class = 'BaselinerX::CI::Empty' unless _package_is_loaded( $class );
    # get my storage type
    my $storage = $class->storage;
    # setup the base data from master row
    my $data = { $row->get_columns };
    if( $storage eq 'yaml' ) {
        my $y = _load( $row->yaml );
        $data = { %$data, %{ ref $y ? $y : {} } };
    }
    elsif( $storage eq 'fields' ) {
       # TODO a vertical table to store fields 
    }
    else {  # dbic result source
        my $rs = Baseliner->model("Baseliner::$storage");
        my $storage_row = $rs->find( $mid );
        my %tab_data = ref $storage_row ? $storage_row->get_columns : ();
        $data = { %$data, %tab_data };
    }
    # look for relationships
    my $rel_types = $self->rel_type;
    for my $field ( keys %$rel_types ) {
        my $prev_value = $data->{$field};  # save in case there is no relationship, useful for changed cis
        my $rel_type = $rel_types->{ $field };
        my $my_mid = $rel_type->[0];
        my $other_mid = $my_mid eq 'to_mid' ? 'from_mid' : 'to_mid';
        next unless defined $rel_type;
        $data->{ $field } = [
            map { values %$_ }
            DB->BaliMasterRel->search( {
                "$my_mid" => $mid,
                rel_type       => "$rel_type->[1]" },
                { select=> $other_mid } )->hashref->all
        ];
        # use old value unless there's a master_rel object 
        $data->{$field} = $prev_value if defined $prev_value && ! _array( $data->{$field} );
    }
    #_log $data;
    $data->{mid} //= $mid;
    $data->{ci_form} //= $self->ci_form;
    $data->{ci_class} //= $class;
    return $data;
}

sub ci_form {
    my ($self) = @_;
    my $component = sprintf "/ci/%s.js", $self->collection;
    my $fullpath = Baseliner->path_to( 'root', $component );
    return -e $fullpath  ? $component : '';
}

sub storage { 'yaml' }   # ie. yaml, fields, BaliUser, BaliProject
sub storage_pk { 'mid' }  # primary key (mid) column for foreing table

sub related_cis {
    my ($self, %opts )=@_;
    my $mid = $self->mid;
    my $where = {};
    my $edge = $opts{edge} // '';
    if( $edge ) {
        my $dir_normal = $edge =~ /^out/ ? 'to_mid' : 'from_mid';
        my $dir_reverse = $edge =~ /^out/ ? 'from_mid' : 'to_mid';
        $where->{$dir_reverse} = $mid;
    } else {
        $where->{'-or'} = [ from_mid=>$mid, to_mid=>$mid ];
    }
    $where->{rel_type} = { -like=>$opts{rel_type} } if defined $opts{rel_type};
    return map {
        my $rel_edge = $_->{from_mid} == $mid
            ? 'child'
            : 'parent';
        my $rel_mid = $rel_edge eq 'child'
            ? $_->{to_mid}
            : $_->{from_mid}; 
        my $ci = _ci( $rel_mid );
        # adhoc ci data with relationship info
        $ci->{_edge} = { rel=>$rel_edge, rel_type=>$_->{rel_type}, mid=>$mid, depth=>$opts{depth_original}-$opts{depth}, path=>$opts{path} };
        $ci;
    } DB->BaliMasterRel->search( $where, { } )->hashref->all;
}

sub _filter_cis {
    my ($self, %opts) = @_;
    return () unless ref $opts{_cis} eq 'ARRAY';
    my @cis = @{ delete $opts{_cis} };
    if( $opts{does} || $opts{does_any} || $opts{does_all} ) {
        @cis = grep { 
            my @does = map { "Baseliner::Role::CI::$_" } _array( $opts{does}, $opts{does_all}, $opts{does_any} );
            my $ci = $_;
            if( exists $opts{does_all} ) {
                List::MoreUtils::all( sub { $ci->does( $_ ) }, @does );
            } else {
                _any( sub { $ci->does( $_ ) }, @does );
            }
        } @cis;
    }
    return @cis;
}

=head2 related

Traverses the master_rel relationships, recursing if necessary.

Returns an instantiated ci list.

Options:

    edge => 'in' | 'out' | undef
        type of edges to traverse. 
            out: where from_mid == mid
            in: where to_mid == mid
            undef: both in and out

    depth => 1
        how many levels to recurse. Default is 1, which means no recursion.  

    mode => 'flat' | 'tree'
        how to return the data. Tree mode will return nodes nested into 
        an attribute called 'ci_rel' 

    does => ['Server']
        filters CIs that do the role "Baseliner::Role::Server"

    does_any => ['Server', 'Project']
        filters CIs that do any of the roles (OR)

    does_all => ['Server', 'Project']
        filters CIs that do all of the roles (AND)

    filter_early => 1|0
        checks CIs filters (does) before recursing. 

=cut
sub related {
    my ($self, %opts)=@_;
    my $mid = $self->mid;
    my $depth = $opts{depth} // 1;
    $opts{depth_original} //= $depth;
    $opts{mode} //= 'flat';
    $opts{visited} //= {};
    $opts{path} //= [];
    push @{ $opts{path} }, $mid;
    return () if exists $opts{visited}{$mid};
    local $Baseliner::CI::_no_record = $opts{no_record} // 0; # make sure we include a _ci 
    $opts{visited}{ $mid } = 1;
    $depth = 1 if $depth < 1; # otherwise we go into infinite loop
    # get my related cis
    my @cis = $self->related_cis( %opts );
    # filter before
    @cis = $self->_filter_cis( %opts, _cis=>\@cis ) if $opts{filter_early};
    # now delve deeper if needed
    if( --$depth ) {
        my $path = [ _array $opts{path} ];  # need another ref in order to preserve opts{path}
        if( $opts{mode} eq 'tree' ) {
            for my $ci( @cis ) {
                push @{ $ci->{ci_rel} }, $ci->related( %opts, depth=>$depth, path=>$path );
            }
        } else {  # flat mode
            push @cis, map { $_->related( %opts, depth=>$depth, path=>$path ) } @cis;
        }
    }
    # filter
    @cis = $self->_filter_cis( %opts, _cis=>\@cis ) unless $opts{filter_early};
    return @cis;
}

sub parents {
    my ($self, %opts)=@_;
    return $self->related( %opts, edge=>'in' );
}

sub children {
    my ($self, %opts)=@_;
    return $self->related( %opts, edge=>'out' );
}

# from Node
has uri      => qw(is rw isa Str);   # maybe a URI someday...
has resource => qw(is rw isa Baseliner::URI), 
                # handles => qr/.*/  # ---> problematic, injects its URI methods into all CIs (host, port, etc)
                ;

has debug => qw(is rw isa Bool), default=>sub { $ENV{BASELINER_DEBUG} };

1;

# Attribute Trait 
package Baseliner::Role::CI::Trait;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Scalar::Util; # 'looks_like_number', 'weaken';

Moose::Util::meta_attribute_alias('CI');

our $gscope;

my $init = sub {
    my ($val) = @_;
    my $obj = $gscope->{$val};
    if( defined $obj ) {
        $_[1] = 1;
        return $obj;
    } else {
        $_[1] = 0;
        return Baseliner::CI->new( $val );
    }
};

around initialize_instance_slot => sub {
    my ($orig, $self) = (shift,shift);
    my ($meta_instance, $instance, $params) = @_;

    my $init_arg = $self->init_arg();
    $gscope or local $gscope = {};
    $gscope->{ $instance->mid // $params->{mid} } //= $instance;
    
    my $weaken = 0;
    if( defined($init_arg) and exists $params->{$init_arg} ) {
        my $val = $params->{$init_arg};
        my $tc = $self->type_constraint;
        # needs coersion?
        if( ! $tc->check( $val ) ) {
            if( $tc->is_a_type_of('ArrayRef') ) {
                match_on_type $val => (
                    'Undef' => sub {
                        $params->{$init_arg} = [ BaselinerX::CI::Empty->new ];
                    },
                    'Num|Str' => sub {
                        if( length $val ) {
                            $params->{$init_arg} = [ $init->( $val, $weaken ) ];
                            Scalar::Util::weaken( $params->{$init_arg}->[0] ) if $weaken;
                            $weaken = 0;
                        } else {
                            $params->{$init_arg} = [ BaselinerX::CI::Empty->new ];
                        }
                    },
                    'ArrayRef[Num]' => sub {
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
                );
            }
            else {
                match_on_type $val => (
                    'Undef' => sub {
                        $params->{$init_arg} = BaselinerX::CI::Empty->new;
                    },
                    'Num|Str' => sub {
                        if( length $val ) {
                            $params->{$init_arg} = $init->( $val, $weaken );
                        } else {
                            $params->{$init_arg} = BaselinerX::CI::Empty->new;
                        }
                    },
                    'ArrayRef[Num]' => sub {
                        if( length $val->[0] ) {
                            $params->{$init_arg} = $init->( $val->[0], $weaken );
                        } else {
                            $params->{$init_arg} = BaselinerX::CI::Empty->new;
                        }
                    },
                    'ArrayRef[CI]' => sub {
                        $params->{$init_arg} = [ $init->( $val, $weaken ) ];
                        Scalar::Util::weaken( $params->{$init_arg}->[0] ) if $weaken;
                        $weaken = 0;
                    },
                );
            }
        }
    }
    $self->$orig( @_ );
    $self->_weaken_value($instance) if $weaken;
};

1;
