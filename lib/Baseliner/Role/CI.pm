package Baseliner::Role::CI;
use Moose::Role;
use v5.10;

use Moose::Util::TypeConstraints;
use Try::Tiny;
require Baseliner::CI;
use Baseliner::Utils qw(_throw _fail _loc _log _debug _unique _array _load _dump _package_is_loaded _any);
use Baseliner::Sugar;

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
#coerce 'CI' =>
#  from 'Str' => via { length $_ ? Baseliner::CI->new( $_ ) : BaselinerX::CI::Empty->new()  }, 
#  from 'Num' => via { Baseliner::CI->new( $_ ) }, 
#  from 'ArrayRef' => via { my $first = [_array( $_ )]->[0]; defined $first ? Baseliner::CI->new( $first ) : BaselinerX::CI::Empty->new() }; 
#
#coerce 'CIs' => 
#  from 'Str' => via { length $_ ? [ Baseliner::CI->new( $_ ) ] : [ BaselinerX::CI::Empty->new() ]  }, 
#  from 'ArrayRef[Num]' => via { my $v = $_; [ map { Baseliner::CI->new( $_ ) } _array( $v ) ] },
#  from 'Num' => via { [ Baseliner::CI->new( $_ ) ] }; 

has mid      => qw(is rw isa Num);
has active   => qw(is rw isa Bool default 1);
has ts       => qw(is rw isa TS coerce 1), default => sub { Class::Date->now->string };
#has _ci      => qw(is rw isa Any);  # the original DB record returned by load() XXX conflicts with Utils::_ci

requires 'icon';
#sub icon { '/static/images/icons/ci.png' }

has name        => qw(is rw isa Maybe[Str]);
has bl          => qw(is rw isa BL coerce 1 default *);
has description => qw(is rw isa Maybe[Str]);
has ns          => qw(is rw isa Maybe[Str]);
has versionid   => qw(is rw isa Maybe[Str] default 1);
has moniker     => qw(is rw isa Maybe[Str]);    # lazy 1);#,
has created_by  => qw(is rw isa Maybe[Str]);
has modified_by => qw(is rw isa Maybe[Str]);
    # default=>sub{   
    #     my $self = shift; 
    #     if( ref $self ) {
    #         my $nid = Util->_name_to_id( $self->name );
    #         return $nid;
    #     }
    # };  # a short name for this
has job     => qw(is rw isa Baseliner::Role::JobRunner),
        lazy    => 1, default => sub {
            BaselinerX::CI::job->new;
        };

sub storage { 'yaml' }   # ie. yaml, deprecated: for now, no other method supported

# methods 
sub has_bl { 1 } 
sub has_description { 1 } 
sub icon_class { '/static/images/ci/class.gif' }
sub rel_type { +{} }   # { field => rel_type, ... }

sub dump {
    my ($self) = @_;
    return Util->_dump( $self ); 
}

sub class_short_name {
    my $self = shift;
    ref $self and $self = ref $self;
    my ($classname) = $self =~ /^BaselinerX::CI::(.+?)$/;
    if( length $classname ) {
        $classname =~ s{::}{/}g;
        return $classname;
    } else {
        return $self;
    }
}

sub collection {
    my $self = shift;
    return $self->class_short_name;
}

sub serialize {
    my ($self)=@_;
    return () if !ref $self;
    # XXX consider calling known attribute methods instead
    my %data = map { $_ => $self->{$_} } grep !/^_/, keys %{$self};
    # cleanup 
    if( $self->does( 'Baseliner::Role::Service' ) ) {
        delete $data{log};
        delete $data{job};
    }
    return \%data;
}

# sets several attributes at once, like DBIC
#   the ci must exist (self=ref)
sub update {
    my ($self, %data ) = @_;

    my $class = ref $self;
    
    # detect changed fields, in case it's a new row then all data is changed
    my $changed = +{ map { $_ => $data{$_} } grep { 
        ( defined $self->{$_} && !defined $data{$_} ) 
        || ( !defined $self->{$_} && defined $data{$_} ) 
        || $self->{$_} ne $data{$_} 
        } keys %data } ;
        
    # merge and recreate object
    my $d = { %$self, %data };  
    $self = $class->new( $d );  
    
    $self->save( changed=>$changed );
}

