package Baseliner::Role::CI;
use Moose::Role;
use v5.10;

use Moose::Util::TypeConstraints;
use Try::Tiny;
require Baseliner::CI;

subtype CI    => as 'Baseliner::Role::CI';
subtype CIs   => as 'ArrayRef[CI]';
subtype BoolCheckbox   => as 'Bool';
subtype HashJSON       => as 'HashRef';
subtype TS    => as 'Str';
subtype DT    => as 'DateTime';

coerce 'TS' => 
    from 'DT' => via { Class::Date->new( $_->set_time_zone( Util->_tz ) )->string },
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
has active   => qw(is rw isa Bool);
has ts       => qw(is rw isa TS coerce 1), default => sub { Class::Date->now->string };
#has _ci      => qw(is rw isa Any);          # the original DB record returned by load() XXX conflicts with Utils::_ci

requires 'icon';
#sub icon { '/static/images/icons/ci.png' }

has name        => qw(is rw isa Maybe[Str]);
has bl          => qw(is rw isa Maybe[Str] default *);
has description => qw(is rw isa Maybe[Str]);
has ns          => qw(is rw isa Maybe[Str]);
has versionid   => qw(is rw isa Maybe[Str] default 1);
has moniker     => qw(is rw isa Maybe[Str]);    # lazy 1);#,
    # default=>sub{   
    #     my $self = shift; 
    #     if( ref $self ) {
    #         my $nid = Util->_name_to_id( $self->name );
    #         return $nid;
    #     }
    # };  # a short name for this
