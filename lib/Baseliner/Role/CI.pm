package Baseliner::Role::CI;
use Moose::Role;
use v5.10;

use Try::Tiny;
require Baseliner::CI;
use Baseliner::Utils qw(_throw _fail _loc _warn _log _debug _unique _array _load _dump _package_is_loaded _any);
use Baseliner::Sugar;
use Data::Compare ();
use experimental 'autoderef';

has mid      => qw(is rw isa Str);
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


before save_data => sub {
    my ($self, $master_row, $data ) = @_;

    my $class = ref $self;
    if ( _array($self->unique_keys) ) {
        for my $key ( _array($self->unique_keys) ) {
            my %where = map { $_ => $self->$_ } _array($key);
            my @cis = $class->find({ mid => { '$ne' => $self->mid}, %where })->all;
            if ( @cis ) {
                _fail _loc("Trying to duplicate key: %1", "['".join("','", _array($key))."']");
            }
        }
    }
};

# i.e.['name'] or ['moniker'] or ['name','moniker']
sub unique_keys {
    []
}
sub storage { 'yaml' }   # ie. yaml, deprecated: for now, no other method supported

# methods 
sub has_bl { 1 } 
sub has_description { 1 } 
sub icon_class { '/static/images/icons/class.gif' }
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

sub as_hash {
    %{ shift->serialize };
}

# sets several attributes at once, like DBIC
#   the ci must exist (self=ref)


sub compare_data{
    my ($self,%p) = @_;
    try{
         return Data::Compare::Compare($p{data1}, $p{data2});
    }catch{
        try{
            return Data::Compare::Compare($p{data1}, $p{data2}+0);
        }catch{
            return Data::Compare::Compare($p{data1}, $p{data2}+'');
        }
    };
}

sub update {
    my $self = shift;
    my %data = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_; 
    my $class = ref $self || _fail _loc 'CI must exist for update to work';
    
    # detect changed fields, in case it's a new row then all data is changed
    # TODO there's contaminated data coming thru from project variables
    my $changed = +{ map { $_ => $data{$_} } grep { 
        ( defined $self->{$_} && !defined $data{$_} ) 
        || ( !defined $self->{$_} && defined $data{$_} ) 
        || !$self->compare_data(data1=>$self->{$_}, data2=>$data{$_})
        } keys %data } ;
        
    # merge and recreate object
    my $d = { %$self, %data };  
    # update database only:
    my $saved_obj =  $class->new( $d );
    $saved_obj->save( changed=>$changed );
    # update live attributes
    $self->$_( $saved_obj->$_ ) for grep { $self->can($_) } keys %data; 
}

sub save {
    my ($self,%opts) = @_;

    my $collection = $self->collection;

    my $mid = $self->mid;
    my $bl = $self->bl;
    $bl = '*' if !length $bl; # fix empty submits from web
    # make sure we have a mid AND it's in mongo
    Util->_fail( Util->_loc('CI mid cannot start with `name:` nor `mid:`') ) if $mid && $mid=~/^(name|moniker):/;
    my $master_row;
    $master_row = mdb->master->find_one({ mid=>"$mid" }) if length $mid;
    my $master_old;
    my $exists = length($mid) && $master_row; 
    
    # try to get mid from ns
    my $ns = $self->ns;
    if( !$exists && length $ns && $ns ne '/' ) {
        my $ns_row = mdb->master->find_one({ collection=>$collection, ns=>$ns }, { mid=>1 });
        if( $ns_row ) {
            $mid = $ns_row->{mid};
            $exists = 1;
        }
    }

    cache->remove({ d=>'ci' });
    cache->remove({ mid=>$mid }) if length $mid;
    
    # TODO make it mongo transaction bound, in case there are foreign tables
    if( $exists ) { 
        ######## UPDATE CI
        if( $master_row ) {
            my $username = 'clarive';
            try { $username = $self->modified_by };
            event_new 'event.ci.update' => { username => $username, mid => $mid, new_ci => $self} => sub {
                my $old_ci = Util->_clone($self);
                $master_old = +{ %$master_row };
                $master_row->{bl} = join ',', Util->_array( $bl );
                $master_row->{name} = $self->name;
                $master_row->{active} = $self->active;
                $master_row->{versionid} = $self->versionid || '1';
                $master_row->{moniker} = $self->moniker;
                $master_row->{ns} = $self->ns;
                $master_row->{ts} = mdb->ts;
                my $ci = $self->update_ci( $master_row, undef, \%opts, $master_old );
                delete $ci->{yaml};
                $ci;
            };
        }
    } else {


        event_new 'event.ci.create' => { username => $self->created_by, ci => $self} => sub {

            ######## NEW CI
            $master_row = {
                    collection => $collection,
                    name       => $self->name,
                    ns         => $self->ns,
                    ts         => mdb->ts,
                    moniker    => $self->moniker, 
                    bl         => join( ',', Util->_array( $bl ) ),
                    active     => $self->active // 1,
                    versionid  => $self->versionid || 1,
            };
            # update mid into CI
            $mid = length($mid) ? $mid : mdb->seq('mid');
            $self->mid( $mid );
            $$master_row{mid} = $mid;
            # put a default name
            if( !length $self->name ) {
                my $name = $collection . ':' . $mid;
                $$master_row{name} = $name;
                $self->name( $name );
            }
            
            # now save the rest of the ci data (yaml)
            $self->new_ci( $master_row, undef, \%opts );
            { mid => $mid, username => $self->created_by };
        };
    }
    return $mid; 
}