sub save {
    my ($self,%opts) = @_;
    
    my $collection = $self->collection;

    my $mid = $self->mid;
    my $bl = $self->bl;
    $bl = '*' if !length $bl; # fix empty submits from web
    my $exists = ! ! $mid;
    my $ns = $self->ns;
    
    # try to get mid from ns
    if( !$exists && length $ns && $ns ne '/' ) {
        my $ns_row = DB->BaliMaster->search({ collection=>$collection, ns=>$ns }, {select=>'mid' })->first;
        if( $ns_row ) {
            $mid = $ns_row->mid;
            $exists = 1;
        }
    }

    Baseliner->cache_remove( qr/^ci:/ );
    Baseliner->cache_remove( qr/ci:[0-9]+:/ );
    Baseliner->cache_remove( qr/:$mid:/ ) if length $mid;
    
    # transaction bound, in case there are foreign tables
    Baseliner->model('Baseliner')->txn_do(sub{
        my $row;
        if( $exists ) { 
            ######## UPDATE CI
            $row = DB->BaliMaster->find( $mid );
            if( $row ) {
                $row->bl( join( ',', Util->_array( $bl ) ) );
                $row->name( $self->name );
                $row->active( $self->active );
                $row->versionid( $self->versionid || '1' );
                $row->moniker( $self->moniker );
                $row->ns( $self->ns );
                $row->ts( Util->_dt );
                $row->update;  # save bali_master data
                
                $self->update_ci( $row, undef, \%opts );
            }
            else {
                _fail _loc "Could not find master row for mid %1", $mid;
            }
            if( ref $self ) {
                $self->mid( $mid );
            }
        } else {
            ######## NEW CI
            $row = DB->BaliMaster->create(
                {
                    collection => $collection,
                    name       => $self->name,
                    ns         => $self->ns,
                    ts         => Util->_dt,
                    moniker    => $self->moniker,
                    bl         => join( ',', Util->_array( $bl ) ),
                    active     => $self->active // 1,
                    versionid  => $self->versionid || 1,
                }
            );
            # update mid into CI
            $mid = $row->mid;
            $self->mid( $row->mid );
            # put a default name
            if( !length $row->name ) {
                my $name = $collection . ':' . $mid;
                $row->update({ name=> $name });
                $self->name( $name );
            }
            
            # now save the rest of the ci data (yaml)
            $self->new_ci( $row, undef, \%opts );
        }
        # update mongo master
        mdb->master->update({ mid=>$self->mid }, +{ $row->get_columns }, { upsert=>1 });
    });  # txn end
    return $mid; 
}

sub delete {
    my ( $self, $mid ) = @_;
    
    $mid //= $self->mid;
    if( $mid ) {
        my $row = DB->BaliMaster->find( $mid );
        DB->BaliMasterRel->search({ -or=>[{ from_mid=>$mid },{ to_mid=>$mid }] })->delete;
        mdb->master_doc->remove({ mid=>"$mid" });
        if( $row ) {
            # perfect
            Baseliner->cache_remove( qr/^ci:/ );
            delete $self->{mid} if ref $self;  # delete the mid value, in case a reuse is in place
            return $row->delete;
        } else {
            # not found warning, cleanup master_doc in the way out
            Util->_warn( Util->_loc( 'Could not delete, master row %1 not found', $mid ) );
        }
    } else {
        return undef;
    }
}

# hook
sub update_ci {
    my ( $self, $master_row, $data, $opts ) = @_;
    # if no data=> supplied, save myself
    $opts //= {}; # maybe lost during bad arounds
    $opts->{save_type} = 'update';
    $data = $self->serialize if !defined $data;
    $self->save_data( $master_row, $data, $opts );
}

sub new_ci {
    my ( $self, $master_row, $data, $opts ) = @_;
    # if no data=> supplied, save myself
    $opts //= {}; # maybe lost during bad arounds
    $opts->{save_type} = 'new';
    $data = $self->serialize if !defined $data;
    $self->save_data( $master_row, $data, $opts);
}

sub field_is_ci {
    my ($self,$field,$meta) = @_;
    $meta //= $self->meta;
    my $attr = $meta->get_attribute( $field ) or return;
    my $type_cons = $attr->type_constraint or return;
    my $type = $type_cons->name;
    my $has_ci_trait = grep /Baseliner::Role::CI::Trait/, _array( $attr->applied_traits );
    return $type if $has_ci_trait || $type eq 'CI' || $type eq 'CIs' || $type =~ /^Baseliner::Role::CI/;
}