has job     => qw(is rw isa Baseliner::Role::JobRunner),
        lazy    => 1, default => sub {
            require Baseliner::Core::JobRunner;
            Baseliner::Core::JobRunner->new;
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

sub collection {
    my $self = shift;
    ref $self and $self = ref $self;
    my ($collection) = $self =~ /^BaselinerX::CI::(.+?)$/;
    $collection =~ s{::}{/}g;
    return $collection;
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
sub update {
    my ($self, %data ) = @_;
    for my $key ( keys %data ) {
        if( $self->can( $key ) ) {
            $self->$key( $data{ $key });
        } else {
            $self->{$key} = $data{ $key };
        }
    }
}

sub save {
    use Baseliner::Utils;
    use Baseliner::Sugar;
    my $self = shift;
    #my %p;
    #if( ref $_[0] eq 'HASH' ) {
    #    %p = %{ $_[0] };
    #} else {
    #    %p = @_;
    #}
    
    # merge self with current values, ignore underscore
    #my ($mid,$name,$data,$bl,$active,$versionid,$ns,$moniker) = @{\%p}{qw/mid name data bl active versionid ns moniker/};

    my $collection = $self->collection;

    my $mid = $self->mid;
    my $exists = !! $mid;
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
    
    # transaction bound, in case there are foreign tables
    Baseliner->model('Baseliner')->txn_do(sub{
        my $row;
        if( $exists ) { 
            ######## UPDATE CI
            $row = Baseliner->model('Baseliner::BaliMaster')->find( $mid );
            if( $row ) {
                $row->bl( join ',', $self->bl );
                $row->name( $self->name );
                $row->active( $self->active );
                $row->versionid( $self->versionid );
                $row->moniker( $self->moniker );
                $row->ns( $self->ns );
                $row->ts( Util->_dt );
                $row->update;  # save bali_master data
                
                $self->update_ci( $row );
            }
            else {
                _fail _loc "Could not find master row for mid %1", $mid;
            }
            if( ref $self ) {
                $self->mid( $mid );
            }
        } else {
            ######## NEW CI
            $row = Baseliner->model('Baseliner::BaliMaster')->create(
                {
                    collection => $collection,
                    name       => $self->name,
                    ns         => $self->ns,
                    ts         => Util->_dt,
                    moniker    => $self->moniker,
                    bl         => join( ',', Util->_array( $self->bl ) ),
                    active     => $self->active // 1,
                    versionid  => $self->versionid // 1
                }
            );
            # update mid into CI
            $mid = $row->mid;
            $self->mid( $row->mid );
            # name, just in case
            if( ! length $self->name ) {
                $row->name( "${collection}:${mid}" );
            }
            
            # now save the rest of the ci data (yaml)
            $self->new_ci( $row );
        }
        # now index for searches  XXX this should be handled by the inner_save data, which should use mdb->save instead 
        #$self->index_search_data( mid=>$mid, row=>$row, data=>$data) unless $p{no_index};
    });
    return $mid; 
}

sub delete {
    my ( $self, $mid ) = @_;
    
    $mid //= $self->mid;
    if( $mid ) {
        my $row = DB->BaliMaster->find( $mid );
        if( $row ) {
            Baseliner->cache_remove( qr/^ci:/ );
            return $row->delete;
        } else {
            Util->_fail( Util->_loc( 'Could not delete, master row %1 not found', $mid ) );
        }
    } else {
        return undef;
    }
}

# hook
sub update_ci {
    my ( $self, $master_row, $data ) = @_;
    # if no data=> supplied, save myself
    $data = $self->serialize if !defined $data;
    $self->save_data( $master_row, $data );
}

sub new_ci {
    my ( $self, $master_row, $data ) = @_;
    # if no data=> supplied, save myself
    $data = $self->serialize if !defined $data;
    $self->save_data( $master_row, $data );
}

# save data to yaml and mdb, does not use self
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
        if( $type eq 'CI' || $type eq 'CIs' || $type =~ /^Baseliner::Role::CI/ ) {
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
        if( $attr->type_constraint->name eq 'BoolCheckbox' ) {
            my $attr_name = $attr->name;
            # fix the on versus nothing on form submit
            $data->{ $attr_name } = 0 unless exists $data->{ $attr_name };
        }
    }
    # now store the data
    if( $storage eq 'yaml' ) {
        $self->save_fields( $master_row, $data );
    } else {
        # temporary: multi-storage deprecated
        Util->_fail( Util->_loc('CI Storage method not supported: %1', $storage) );
    }
    # master_rel relationships, if any
    for my $rel ( @master_rel ) {
        # delete previous relationships
        my $my_rel = $rel->{rel_type}->[0];
        my $other_rel = $my_rel eq 'from_mid' ? 'to_mid' : 'from_mid';
        my $rel_type_name = $rel->{rel_type}->[1];
        DB->BaliMasterRel->search({ $my_rel, $master_row->mid, rel_type=>$rel_type_name })->delete;
        for my $other_mid ( _array $rel->{value} ) {
            $other_mid = $other_mid->mid if ref( $other_mid ) =~ /^BaselinerX::CI::/;
            next unless $other_mid;
            DB->BaliMasterRel->find_or_create({ $my_rel => $master_row->mid, $other_rel => $other_mid, rel_type=>$rel_type_name, rel_field=>$rel_type_name });
            Baseliner->cache_remove( qr/:$other_mid:/ );
        }
    }
    return $master_row;
}

sub save_fields {
    my $self = shift;
    mdb->save( @_ );
}

sub load {
    use Baseliner::Utils;
    my ( $self, $mid, $row, $data, $yaml ) = @_;
    $mid ||= $self->mid;
    _fail _loc( "Missing mid %1", $mid ) unless length $mid;
    # in scope ? 
    my $scoped = $Baseliner::CI::mid_scope->{ $mid } if $Baseliner::CI::mid_scope;
    #say STDERR "----> SCOPE $mid =" . join( ', ', keys( $Baseliner::CI::mid_scope ) );
    return $scoped if $scoped;
    # in cache ?
    my $cache_key = "ci:$mid:";
    my $cached = Baseliner->cache_get( $cache_key );
    return $cached if $cached;

    if( !$data ) {
        $row //= Baseliner->model('Baseliner::BaliMaster')->find( $mid );
        _fail _loc( "Master row not found for mid %1", $mid ) unless ref $row;
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
        my $y = 
            try { _load( $data->{yaml}) }
            catch {
                my $err = shift;
                Util->_error( Util->_loc( "Error deserializing CI: %1", $err ) );
                +{};
            };
        $data = { %$data, %{ ref $y ? $y : {} } };
    }
    else {  # dbic result source
        Util->_fail( Util->_loc('CI Storage method not supported: %1', $storage) );
    }
    # load post-data and merge
    $data = { %$data, %{ $self->load_post_data($mid, $data) || {} } };
    # look for relationships
    my $rel_types = $self->rel_type;
    my %field_rel_mids;
    for my $field ( keys %$rel_types ) {
        #my $prev_value = $data->{$field};  # save in case there is no relationship, useful for changed cis
        my $rel_type = $rel_types->{ $field };
        next unless defined $rel_type;
        my $my_mid = $rel_type->[0];
        my $other_mid = $my_mid eq 'to_mid' ? 'from_mid' : 'to_mid';
        $field_rel_mids{ "$rel_type->[1]" } = { field=>$field, my_mid => $my_mid, other_mid => $other_mid, };
        delete $data->{$field}; # delete yaml junk
        #$data->{$field} = $prev_value if defined $prev_value && ! _array( $data->{$field} );
    }
    # get rel data
    if( my @fields = keys %field_rel_mids ) {
        my @rel_type_data = DB->BaliMasterRel->search( 
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
    
    #_log $data;
    $data->{mid} //= $mid;
    $data->{ci_form} //= $self->ci_form if $Baseliner::CI::get_form;
    $data->{ci_class} //= $class;
    $Baseliner::CI::mid_scope->{ "$mid" } = $data if $Baseliner::CI::mid_scope;
    Baseliner->cache_set($cache_key, $data);
    return $data;
}

sub load_pre_data { +{} }
sub load_post_data { +{} }

sub ci_form {
    my ($self) = @_;
    my $component = $self->can('form') ? $self->form : sprintf( "/ci/%s.js", $self->collection );
    my $fullpath = Baseliner->path_to( 'root', $component );
    return -e $fullpath  ? $component : '';
}

sub related_cis {
    my ($self, %opts )=@_;
    my $mid = $self->mid;
    # in scope ? 
    local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;
    my $scope_key =  "related_cis:$mid:" . Storable::freeze( \%opts );
    my $scoped = $Baseliner::CI::mid_scope->{ $scope_key } if $Baseliner::CI::mid_scope;
    return @$scoped if $scoped;
    # in cache ?
    my $cache_key = [ "ci:$mid:", \%opts ];
    if( my $cached = Baseliner->cache_get( $cache_key ) ) {
        return @$cached if ref $cached eq 'ARRAY';
    }
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
    my @data = DB->BaliMasterRel->search( $where, { } )->hashref->all;
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

=cut
sub related {
    my ($self, %opts)=@_;
    my $mid = $self->mid;
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
    local $Baseliner::CI::_no_record = $opts{no_record} // 0; # make sure we include a _ci 
    $opts{visited}{ $mid } = 1;
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
                push @{ $ci->{ci_rel} }, $ci->related( %opts, depth=>$depth, path=>$path );
            }
        } else {  # flat mode
            push @cis, map { $_->related( %opts, depth=>$depth, path=>$path ) } @cis;
        }
    }
    # filter
    @cis = $self->_filter_cis( %opts, _cis=>\@cis ) unless $opts{filter_early};
    Baseliner->cache_set( $cache_key, \@cis );
    return @cis;
}

sub parents {
    my ($self, %opts)=@_;
    local $Baseliner::CI::mid_scope = {} unless defined $Baseliner::CI::mid_scope;
    return $self->related( %opts, edge=>'in' );
}

sub children {
    my ($self, %opts)=@_;
    local $Baseliner::CI::mid_scope = {} unless defined $Baseliner::CI::mid_scope;
    return $self->related( %opts, edge=>'out' );
}

sub list_by_name {
    my ($class, $p)=@_;
    my $where = {};
    $where->{name} = $p->{names} if defined $p->{names};
    my $from = { select=>'mid' };
    $from->{rows} = $p->{rows} if defined $p->{rows};
    [ map { _ci( $_->{mid} )->{_ci} } DB->BaliMaster->search($where, $from)->hashref->all ];
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
        $self->mem_load( db=>$db, cis=>[ map { _ci( $_ ) } _array($p{mid}) ], cols=>\@cols  );
    }
    else {   # full collection, from yaml
        #my @mids = map { $_->{mid} } DB->BaliMaster->search({ collection=>$coll }, { select=>'mid' })->hashref->all;
        #$self->mem_load( db=>$db, cis=>[ map { _ci( $_ ) } @mids ], cols=>\@cols  );
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
            name => $instance->name,
            key  => $reg_node->key,
            icon => $instance->icon,
            };
    }
    return @services;
}

=head2 all_cis

Returns all CIs of a given role class:

    my @natures = Baseliner::Role::Nature->all_cis;
    $natures[0]->scan;

=cut
sub all_cis {
    my ($class,%p) = @_;
    my @cis;
    for my $pkg ( Util->packages_that_do( $class ) ) {
        my $coll = $pkg->collection;
        DB->BaliMaster->search({ collection=>$coll })->each( sub {
            my ($row)=@_;
            Util->_log( $row->mid );
            push @cis, Baseliner::CI->new( $row->mid );
        });
    }
    return @cis;
}

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