sub delete {
    my ( $self, $mid ) = @_;
    
    $mid //= $self->mid;
    if( $mid ) {
        my $ci = mdb->master->find_one({'mid' => $mid});
        return 0 unless $ci;

        my $username = 'clarive';
        try {
            $username = $self->modified_by;
        }
        catch {
            Util->_error("Problem here");
        };

        event_new 'event.ci.delete' => { username => $username, ci => $self} => sub {
            # first relations, so nobody can find me
            mdb->master_rel->remove({ '$or'=>[{from_mid=>"$mid"},{to_mid=>"$mid"}] },{multiple=>1});
            mdb->master_doc->remove({ mid=>"$mid" },{multiple=>1});
            mdb->master->remove({ mid=>"$mid" },{multiple=>1});
            cache->remove({ d=>'ci' });
            delete $self->{mid} if ref $self;  # delete the mid value, in case a reuse is in place
        };
        return 1;
    } else {
        return 0;
    }
}

# hook
sub update_ci {
    my ( $self, $master_row, $master_doc, $opts, $master_old ) = @_;
    # if no data=> supplied, save myself
    $opts //= {}; # maybe lost during bad arounds
    $opts->{save_type} = 'update';
    $master_doc = $self->serialize if !ref($master_doc) eq 'HASH' || !keys %$master_doc;
    $self->save_data( $master_row, $master_doc, $opts, $master_old );
}