# save data to yaml and master_doc, does not use self
sub save_data {
    my ( $self, $master_row, $data, $opts ) = @_;
    return unless ref $data;
    my $storage = $self->storage;
    # peek into if we need to store the relationship
    my @master_rel;
    my $meta = $self->meta;
    for my $field ( keys %$data ) {
        if( my $type = $self->field_is_ci($field,$meta) ) { 
            my $rel_type = $self->rel_type->{ $field } or Util->_fail( Util->_loc( "Missing rel_type definition for %1 (class %2)", $field, ref $self || $self ) );
            next unless $rel_type;
            my $v = delete($data->{$field});  # consider a split on ,  
            $v = [ split /,/, $v ] unless ref $v;
            push @master_rel, { field=>$field, type=>$type, rel_type=>$rel_type, value=>$v }; 
            #_error( \@master_rel );
            #_fail( "$field is $type - $rel_type" );
        }
    }
    # attribute specific conversions
    for my $attr ( $meta->get_all_attributes ) {
        my $type_cons = $attr->type_constraint or next;
        if( $type_cons->name eq 'BoolCheckbox' ) {
            my $attr_name = $attr->name;
            # fix the on versus nothing on form submit
            $data->{ $attr_name } = 0 unless exists $data->{ $attr_name };
        }
    }
    # master_rel relationships, if any
    my %relations;
    for my $rel ( @master_rel ) {
        # delete previous relationships
        my $my_rel = $rel->{rel_type}->[0];
        my $other_rel = $my_rel eq 'from_mid' ? 'to_mid' : 'from_mid';
        my $rel_type_name = $rel->{rel_type}->[1];
        # delete all records related 
        my $mr_where ={ $my_rel=>$master_row->mid, rel_type=>$rel_type_name };
        DB->BaliMasterRel->search($mr_where)->delete;
        mdb->master_rel->remove($mr_where,{ multiple=>1 });
        for my $other_mid ( _array $rel->{value} ) {
            $other_mid = $other_mid->mid if ref( $other_mid ) =~ /^BaselinerX::CI::/;
            next unless $other_mid;
            my $rdoc = { $my_rel => $master_row->mid, $other_rel => $other_mid, rel_type=>$rel_type_name, rel_field=>$rel->{field} };
            DB->BaliMasterRel->find_or_create($rdoc);
            mdb->master_rel->find_or_create($rdoc);
            push @{$relations{ $rel->{field} }}, $other_mid;
            Baseliner->cache_remove( qr/:$other_mid:/ );
        }
    }
    # now store the data
    if( $storage eq 'yaml' ) {
        $self->save_fields( $master_row, $data, undef, \%relations );
    } else {
        # temporary: multi-storage deprecated
        Util->_fail( Util->_loc('CI Storage method not supported: %1', $storage) );
    }
    return $master_row;
}

sub save_fields {
    my ($self, $master_row, $data, $opts, $relations ) = @_;
    $opts //={};
    $opts->{master_only} //= 1;
    my $mid = $master_row->mid;
    if( !$master_row ) {
        mdb->master_doc->remove({ mid=>"$mid" });
        _fail _loc( 'Master row not found for mid %1', $mid );
    }
    $master_row->update({ yaml=>Util->_dump($data) });
    my $md = mdb->master_doc;
    if( my $row = $md->find_one({ mid=>"$mid" }) ) {
        my $id = $row->{_id};
        my $doc = { ( $master_row ? $master_row->get_columns : () ), %$row, %{ $data || {} } };
        my $final_doc = Util->_clone($doc);
        Util->_unbless($final_doc);
        mdb->clean_doc($final_doc);
        $final_doc->{_id} = $id;  # preserve OID object
        $md->save({ %$final_doc, %{ $relations || {} } });
    } else {
        my $doc = { ( $master_row ? $master_row->get_columns : () ), %{ $data || {} }, mid=>"$mid" };
        delete $doc->{yaml};
        my $final_doc = Util->_clone($doc);
        Util->_unbless($final_doc);
        mdb->clean_doc($final_doc);
        $md->insert({ %$final_doc, %{ $relations || {} } });
    }
}

sub load {
    my ( $self, $mid, $row, $data, $yaml, $rel_data ) = @_;
    $mid ||= $self->mid if $self->can('mid');
    _fail _loc( "Missing mid %1", $mid ) unless length $mid;
    # in scope ? 
    my $scoped = $Baseliner::CI::mid_scope->{ $mid } if $Baseliner::CI::mid_scope;
    #say STDERR "----> SCOPE $mid =" . join( ', ', keys( $Baseliner::CI::mid_scope // {}) ) if $Baseliner::CI::mid_scope && Baseliner->debug;
    return $scoped if $scoped;
    # in cache ?
    my $cache_key = "ci:$mid:";
    my $cached = Baseliner->cache_get( $cache_key );
    #Util->_warn( "Cached $mid" ) if $cached;
    return $cached if $cached;

    if( !$data ) {
        $row //= DB->BaliMaster->find( $mid );
        if( ! ref $row ) {
            mdb->master_doc->remove({ mid=>"$mid" });
            _fail _loc( "Master row not found for mid %1", $mid );
        }
        # setup the base data from master row
        $data = ref $row eq 'HASH' ? $row : { $row->get_columns }; # row may come already hashref'ed
    }

    # find class, so that we are subclassed correctly
    my $class = "BaselinerX::CI::" . $data->{collection};
    # fix static generic calling from Baseliner::CI
    $self = $class if $self eq 'Baseliner::Role::CI';
    # check class is available, otherwise use a dummy ci class
    $self = $class = 'BaselinerX::CI::Empty' unless _package_is_loaded( $class );
    
    # load pre-data
    $data = { %$data, %{ $self->load_pre_data($mid, $data) || {} } };
    # get my storage type
    my $storage = $class->storage;
    if( $storage eq 'yaml' ) {
        $data->{yaml} //= $yaml;
        $data->{yaml} =~ s{!!perl/code}{}g;
        my $y = try { _load( $data->{yaml} ) } catch {
            my $err = shift;
            Util->_error( Util->_loc( "Error deserializing CI %1. Error YAML ref: %2", $mid, $err) );
            Util->_error( Util->_whereami );
            undef;
        };
        Util->_error( Util->_loc( "Error deserializing CI %1. Missing or invalid YAML ref: %2", $mid, ref $y || '(empty)' ) ) 
            unless ref $y eq 'HASH';
        $data = { %{ $data || {} }, %{ $y || {} } };   # TODO yaml should be blessed obj?
    }
    else {  # dbic result source
        Util->_fail( Util->_loc('CI Storage method not supported: %1', $storage) );
    }
    # load post-data and merge
    $data = { %$data, %{ $self->load_post_data($mid, $data) || {} } };
    # look for relationships
    if( ! $Baseliner::CI::no_rels ) {
        my $rel_types = $self->rel_type;
        my %field_rel_mids;
        for my $field ( keys %$rel_types ) {
            #my $prev_value = $data->{$field};  # save in case there is no relationship, useful for changed cis
            my $rel_type = $rel_types->{ $field };
            next unless defined $rel_type;
            my $my_mid = $rel_type->[0];
            my $other_mid = $my_mid eq 'to_mid' ? 'from_mid' : 'to_mid';
            $field_rel_mids{ $rel_type->[1] } = { field=>$field, my_mid => $my_mid, other_mid => $other_mid, opts=>{splice @$rel_type,2} };
            delete $data->{$field}; # delete yaml junk
            #$data->{$field} = $prev_value if defined $prev_value && ! _array( $data->{$field} );
        }
        # get rel data
        if( my @fields = keys %field_rel_mids ) {
            my @rel_type_data = ref $rel_data eq 'ARRAY' 
                ? @$rel_data 
                : ref $rel_data eq 'HASH' 
                    ? @{ $rel_data->{$mid} || [] }
                    : DB->BaliMasterRel->search( 
                        { -or=>[ to_mid=>$mid, from_mid=>$mid ], rel_type => \@fields },
                        { select=> ['from_mid', 'to_mid', 'rel_type' ] } )->hashref->all;
                    
            for my $rel_row ( @rel_type_data ) {
                my $f = $field_rel_mids{ $rel_row->{rel_type} }; 
                next unless $f;
                next if $rel_row->{ $f->{my_mid} } ne $mid;
                my $other_mid = $rel_row->{ $f->{other_mid} };
                next unless $other_mid;
                my $prev_value = $data->{ $f->{field} };
                # add mid to field array
                push @{ $data->{ $f->{field} } }, $other_mid;
            }
        }
    }
    
    #_log $data;
    $data->{mid} //= $mid;
    $data->{ci_form} //= $self->ci_form if $Baseliner::CI::get_form;
    $data->{ci_class} //= $class;
    $Baseliner::CI::mid_scope->{ "$mid" } = $data if $Baseliner::CI::mid_scope;
    Baseliner->cache_set($cache_key, $data);
    return $data;
}

sub load_from_search {
    my ($class, $where, %p ) = @_;
    my @rows = DB->BaliMaster->search( $where )->hashref->all;
    if( $p{single} ) {
        _throw _loc('More than one row returned (%1) for CI load %2, mids found: %3', 
            scalar(@rows), Util->_to_json($where), join(',', map{$_->{mid}} @rows) )
            if scalar @rows > 1;
        return unless @rows;
        return $class->load( $rows[0]->{mid} );
    } else {
        return map { $class->load($_->{mid}) } @rows;
    }
}

sub load_from_query {
    my ($class, $where, %p ) = @_;
    my @mids = map { $_->{mid} } mdb->master_doc->find($where)->fields({ mid=>1 })->limit(1000)->all;
    my @rows = DB->BaliMaster->search({ mid=>\@mids })->hashref->all;
    if( $p{single} ) {
        _throw _loc('More than one row returned (%1) for CI load %2, mids found: %3', 
            scalar(@rows), Util->_to_json($where), join(',', map{$_->{mid}} @rows) )
            if scalar @rows > 1;
        return $class->load( $rows[0]->{mid} );
    } else {
        return map { $class->load($_->{mid}) } @rows;
    }
}

sub query {
    my ($self, $where, %p ) = @_;
    $where //= {};
    if( !$where->{collection} && $self->can('collection') ) {
        my $coll = $self->collection;
        $where->{collection} = $coll if length $coll; 
    }
    local $Baseliner::CI::_no_record = 1;
    my @recs = map { Baseliner::Role::CI->_build_ci_instance_from_rec( $_ ) }  Baseliner::Role::CI->load_from_query( $where, %p );
    return @recs;
}
        
sub load_pre_data { +{} }
sub load_post_data { +{} }

=head2 _build_ci_instance_from_rec

Creates a CI obj from a hash.