sub new_ci {
    my ( $self, $master_row, $master_doc, $opts ) = @_;
    # if no data=> supplied, save myself
    $opts //= {}; # maybe lost during bad arounds
    $opts->{save_type} = 'new';
    $master_doc = $self->serialize if !ref($master_doc) eq 'HASH' || !keys %$master_doc;
    $self->save_data( $master_row, $master_doc, $opts);
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
    my ( $self, $master_row, $master_doc, $opts, $master_old ) = @_;
    return unless ref $master_doc;
    
    # To fix not saving attributes modified in "before save_data"
    #$master_doc = { %$self, %$master_doc };

    my $storage = $self->storage;
    # peek into if we need to store the relationship
    my @master_rel;
    my $meta = $self->meta;
    for my $field ( keys %$master_doc ) {
        if( my $type = $self->field_is_ci($field,$meta) ) { 
            my $rel_type = $self->rel_type->{ $field } or Util->_fail( Util->_loc( "Missing rel_type definition for %1 (class %2)", $field, ref $self || $self ) );
            next unless $rel_type;
            my $v = delete($master_doc->{$field});  # consider a split on ,  
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
            $master_doc->{ $attr_name } = 0 unless exists $master_doc->{ $attr_name };
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
        my $mr_where ={ $my_rel=>''.$master_row->{mid}, rel_type=>$rel_type_name };
        mdb->master_rel->remove($mr_where,{ multiple=>1 });
        for my $other_mid ( _array $rel->{value} ) {
            $other_mid = $other_mid->mid if ref( $other_mid ) =~ /^BaselinerX::CI::/;
            next unless $other_mid;
            my $rdoc = { $my_rel => $master_row->{mid}, $other_rel => $other_mid, rel_type=>$rel_type_name, rel_field=>$rel->{field} };
            mdb->master_rel->find_or_create($rdoc);
            push @{$relations{ $rel->{field} }}, $other_mid;
            cache->remove({ mid=>$other_mid });
        }
    }
    # now store the data
    if( $storage eq 'yaml' ) {
        $self->save_fields( $master_row, $master_doc, undef, \%relations );
    } else {
        # temporary: multi-storage deprecated
        Util->_fail( Util->_loc('CI Storage method not supported: %1', $storage) );
    }
    return $master_row;
}

sub save_fields {
    my ($self, $master_row, $master_doc, $opts, $relations ) = @_;
    $opts //={};
    $opts->{master_only} //= 1;
    my $mid = $master_row->{mid};
    delete $master_row->{_id}; # $set fails if _id is in hash
    my $yaml = Util->_dump($master_doc);
    # update mongo master
    mdb->master->update({ mid=>"$mid" }, { '$set'=>{ %$master_row, yaml=>$yaml } }, { upsert=>1, safe=>1 });
    # update master_doc
    if( my $row = mdb->master_doc->find_one({ mid=>"$mid" }) ) {
        my $id = $row->{_id};
        my $doc = { ( $master_row ? %$master_row : () ), %$row, %{ $master_doc || {} } };
        my $final_doc = Util->_clone($doc);
        Util->_unbless($final_doc);
        mdb->clean_doc($final_doc);
        $final_doc->{_id} = $id;  # preserve OID object
        $final_doc->{_sort} = {name=>lc $self->name};
        mdb->master_doc->save({ %$final_doc, %{ $relations || {} } },{ safe=>1 });
    } else {
        my $doc = { ( $master_row ? %$master_row : () ), %{ $master_doc || {} }, mid=>"$mid" };
        delete $doc->{yaml};
        my $final_doc = Util->_clone($doc);
        Util->_unbless($final_doc);
        mdb->clean_doc($final_doc);
        $final_doc->{_sort} = {name=>lc $self->name};
        mdb->master_doc->insert({ %$final_doc, %{ $relations || {} } },{ safe=>1 });
    }
    return $yaml;
}

sub load {
    my ( $self, $mid, $row, $data, $yaml, $rel_data ) = @_;
    $mid ||= $self->mid if $self->can('mid');
    _fail _loc( "Missing mid %1", $mid ) unless length $mid;
    # in scope ? 
    my $scoped = $Baseliner::CI::mid_scope->{ $mid } if $Baseliner::CI::mid_scope;
    #say STDERR "----> SCOPE $mid =" . join( ', ', keys( $Baseliner::CI::mid_scope // {}) ) if $Baseliner::CI::mid_scope && Clarive->debug;
    return $scoped if $scoped;
    # in cache ?
    my $cache_key = { d=>'ci', mid=>"$mid" }; #"ci:$mid:";
    my $cached = cache->get( $cache_key );
    return $cached if $cached;

    if( !$data ) {
        $row //= mdb->master->find_one({ mid=> "$mid" });
        if( ! ref $row ) {
            mdb->master_doc->remove({ mid=>"$mid" },{ multiple=>1 });
            _fail _loc( "Master row not found for mid %1", $mid );
        }
        # setup the base data from master row
        $data = $row; 
    }

    # find class, so that we are subclassed correctly
    my $coll = $data->{collection};
    my $class = "BaselinerX::CI::" . $coll;
    # fix static generic calling from Baseliner::CI
    $self = $class if $self eq 'Baseliner::Role::CI';
    # check class is available, otherwise use a dummy ci class
    if( ! try { Clarive->load_class( $class ) } ) {
        if( $Baseliner::CI::use_empty_ci ) {
            $self = $class = 'BaselinerX::CI::Empty';
        } else {
            _fail(_loc("Could not load CI class `%1`. Maybe check if any plugins/features are missing?", $coll) ); 
        }
    }
    
    # grab the returned data, in case someone did an 'around' and returned it, otherwise == addr $data
    my $final_data = $self->load_data( $mid, $data, $class, $yaml, $rel_data );
    $Baseliner::CI::mid_scope->{ "$mid" } = $final_data if $Baseliner::CI::mid_scope;
    cache->set($cache_key, $final_data);
    return $final_data;
}

# load_data($mid,$data) is perfect for after, around, before intercepts in a CI class
#   you can also use around BUILDARGS => sub{} for the next level of instantiation
sub load_data {
    my ($self,$mid,$data,$class,$yaml,$rel_data) = @_;
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
        $y //= {};
        $data->{$_} = $y->{$_} for keys %$y; # TODO yaml should be blessed obj?
    }
    else {  
        Util->_fail( Util->_loc('CI Storage method not supported: %1', $storage) );
    }
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
                    : mdb->master_rel
                        ->find({ '$or'=>[{ to_mid=>"$mid" },{ from_mid=>"$mid" }], rel_type =>mdb->in(@fields) })
                        ->fields({ from_mid=>1,to_mid=>1,rel_type=>1 })->all;
                    
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
    return $data;
}