=cut
sub _build_ci_instance_from_rec {
    my ($class,$rec) = @_;
    local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;
    my $yaml = delete $rec->{yaml}; # useless from here
    if( $Baseliner::CI::_record_only ) {
        return $rec;
    }
    my $ci_class = $rec->{ci_class}; 
    # instantiate
    my $obj = $ci_class->new( $rec );
    # add the original record to _ci
    if( ! $Baseliner::CI::_no_record ) {   ## TODO change this to $Baseliner::CI::ci_record
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

sub TO_JSON {
    my ($self) = @_;
    my $clone = Util->_clone( $self );
    return Util->_unbless( $clone );
}

sub ci_form {
    my ($self) = @_;
    my $component = $self->can('form') ? $self->form : sprintf( "/ci/%s.js", $self->collection );
    my $fullpath = Baseliner->path_to( 'root', $component );
    return -e $fullpath  ? $component : '';
}

sub related_cis {
    my ($self_or_class, %opts )=@_;
    my $mid = ref $self_or_class ? $self_or_class->mid : $opts{mid};
    $mid // _fail 'Missing parameter `mid`';
    # in scope ? 
    #local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;
    my $scope_key =  "related_cis:$mid:" . Storable::freeze( \%opts );
    my $scoped = $Baseliner::CI::mid_scope->{ $scope_key } if $Baseliner::CI::mid_scope;
    return @$scoped if $scoped;
    # in cache ?
    my $cache_key = [ "ci:$mid:", \%opts ];
    if( my $cached = Baseliner->cache_get( $cache_key ) ) {
        return @$cached if ref $cached eq 'ARRAY';
    }
    my $where = {};
    my @ands;
    my $edge = $opts{edge} // '';
    if( $edge ) {
        my $dir_normal = $edge =~ /^out/ ? 'to_mid' : 'from_mid';
        my $dir_reverse = $edge =~ /^out/ ? 'from_mid' : 'to_mid';
        $where->{$dir_reverse} = $mid;
    } elsif( $opts{where} ) {
        my @mids = grep { $_ ne $mid } map {$_->{mid} } mdb->master_doc->find($opts{where})->fields({ mid=>1, _id=>0 })->all;
        push @ands, { '$or'=> [ { from_mid=>mdb->in(@mids), to_mid=>$mid }, {to_mid=>mdb->in(@mids), from_mid=>$mid} ] };
    } else {
        push @ands, { '$or'=> [ {from_mid=>$mid}, {to_mid=>$mid} ] };
    }
    $where->{rel_type} = { -like=>$opts{rel_type} } if defined $opts{rel_type};
    # paging support
    $opts{limit} //= 20;
    $where->{'$and'} = \@ands if @ands;
    ######### rel query
    my $rs = mdb->master_rel->find( $where );
    ########
    if( $opts{order_by} ) {
        Util->_error( "IGNORED: " . _dump( $opts{order_by} ) );   
    }
    $rs->skip( $opts{start} ) if $opts{start} > 0;
    $rs->limit( $opts{limit} ) if $opts{limit} > 0;

    my @data = $rs->all;
    local $Baseliner::CI::no_rels = 1 if $opts{no_rels};
    my @ret = map {
        my $rel_edge = $_->{from_mid} == $mid
            ? 'child'
            : 'parent';
        my $rel_mid = $rel_edge eq 'child'
            ? $_->{to_mid}
            : $_->{from_mid}; 
        my $ci = Baseliner::CI->new( $rel_mid );
        # adhoc ci data with relationship info
        if( $Baseliner::CI::_edge ) {
            $ci->{_edge} = { rel=>$rel_edge, rel_type=>$_->{rel_type}, mid=>$mid, depth=>$opts{depth_original}-$opts{depth}, path=>$opts{path} };
        }
        $ci;
    } @data;
    $Baseliner::CI::mid_scope->{ $scope_key } = \@ret if $Baseliner::CI::mid_scope;
    Baseliner->cache_set( $cache_key, \@ret );
    return @ret;
}

sub _filter_cis {
    my ($self_or_class, %opts) = @_;
    return () unless ref $opts{_cis} eq 'ARRAY';
    my @cis = @{ delete $opts{_cis} };
    if( $opts{does} || $opts{does_any} || $opts{does_all} ) {
        @cis = grep { 
            my $ci = $_;
            my @does = map { "Baseliner::Role::CI::$_" } _array( $opts{does}, $opts{does_all}, $opts{does_any} );
            if( exists $opts{does_all} ) {
                List::MoreUtils::all( sub { $ci->does( $_ ) }, @does );
            } else {
                _any( sub { $ci->does( $_ ) }, @does );
            }
        } @cis;
    }
    if( $opts{isa} || $opts{isa_any} || $opts{isa_all} ) {
        @cis = grep { 
            my @isa = map { "BaselinerX::CI::$_" } _array( $opts{isa}, $opts{isa_all}, $opts{isa_any} );
            my $ci = $_;
            if( exists $opts{isa_all} ) {
                List::MoreUtils::all( sub { $ci->isa( $_ ) }, @isa );
            } else {
                _any( sub { $ci->isa( $_ ) }, @isa );
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

    filter_early => 1|0 (default:0)
        checks CIs filters (does) before recursing. 

    unique => 1|0 (default:0)
        no duplicate cis in the list, useful to avoid recursive trees

    no_rels => 1|0 (default:0) 
        don't load relationships into CIs

    start => Num
        start row for MasterRel query
    
    rows => Num
        how many rows to retrieve from MasterRel

    order_by => { ... }
        MasterRel order by

=cut
sub related {
    my ($self_or_class, %opts)=@_;
    my $mid = ref $self_or_class ? $self_or_class->mid : $opts{mid};
    $mid // _fail 'Missing parameter `mid`';
    # in cache ? 
    my $cache_key = [ "ci:$mid:",  \%opts ];
    if( my $cached = Baseliner->cache_get( $cache_key ) ) {
        return @$cached if ref $cached eq 'ARRAY';
    }
    my $depth = $opts{depth} // 1;
    $opts{depth} //= 1;
    $opts{depth_original} //= $depth;
    $opts{mode} //= 'flat';
    $opts{visited} //= {};
    $opts{path} //= [];
    push @{ $opts{path} }, $mid;
    return () if exists $opts{visited}{$mid};
    local $Baseliner::CI::_no_record = $opts{no_record} // 1; # make sure we *don't* include a _ci (rgo) 
    $opts{visited}{ $mid } = 1;
    local $Baseliner::ci_unique = {} unless defined $Baseliner::ci_unique;
    
    # get my related cis
    my @cis = $self_or_class->related_cis( %opts );
    # unique?
    @cis = grep { !exists $Baseliner::ci_unique->{$_->{mid}} && ($Baseliner::ci_unique->{$_->{mid}}=1) } @cis
        if $opts{unique} ;
    # filter before
    @cis = $self_or_class->_filter_cis( %opts, _cis=>\@cis ) if $opts{filter_early};
    # now delve deeper if needed
    $depth --;
    if( $depth<0 || $depth>0 ) {
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
    @cis = $self_or_class->_filter_cis( %opts, _cis=>\@cis ) unless $opts{filter_early};
    Baseliner->cache_set( $cache_key, \@cis );
    return @cis;
}

sub parents {
    my ($self_or_class, %opts)=@_;
    local $Baseliner::CI::mid_scope = {} unless defined $Baseliner::CI::mid_scope;
    return $self_or_class->related( %opts, edge=>'in' );
}

sub children {
    my ($self_or_class, %opts)=@_;
    local $Baseliner::CI::mid_scope = {} unless defined $Baseliner::CI::mid_scope;
    return $self_or_class->related( %opts, edge=>'out' );
}

sub list_by_name {
    my ($class, $p)=@_;
    my $where = {};
    $where->{name} = $p->{names} if defined $p->{names};
    my $from = { select=>'mid' };
    $from->{rows} = $p->{rows} if defined $p->{rows};
    [ map { ci->new( $_->{mid} ) } DB->BaliMaster->search($where, $from)->hashref->all ];
}

=head2 push_ci_unique

Adds a ci to a has_cis list, making sure the list remains 
unique. 

    $self->push_ci_unique( 'field', $ci ); 

All cis must be expanded into objects with ->mid available. 

=cut
sub push_ci_unique {
    my ($self,$field,$ci) = @_;
    my $cis = $self->$field; 
    my %unique;
    for my $rel ( @{ $cis || [] } ) {
        $unique{ $rel->mid } = $rel; 
    }
    $unique{ $ci->mid } = $ci; 
    $self->$field( [ values %unique ] );
}

=head2 attribute_default_values

Return all default values for the CI class'
attributes that are not C<sub{}>

=cut
sub attribute_default_values {
    my ($class)=@_;
    my %defs =
        map { 
            $_->name => $_->default 
        } 
        grep { 
            my $d=$_->default; 
            defined $d && ref $d ne 'CODE'; 
        } 
        $class->meta->get_all_attributes;
    return \%defs;
}


# XXX deprecated:
sub searcher {
    my ($self, %p ) = @_;
    my $coll = $self->collection;
    my @fields = _unique _array('mid', $p{fields});
    my $schema = [
        map {
            +{ name=>$_, sortable=>1 } 
        } @fields 
    ];
    require Baseliner::Lucy;
    my $string_tokenizer = Lucy::Analysis::RegexTokenizer->new( pattern => '\w');
    my $analyzer = Lucy::Analysis::PolyAnalyzer->new( analyzers => [$string_tokenizer]);

    my $searcher = Baseliner::Lucy->new(
            index_path => Lucy::Store::RAMFolder->new, # in-memory files "$dir",
            language   => 'es', 
            analyser   => $analyzer, 
            resultclass => 'LucyX::Simple::Result::Hash',
            entries_per_page => 10,
            schema     => $schema,
            highlighter => 'Baseliner::Lucy::Highlighter',
            search_fields => ['gdi_perfil_dni', 'id'],
            search_boolop => 'AND',
        );
    my @cis = map {
       my $h = _load( delete $_->{yaml} );
       my $d = { %$_, %$h };
       +{ map { $_ => $d->{$_} } @fields  };
    } DB->BaliMaster->search({ collection=>$coll })->hashref->all;

    my $sort_spec;
    if( $p{sort} ) {
        $sort_spec = Lucy::Search::SortSpec->new(
                rules => [
                    map { 
                        my ($field,$dir) = /^(\S+) (\S+)$/ ? ($1,$2) : ($_,'ASC');
                        Lucy::Search::SortRule->new( field =>$field, reverse=>( $dir =~ /asc/i ? 0 : 1 )  ) 
                    } _array($p{sort})
                ],
        );
    }
        
    my $query;
    if( ref $p{query} ) {
        while( my ($k,$v) = each %{ $p{query} } ) {
            $query = Lucy::Search::TermQuery->new(
                field => $k,
                term  => $v,
            );
        }
    } else {
        $query = $p{query};
    }

    map { $searcher->create($_) } @cis;
    $searcher->commit;
    my ( $results, $pager ) = try {
       $searcher->search( $query, 1, $sort_spec );
    } catch {
      _debug shift(); # usually a "no results" exception
      ([],undef);
    };
}

sub mem_table {
    my ($self, %p) = @_;
    my $coll = $self->collection;
    my @cols = grep { $_ ne 'mid' } (
        @{ $p{cols} || [] } 
        ||  
        ( map { $_->name } $self->meta->get_all_attributes )
    );
    require DBIx::Simple;
    my $db = $p{db} // DBIx::Simple->connect('dbi:SQLite::memory:'); 
    my $cols_str = join ',', map { "$_ text" } @cols;
    eval { $db->query("create table $coll ( mid number, $cols_str, unique (mid ) )") };
    push @cols, 'mid';
    @cols = _unique @cols;
    if( ref $p{cis} eq 'ARRAY' ) {
        $self->mem_load( db=>$db, cis=>$p{cis}, cols=>\@cols  );
    }
    elsif( exists $p{mid} ) {
        $self->mem_load( db=>$db, cis=>[ map { ci->new( $_ ) } _array($p{mid}) ], cols=>\@cols  );
    }
    else {   # full collection, from yaml
        #my @mids = map { $_->{mid} } DB->BaliMaster->search({ collection=>$coll }, { select=>'mid' })->hashref->all;
        #$self->mem_load( db=>$db, cis=>[ map { ci->new( $_ ) } @mids ], cols=>\@cols  );
        my @cis = map {
            my $h = _load( delete $_->{yaml} ) // {};
            +{ %$_, %$h };
        } DB->BaliMaster->search( { collection => $coll, %{ $p{where} || {} } }, $p{from} )->hashref->all;
        $self->mem_load( db => $db, cis =>\@cis, cols => \@cols );
    }
    return $db;
}

sub mem_load {
    my ($self,%p) = @_;
    my $coll = $self->collection;
    my @cols = @{ $p{cols} };
    my $db = $p{db};
    my $k = @cols;
    my $pos_str = join ',', map { '?' } 1..$k;
    my $cols_str_ins = join ',', @cols;
    my $s = $db->dbh->prepare("insert into $coll ($cols_str_ins) values ($pos_str)" );
    for my $ci ( @{ $p{cis} } ) {
        my @values = map { $ci->{$_} // '' } @cols;
        $s->execute( @values );
    }
}

sub service_list {
    my ($self)=@_;
    my @services;
    for my $reg_node ( _array( Baseliner::Core::Registry->module_index->{ ref($self) || $self } ) ) {
        my $instance = $reg_node->instance;
        next unless ref $instance;
        push @services,
            {
            name  => $instance->name,
            key   => $reg_node->key,
            form  => $instance->form,
            icon  => $instance->icon,
            };
    }
    return @services;
}

sub run_service {
    my ($self_or_class, $key, %p ) = @_;
    _throw 'Missing argument service key' unless $key;
    my $reg = Baseliner->registry->get( $key );
    _log "running container for $key";
    my $stash = {};
    my $config = \%p;
    require Capture::Tiny;
    my ($return_data, $output, $rc); 
    try {
        ($output) = Capture::Tiny::tee_merged( sub{
            $return_data = $reg->run_container( $stash, $config, $self_or_class );
        });
    } catch {
        my $err = shift;
        if( $p{fail} ) {
            _fail _loc "Error running service %1 against ci %2: %3", 
                $key, ( ref $self_or_class ? $self_or_class->mid : $self_or_class ), $err;
        } else {
            $output .= "\n$err";  
        }
    };
    { stash=>$stash, return=>$return_data, output=>$output };  
}

sub variables_like_me {
    my ($class,%p) = @_;

    my @recs = Baseliner::Role::CI->load_from_search({ collection=>'variable' });
    my @vars = map { $class->_build_ci_instance_from_rec($_) } @recs;
    
    my @final;
    if( $class eq 'Baseliner::Role::CI' ) {
        if( my $classname = $p{classname} ) {
            @final = grep { defined $_->var_ci_class && $_->var_ci_class eq $classname } @vars;
        } elsif( my $role = $p{role} ) {
            my $cn = Util->to_role_class($role);
            if( $cn->can('meta') ) {
                my %consumers = map { $_=>1 } $cn->meta->consumers; 
                @final = grep {
                    defined $_->var_ci_role
                        && ( $_->var_ci_role eq $role 
                            || $consumers{ Util->to_ci_class($_->var_ci_class) }
                            || $consumers{ Util->to_role_class( $_->var_ci_role ) } )
                } @vars;
            }
        } else {
            @final = @vars;
        }
    } else {
        my $cn = $class->class_short_name; 
        #filter roles
        my %roles = map { Util->_strip_last( '::', $_->name ) => 1 } $class->meta->calculate_all_roles_with_inheritance;
        @vars = grep { defined $_->var_ci_role && $roles{ $_->var_ci_role } } @vars;
        
        # filter class
        for my $var ( @vars ) {
            my $var_class = $var->var_ci_class;
            if( !defined $var_class ) {
                push @final, $var;
            }
            elsif( $var_class eq $cn ) {
                push @final, $var;
            }
        }
    }
    return @final;
}

=head2 all_cis

Returns all CIs of a given role class:

    my @natures = Baseliner::Role::Nature->all_cis;
    $natures[0]->scan;

=cut
sub all_cis {
    my ($class,%p) = @_;
    $class = $p{class} // ( ref $class || $class );
    $class = 'BaselinerX::CI::' . $class unless $class =~ /::/;
    my @cis;
    for my $pkg ( Util->packages_that_do( $class ) ) {
        my $coll = $pkg->collection;
        DB->BaliMaster->search({ collection=>$coll })->each( sub {
            my ($row)=@_;
            Util->_log( $row->mid );
            push @cis, ci->new( $row->mid );
        });
    }
    return @cis;
}


# TODO consider returning a collection for ci->[collection] ? 
sub find {
    my ($self,$where,@rest) = @_;
    $where //= {};
    if( ref($where) ne 'HASH' && length $where ) {  
        $where = { mid=>mdb->in($where) };
    }
    $where->{collection} //= $self->collection;
    return mdb->master_doc->find($where,@rest);
}

sub find_one {
    my ($self,$where,@rest) = @_;
    $where //= {};
    if( ref($where) ne 'HASH' && length $where ) {
        $where = { mid=>mdb->in($where) };
    }
    $where->{collection} //= $self->collection;
    return mdb->master_doc->find_one($where,@rest);
}

sub search_ci {
    my ($class,%p) = @_;
    $p{_ci_search_one} = 1;
    $class->search_cis( %p );
}

sub search_cis {
    my ($class,%p) = @_;
    my $search_one = delete $p{_ci_search_one};
    $class = $p{class} // $class;
    $class = 'BaselinerX::CI::' . $class unless $class =~ /::/ || ref $class;
    my $coll = $class->collection;
    my $rs = mdb->master_doc->find({ collection=>$coll, %p })->fields({ mid=>1 })->sort({ _id=>1 });
    if( $search_one ) {
        my $doc = $rs->next; 
        return undef if !$doc;
        return ci->new( $doc->{mid} );
    } else {
        my @cis = map { ci->new( $_->{mid} ) } $rs->all;
        return @cis;
    }
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
    my $obj = $gscope->{$val};
    if( defined $obj ) {
        $_[1] = 1;
        return $obj;
    } else {
        $_[1] = 0;
        return ci->new( $val );
    }
};

around initialize_instance_slot => sub {
    my ($orig, $self) = (shift,shift);
    my ($meta_instance, $instance, $params) = @_;

    my $init_arg = $self->init_arg();
    $gscope or local $gscope = {};
    my $mid = $instance->mid // $params->{mid};
    my $weaken = 0;
    if( defined($init_arg) and exists $params->{$init_arg} ) {
        $gscope->{ $mid } //= $instance if defined $mid;
        my $val = $params->{$init_arg};
        my $tc = $self->type_constraint;
        # needs coersion?
        if( ! $tc->check( $val ) ) {
            # CIs
            if( $tc->is_a_type_of('ArrayRef') ) {
                match_on_type $val => (
                    'Undef' => sub {
                        $params->{$init_arg} = [ BaselinerX::CI::Empty->new ];
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
                    # => sub { _fail 'not found...' } 
                );
            }
            # CI
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
                        $params->{$init_arg} = $init->( $val->[0], $weaken );
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

# CIs
package Baseliner::Role::CI::TraitCIs;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Scalar::Util; # 'looks_like_number', 'weaken';

with 'Baseliner::Role::CI::TraitCI';

Moose::Util::meta_attribute_alias('CIs');

1;