sub load_from_search {
    my ($class, $where, %p ) = @_;
    my @rows = mdb->master->find( $where )->all;
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
    my @rows = mdb->master->find({ mid=>mdb->in(@mids) })->all;
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
    my $obj = try {
        $ci_class->new( $rec )
    } catch { 
        my $err = shift;
        Util->_error( "MID=$rec->{mid} rec=" . _dump( $rec ) );
        _fail _loc 'Could not instanciate CI `%1`%2: %3', 
            Util->to_base_class($ci_class), ($rec->{mid} ? " ($rec->{mid})": ''), $err;
    };
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

sub related_mids {
    my ( $self, %opts ) = @_;

    my $mid = $opts{mid};
    $mid // _fail 'Missing parameter `mid`';

    my $opath = delete $opts{path}; # path are all visited cis and may be huge for a cache key
    my $visited = delete $opts{visited}; # visited cis may be huge for a cache key

    my $cache_key = { d=>'ci', mid=>"$mid", a=>'related', b=>\%opts }; #[ "ci:$mid:",  %opts ];
    if( my $cached = cache->get( $cache_key ) ) {
        return @$cached if ref $cached eq 'ARRAY';
    }
    my $depth = $opts{depth} // 1;
    $opts{depth} //= 1;
    $opts{depth_original} //= $depth;
    $opts{mode} //= 'flat';
    $opts{visited} //= {};
    $opts{path} //= $opath // [];
    push @{ $opts{path} }, $mid;
    my @mids_to_visit = _array($mid);
    my @not_visited_mids = ();

    for my $mid_to_visit ( @mids_to_visit ) {
        if (!exists $visited->{$opts{edge}}->{$mid_to_visit}) {
            push @not_visited_mids, $mid_to_visit;
            $visited->{$opts{edge}}->{$mid_to_visit} = 1;
        }
    }
    if ( !@not_visited_mids ) {
        return () ;
    } else {
        $mid = \@not_visited_mids;
    }

    local $Baseliner::CI::_no_record = $opts{no_record} // 1; # make sure we *don't* include a _ci (rgo) 
    $visited->{$opts{edge}}->{ $mid } = 1;
    $opts{visited} = $visited;
    local $Baseliner::ci_unique = {} unless defined $Baseliner::ci_unique;
    
    # get my related cis
    my @cis = $self->related_cis( %opts );
    # unique?
    @cis = grep { !exists $Baseliner::ci_unique->{$_->{mid}} && ($Baseliner::ci_unique->{$_->{mid}}=1) } @cis
        if $opts{unique} ;
    # filter before
    @cis = $self->_filter_cis( %opts, _cis=>\@cis ) if $opts{filter_early};
    # now delve deeper if needed
    $depth --;
    if( $depth<0 || $depth>0 ) {
        my $path = [ _array $opts{path} ];  # need another ref in order to preserve opts{path}

        if( $opts{mode} eq 'tree' ) {
            for my $ci( @cis ) {
                push @{ $ci->{ci_rel} }, $self->related_mids( %opts, mid=>$ci->{mid}, depth=>$depth, path=>$path );
            }
        } else {  # flat mode
            my @mids = map { $_->{mid} } @cis;
            push @cis, 
                $self->related_mids(
                    %opts,
                    mid   => \@mids,
                    depth => $depth,
                    path  => $path
                );
        }
    }
    # filter
    cache->set( $cache_key, \@cis );
    return @cis;
}

sub related_cis {
    my ($self, %opts )=@_;
    my $mid = $opts{mid};
    $mid // _fail 'Missing parameter `mid`';
    # in scope ? 
    #local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;
    my $scope_key =  "related_cis:$mid:" . Storable::freeze( \%opts );
    my $scoped = $Baseliner::CI::mid_scope->{ $scope_key } if $Baseliner::CI::mid_scope;
    return @$scoped if $scoped;
    # in cache ?
    delete $opts{path};  # path are all visited cis and may be huge for a cache key
    my $cache_key = { d=>'ci', mid=>"$mid", a=>'related_cis', b=>\%opts }; #[ "ci:$mid:", \%opts ];
    if( my $cached = cache->get( $cache_key ) ) {
        return @$cached if ref $cached eq 'ARRAY';
    }
    my $where_mid;
    my $where = {};

    if ( ref $mid ) {
        $where_mid = mdb->in($mid);
    } else {
        $where_mid = ''. $mid;
    }
    my @ands;
    my $edge = $opts{edge} // '';
    if( $edge ) {
        my $dir_normal = $edge =~ /^out/ ? 'to_mid' : 'from_mid';
        my $dir_reverse = $edge =~ /^out/ ? 'from_mid' : 'to_mid';
        $where->{$dir_reverse} = $where_mid;
    } else {
        push @ands, { '$or'=> [ {from_mid=>$where_mid}, {to_mid=>$where_mid} ] };
    }

    $where->{rel_type} = mdb->in($opts{rel_type}) if defined $opts{rel_type};
    $where->{'$and'} = \@ands if @ands;

    ######### rel query
    #_warn $where;
    my $rs = mdb->master_rel->find( $where );
    ########
    if( $opts{order_by} ) {
        Util->_error( "ORDER_BY IGNORED: " . _dump( $opts{order_by} ) );   
        Util->_error( Util->_whereami() );
    }

    my @data = $rs->all;
    local $Baseliner::CI::no_rels = 1 if $opts{no_rels};
    my $rel_edge = $edge =~ /^out/
        ? 'child'
        : 'parent';

    my @ret = map {
        my $rel_mid = $rel_edge eq 'child'
            ? $_->{to_mid}
            : $_->{from_mid}; 
        my $ci;
        $ci = { mid => $rel_mid };

        # adhoc ci data with relationship info
        if( $Baseliner::CI::_edge ) {
            $ci->{_edge} = { rel=>$rel_edge, rel_type=>$_->{rel_type}, mid=>$mid, depth=>$opts{depth_original}-$opts{depth}, path=>$opts{path} };
        }
        $ci;
    } @data;
    $Baseliner::CI::mid_scope->{ $scope_key } = \@ret if $Baseliner::CI::mid_scope;
    cache->set( $cache_key, \@ret );
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

    my @edges;

    #Decide if execute in, out or both
    if ( exists $opts{edge} ) {
        @edges = ($opts{edge})
    } else {
        @edges = ( 'in', 'out');
    }

    my @cis;

    for my $edge ( @edges ){
        $opts{edge} = $edge;
        push @cis, $self_or_class->related_mids( %opts, mid => $mid );
    }

    my @ands = ( { mid => mdb->in(map{$_->{mid}} @cis)} );

    if( $opts{where} ) {
        push @ands, $opts{where};
    } 

    # paging support
    $opts{start} //= 0;
    $opts{limit} //= 0; # causes normal stuff to miss relationships

    my $rs = mdb->master_doc->find( {'$and' => \@ands} )->fields( $opts{fields} || {});

    $rs->skip( $opts{start} ) if $opts{start} > 0;
    $rs->limit( $opts{limit} ) if $opts{limit} > 0;
    $rs->sort( $opts{sort} ) if ref $opts{sort};

    @cis = $rs->all;
    
    if ( $opts{mids_only} ) {
        @cis = map { +{ mid => $_->{mid} } } @cis;
    } elsif ( !$opts{docs_only} ) {
         @cis = map { ci->new($_->{mid}) } @cis;
         @cis = $self_or_class->_filter_cis( %opts, _cis=>\@cis ) unless $opts{filter_early};
    }
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

=head2 list_by_name

Returns instanciated cis of this same
class.

=cut
sub list_by_name {
    my ($class, $p)=@_;
    $class = ref $class if ref $class;
    my $where = { collection=>Util->to_base_class($class) };
    $where->{name} = mdb->in($p->{names}) if defined $p->{names};
    my $from = {};
    my $limit = $p->{limit} // $p->{rows};
    $from->{limit} = $limit if defined $limit;
    return [ map { ci->new( $_->{mid} ) } mdb->master->query($where, $from)->fields({ mid=>1 })->all ];
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
            ($classname) = _array($classname) if ref $classname;
            @final = grep { defined $_->var_ci_class && $_->var_ci_class eq $classname } @vars;
        } elsif( my $roles = $p{role} ) {
            for my $role ( _array( $roles ) ) {
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
            }
            @final = _unique( @final );
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
        push @cis, map { ci->new( $_->{mid} ) } mdb->master->find({ collection=>$coll })->fields({ mid=>1 })->all;
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

sub aggregate {
    my ($self,$where) = @_;
    $where //= [];
    unshift $where => { '$match'=>{ collection=>$self->collection } }; 
    return mdb->master_doc->aggregate($where);
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
    my $sort = $p{sort} // "_id";
    delete $p{sort};
    $class = $p{class} // $class;
    $class = 'BaselinerX::CI::' . $class unless $class =~ /::/ || ref $class;
    my $coll = $class->collection;
    my $rs = mdb->master_doc->find({ collection=>$coll, %p })->fields({ mid=>1 })->sort({ $sort=>1 });
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
