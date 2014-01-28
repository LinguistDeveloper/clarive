package Baseliner::Controller::CI;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

# register 'action.ci.admin' => { name => 'Admin CIs' };
# register 'menu.tools.ci' => {
#     label    => 'CI Viewer',
#     url_comp => '/comp/ci-viewer-tree.js',
#     title    => 'CI Viewer',
#     icon     => '/static/images/ci/ci.png',
#     actions  => ['action.ci.admin']
# };

register 'action.search.ci' => { name => 'Search cis' };

# gridtree - the adjacency list treegrid
sub gridtree : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    $p->{user} = $c->username;
    my ($total, @tree ) = $self->dispatch( $p );
    $c->stash->{json} = { total=>$total, totalCount=>$total, data=>\@tree, success=>\1 };
    $c->forward('View::JSON');
}

# list - used by the west navigator
sub list : Local {
    my ($self, $c) = @_;
    local $Baseliner::CI::get_form = 1;
    my $p = $c->req->params;
    $p->{user} = $c->username;
    my ($total, @tree ) = $self->dispatch( $p );

    @tree = sort { lc $a->{text} cmp lc $b->{text} } map {
        my $n = {};
        $_->{anode} = $_->{_id};
        $n->{leaf} = $_->{type} =~ /role/ ? $_->{_is_leaf} : \1;
        $n->{text} = $_->{item};
        $n->{icon} = $_->{icon};
        #$_->{id} = $_->{_id};
        $n->{url} = '/ci/list';
        $n->{data} = $_;
        $n->{data}{click} = {
            url  => '/ci/grid',
            type => 'comp',
            icon => $_->{icon}
        };
        $n;
    } @tree;

    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub dispatch {
    my ($self, $p) = @_;
    my $parent = $p->{anode};
    my $mid = $p->{mid};
    my $c = $p->{c};
    my $total;
    my @tree;

    if ( !length $p->{anode} && !$p->{type} ) {
        @tree = $self->tree_roles( user => $p->{user} );
    } elsif ( $p->{type} eq 'role' ) {
        @tree = $self->tree_classes( role => $p->{class}, parent => $p->{anode}, user => $p->{user}, role_name => $p->{item} );
    } elsif ( $p->{type} eq 'class' ) {
        ( $total, @tree ) = $self->tree_objects(
            class  => $p->{class},
            classname  => $p->{class},
            parent => $p->{anode},
            start  => $p->{start},
            limit  => $p->{limit},
            pretty => $p->{pretty},
            query  => $p->{query}
        );
    } elsif ( $p->{type} eq 'object' ) {
        @tree = $self->tree_object_info( mid => $p->{mid}, parent => $p->{anode} );
    } elsif ( $p->{type} eq 'depend_from' ) {
        ( $total, @tree ) = $self->tree_object_depend(
            from       => $p->{mid},
            parent     => $p->{anode},
            start      => $p->{start},
            limit      => $p->{limit},
            query      => $p->{query},
            pretty     => $p->{pretty},
            collection => $p->{collection}
        );
    } elsif ( $p->{type} eq 'depend_to' ) {
        ( $total, @tree ) = $self->tree_object_depend(
            to         => $p->{mid},
            parent     => $p->{anode},
            start      => $p->{start},
            limit      => $p->{limit},
            query      => $p->{query},
            pretty     => $p->{pretty},
            collection => $p->{collection}
        );
    } elsif ( $p->{type} eq 'ci_request' ) {
        ( $total, @tree ) = $self->tree_ci_request(
            mid        => $p->{mid},
            parent     => $p->{anode},
            start      => $p->{start},
            limit      => $p->{limit},
            query      => $p->{query},
            pretty     => $p->{pretty},
            collection => $p->{collection}
        );
    }
    
    $total = scalar( @tree ) unless defined $total;
    return ($total,@tree);
}

sub tree_roles {
    my ( $self, %p ) = @_;

    #my $last1 = '2011-11-04 10:49:22';
    #+{ $_->get_columns, _id => $_->mid, _parent => undef, _is_leaf => \1, size => $size }
    my $cnt  = 1;
    my $user = $p{user};
    my @tree;
    map {
        my $role = $_->{role};
        my $name = $_->{name};
        if ( Baseliner->model( 'Permissions' )
            ->user_has_any_action( username => $user, action => 'action.ci.%.' . $name . '.%') )
        {
            $role = 'Generic' if $name eq '';
            push @tree, {
                _id        => $cnt++,
                _parent    => undef,
                _is_leaf   => \0,
                type       => 'role',
                mid        => $cnt,
                item       => $name,
                class      => $role,
                classname  => $role,
                icon       => '/static/images/ci/class.gif',
                versionid  => 1,
                ts         => '-',
                tags       => [],
                properties => undef,

                #children => [], #\@chi
            };
        } ## end if ( Baseliner->model(...))
    } $self->list_roles;
    return @tree;
}

sub tree_classes {
    my ($self, %p)=@_;
    my $role = $p{role};
    my $user = $p{user};
    my $cnt = substr( _nowstamp(), -6 ) . ( $p{parent} * 1 );
    my @tree;
    map {
        my $item       = $_;
        my $collection = $_->collection;
        my $ci_form = $self->form_for_ci( $item, $collection );
        $item =~ s/^BaselinerX::CI:://g;
        my $has_permission = Baseliner->model( 'Permissions' )
            ->user_has_any_action( username => $user, action => 'action.ci.%.' .$p{role_name}.'.'. $item );
        if ( $has_permission )
        {

            $cnt++;
            push @tree, {
                _id      => ++$cnt,
                _parent  => $p{parent} || undef,
                _is_leaf => \0,
                type     => 'class',

                #mid        => $cnt,
                item            => $item,
                collection      => $collection,
                ci_form         => $ci_form,
                class           => $_,
                classname       => $_,
                icon            => $_->icon,
                has_bl          => $_->has_bl,
                has_description => $_->has_description,
                versionid       => '',
                ts              => '-',
                properties      => '',
            };
        } 
    } packages_that_do( $role );
    return @tree; 
}

sub form_for_ci {
    my ($self, $class, $collection )=@_;
    local $Baseliner::CI::get_form = 1;
    my $ci_form = $class && $class->can('ci_form') 
        ? $class->ci_form 
        : sprintf( "/ci/%s.js", $collection );
    my $component_exists = -e Baseliner->path_to( 'root', $ci_form );
    return $component_exists ? $ci_form : '';
}

# adjacency flat tree
sub tree_objects {
    my ($self, %p)=@_;
    my $class = $p{class};
    my $collection = $p{collection};
    my %class_coll;
    if( ! $collection ) {
        if( ref $class eq 'ARRAY' ) {
            $collection = { -in=>[ map { 
                my $coll= $_->can('collection') ? $_->collection : Util->to_base_class($_);
                $class_coll{ $coll } = $_ ; # for later decoding it from a table
                $coll } @$class ] };
        } 
        elsif( $class ) {
            $collection = $class->can('collection') ? $class->collection : Util->to_base_class($class);
            %class_coll = ( $collection => $class );  # for later decoding it from a table
        }
        else {
            # probably just mids, no class or collection
            #  consider creating a %class_coll of all classes
        }
    }
    my $opts = { order_by=>( $p{order_by} // +{ -asc=>['mid'] } ) };
    $opts->{select} = [ grep !/yaml/, DB->BaliMaster->result_source->columns ] if $p{no_yaml}; 
    my $page;
    if( length $p{start} && length $p{limit} && $p{limit}>-1 ) {
        $page =  to_pages( start=>$p{start}, limit=>$p{limit} );
        $opts->{rows} = $p{limit};
        $opts->{page} = $page;
    }
    my $where = {};
    
    if( length $p{query} ) {
        my $filter = {};
        my $q = $p{query};
        $filter->{collection} = $collection if $collection;
        my @mids_query = map { $_->{obj}{mid} } 
            _array( mdb->master_doc->search( query=>$q, limit=>1000, project=>{mid=>1}, filter=>$filter )->{results} );
        push @mids_query, map { $_->{mid} } mdb->master_doc->find({ '$or'=>[ {name=>qr/$q/i}, {moniker=>qr/$q/i} ] })->fields({ mid=>1 })->all;
        $where->{mid}=\@mids_query;
    }
    
    $where->{collection} = $collection if $collection;
    $where = { %$where, %{ $p{where} } } if $p{where};
    
    # search for variables in mids 
    if( defined $p{mids} && length $p{mids} ) {
        my @where_mids;
        for my $m ( _array( $p{mids} ) ) {
            next if $m =~ /^\$\{/;
            push @where_mids, $m;
        }
        if( scalar @where_mids == 1 ) {
            $where->{mid} = $where_mids[0];
        } elsif( @where_mids > 1 ) {
            $where->{mid} = \@where_mids;
        }
    }

    my $rs = Baseliner->model('Baseliner::BaliMaster')->search( $where, $opts );
    my $total = defined $page ? $rs->pager->total_entries : $rs->count;
    my $generic_icon = do { require Baseliner::Role::CI::Generic; Baseliner::Role::CI::Generic->icon() };
    my (%forms, %icons);  # caches
    my @tree = map {
        my $row = $_;
        my $data = $p{no_yaml} ? {} : _load( $row->{yaml} );
        my $row_class = $class_coll{ $row->{collection} };
        # the form may be in cache, otherwise ask the class for a sub form {} formname, otherwise use the collection name
        my $ci_form = $forms{ $row->{collection} } 
            // ( $forms{ $row->{collection} } = $self->form_for_ci( $row_class, $row->{collection} ) );
        
        # list properties: field: value, field: value ...
        my $pretty = $p{pretty} && !$p{no_yaml}
            ?  do { join(', ',map {
                my $d = $data->{$_};
                $d = '**' x length($d) if $_ =~ /password/;
                "$_: $d"
                } grep { length $data->{$_} } keys %$data ) }
            : '';
        my $noname = $row->{collection}.':'.$row->{mid};
        +{
            _id               => $row->{mid},
            _parent           => $p{parent} || undef,
            _is_leaf          => \0,
            mid               => $row->{mid},
            name              => ( $row->{name} // $noname ),
            item              => ( $row->{name} // $data->{name} // $noname ),
            ci_form           => $ci_form,
            type              => 'object',
            class             => $row_class, 
            classname         => $row_class, 
            collection        => $row->{collection},
            moniker           => $row->{moniker},
            icon              => ( $icons{ $row_class } // ( $icons{$row_class} = $row_class ? $row_class->icon : $generic_icon ) ),
            ts                => $row->{ts},
            bl                => $row->{bl},
            description       => $data->{description} // '',
            active            => ( $row->{active} eq 1 ? \1 : \0 ),
            data              => $data,
            properties        => $row->{yaml},
            pretty_properties => $pretty,
            versionid         => $row->{versionid},
        }
    } $rs->hashref->all;
    ( $total, @tree );
}

sub tree_object_depend {
    my ($self, %p)=@_;
    my $class = $p{class};
    my $where = {};
    my $join = { };
    my $page = to_pages( start=>$p{start}, limit=>$p{limit} );
    my $rel_type;
    if( defined $p{from} ) {
        $where->{from_mid} = $p{from};
        $rel_type = 'master_to';
        $join->{prefetch} = [$rel_type];
    }
    elsif( defined $p{to} ) {
        $where->{to_mid} = $p{to};
        $rel_type = 'master_from';
        $join->{prefetch} = [$rel_type];
    }
    my $rs = Baseliner->model('Baseliner::BaliMasterRel')->search(
        $where, { %$join, order_by=>{ -asc=>['mid'] }, rows=>$p{limit}, page=>$page }
    );
    my $total = $rs->pager->total_entries;
    my $cnt = $p{parent} * 10;
    my @tree = map {
        my $class = 'BaselinerX::CI::' . $_->{$rel_type}{collection};
        my $data = _load( $_->{yaml} );
        my $bl = [ split /,/, $_->{bl} ];
        +{
            _id        => ++$cnt,
            _parent    => $p{parent} || undef,
            _is_leaf   => \0,
            mid        => $_->{$rel_type}{mid},
            item       => ( $_->{$rel_type}{name} // $data->{name} // $_->{$rel_type}{collection} ),
            type       => 'object',
            class      => $class,
            classname  => $class,
            bl         => $bl,
            collection => $_->{rel_type},
            icon       => $class->icon,
            ts         => $_->{$rel_type}{ts},
            data       => $data,
            properties => $_->{yaml},
            versionid    => $_->{versionid},
            }
    } $rs->hashref->all;
    ( $total, @tree );
}

sub tree_ci_request {
    my ($self, %p)=@_;
    my $class = $p{class};
    my $where = {};
    my $page = to_pages( start=>$p{start}, limit=>$p{limit} );
    my @rs = DB->BaliTopic->search(
        { from_mid=>$p{mid}, rel_type=>'ci_request' },
        { prefetch=>['parents','status','categories'] },
    )->hashref->all;
    my $total = @rs;
    my $cnt = $p{parent} * 10;
    my @tree = map {
        +{
            _id        => ++$cnt,
            _parent    => $p{parent} || undef,
            _is_leaf   => \1,
            mid        => $_->{mid},
            item       => $_->{categories}{name} . ' #' . $_->{mid},
            title      => $_->{title},
            type       => 'topic',
            class      => 'BaselinerX::CI::topic',
            bl         => $p{bl},
            collection => $_->{status}{name}, 
            icon       => '/static/images/icons/topic_one.png',
            ts         => $_->{master_to}{ts},
            data       => { %{ $_->{categories} } }, 
            properties => '',
            versionid    => '',
        }
    } @rs;
    ( $total, @tree );
}

sub tree_object_info {
    my ($self, %p)=@_;
    my $mid = $p{mid};
    #my $cnt = substr( _nowstamp(), -6 ) . ( $p{parent} * 1 );
    my $cnt = $p{parent} * 10;
    my @tree = (
        {
            _id      => $cnt++,
            _parent  => $p{parent} || undef,
            _is_leaf => \0,
            mid      => $mid,
            item     => _loc('Depends On'), 
            type     => 'depend_from',
            class    => '-',
            classname    => '-',
            icon     => '/static/images/ci/out.png',
            ts       => '-',
            versionid  => '',
        },
        {
            _id      => $cnt++,
            _parent  => $p{parent} || undef,
            _is_leaf => \0,
            mid      => $mid,
            item     => _loc('Depend On Me'), 
            type     => 'depend_to',
            class    => '-',
            classname    => '-',
            icon     => '/static/images/ci/in.png',
            ts       => '-',
            versionid  => '',
        },
        {
            _id      => $cnt++,
            _parent  => $p{parent} || undef,
            _is_leaf => \0,
            mid      => $mid,
            item     => _loc('Requests'), 
            type     => 'ci_request',
            class    => '-',
            classname    => '-',
            icon     => '/static/images/icons/topic.png',
            ts       => '-',
            versionid  => '',
        },
    );
    return @tree;
}

sub list_classes {
    my ($self, $role ) = @_;
    $role //= 'Baseliner::Role::CI';
    map {
        my $pkg = $_;
        ( my $name = $pkg ) =~ s/^BaselinerX::CI:://g;
        +{ classname=>$pkg, name=>$name };
    } packages_that_do( $role );
}

sub list_roles {
    my ($self, %p) = @_;
    $p{name_format} //= 'lc';
    my $name_transform = sub {
        my $name = shift;
        return $name if $p{name_format} eq 'full';
        ($name) = $name =~ /^.*::CI::(.*)$/;
        return length($name) ? $name : 'CI' if $p{name_format} eq 'short';
        $name =~ s{::}{}g if $name;
        $name =~ s{([a-z])([A-Z])}{$1_$2}g if $name; 
        my $return = $name || 'ci';
        return lc $return;
    };
    my %cl=Class::MOP::get_all_metaclasses;
    map {
        my $role = $_;
        +{
            role => $role,
            name => $name_transform->( $role ),
        }
    } grep /^Baseliner::Role::CI/, keys %cl;
}

sub classes : Local {
    my ($self, $c) = @_;
    my @classes = sort { $a->{name} cmp $b->{name} } $self->list_classes;
    $c->stash->{json} = { data=>\@classes, totalCount=>scalar(@classes) };
    $c->forward('View::JSON');
}

sub roles : Local {
    my ($self, $c) = @_;
    my $name_format = $c->req->params->{name_format};
    my @roles = sort { $a->{name} cmp $b->{name} } $self->list_roles( name_format=>$name_format );
    $c->stash->{json} = { data=>\@roles, totalCount=>scalar(@roles) };
    $c->forward('View::JSON');
}

# used by Baseliner.store.CI
#   (used in ci forms)

sub store : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    
    # in cache ?
    my $mid_param =  $p->{mid} || $p->{from_mid} || $p->{to_mid} ;
    my $cache_key;
    if( defined $mid_param ) {
        $cache_key = ["ci:store:$mid_param:", $p ];
        if( my $cc = $c->cache_get( $cache_key ) ) {   # not good during testing mode
            #$c->stash->{json} = $cc;
            #return $c->forward('View::JSON');
        }
    }
    
    my $bl = delete $p->{bl};
    my $name = delete $p->{name};
    my $collection = delete $p->{collection};
    my $action = delete $p->{action};
    my $where = {};
    local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;

    if ( defined $mid_param ) {
        my $w = {};
        $w->{from_mid} = $p->{mid} if $p->{mid};
        $w->{from_mid} = $p->{from_mid} if $p->{from_mid};
        $w->{to_mid}   = $p->{to_mid} if $p->{to_mid};
        $w->{rel_type} = $p->{rel_type}  if defined $p->{rel_type};

        my $s = {};
        $s->{select} = 'to_mid' if $p->{mid} || $p->{from_mid};
        $s->{select} = 'from_mid' if $p->{to_mid};
        
        my $rel_query = Baseliner->model('Baseliner::BaliMasterRel')->search( $w , $s )->as_query;
        $where->{mid} = { -in=>$rel_query };
    }

    if( length $bl && $bl ne '*' ) {
        $where->{'-or'} = [ { bl =>{-like => '%'.$bl.'%'} }, { bl=>{-like=>'%*%'}} ];  # XXX XXX XXX  use where exists( select rels from master_rel? )
    }
    
    # used by value in a CIGrid
    my $mids;
    if( exists $p->{mids} ) {
        $mids = delete $p->{mids};
        if( length $mids ) {
            $mids = [ grep { defined } split /,+/, $mids ] unless ref $mids eq 'ARRAY';
        } else {  # no value sent, but key exists
            $mids = [];  # otherwise, it will return all cis
        }
    }
    
    my @data;
    my $total = 0; 

    if( my $class = $p->{class} // $p->{classname} // $p->{isa} ) {
        if( $p->{security} ){  #Parámetro desde informes
            my @security;
            my @cols_roles = $c->model('Permissions')->user_projects_ids_with_collection( username=>$c->username );
            for my $collections ( @cols_roles ) {
                if(exists $collections->{$class}){
                    push @security, keys $collections->{$class};    
                }
            }
            $mids = [ _array($mids), @security];
        }
        
        $class = "BaselinerX::CI::$class" if $class !~ /^Baseliner/;
        ($total, @data) = $self->tree_objects( class=>$class, parent=>0, start=>$p->{start}, limit=>$p->{limit}, order_by=>$p->{order_by}, query=>$p->{query}, where=>$where, mids=>$mids, pretty=>$p->{pretty} , no_yaml=>$p->{with_data}?0:1);
    }
    elsif( my $role = $p->{role} ) {
        my @roles;
        for my $r ( _array $role ) {
            if( $r !~ /^Baseliner/ ) {
                $r = uc($r) eq 'CI' ? "Baseliner::Role::CI" : "Baseliner::Role::CI::$r" ;
            }
            push @roles, $r;
        }
        my $classes = [ packages_that_do( @roles ) ];
        ($total, @data) = $self->tree_objects( class=>$classes, parent=>0, start=>$p->{start}, limit=>$p->{limit}, order_by=>$p->{order_by}, query=>$p->{query}, where=>$where, mids=>$mids, pretty=>$p->{pretty}, no_yaml=>$p->{with_data}?0:1);
    }
    else {
        ($total, @data) = $self->tree_objects( class=>$class, parent=>0, start=>$p->{start}, limit=>$p->{limit}, order_by=>$p->{order_by}, query=>$p->{query}, where=>$where, mids=>$mids, pretty=>$p->{pretty} , no_yaml=>$p->{with_data}?0:1);
        #_fail( 'No class or role supplied' );
    }

    #_debug \@data if $mids;

    # variables
    if( $p->{with_vars} ) {  # $p->{no_vars} ) {  # show variables always, with_vars deprecated
        my %vp = ( $p->{role} ? (role=>$p->{role}) : ($p->{classname} || $p->{class} || $p->{isa}) ? (classname=>$p->{class}||$p->{classname}) : () );
        
        my @vars = Baseliner::Role::CI->variables_like_me( %vp );
        push @data, map { 
            my $cn =  $_->var_ci_class ? 'BaselinerX::CI::'.$_->var_ci_class : $_->description;
            +{
                  _id=> 'var-'. $_->mid,
                  _is_leaf=> \1,
                  _parent=> undef,
                  active=> \1,
                  bl=> $_->bl,
                  class=> $cn, 
                  classname => $cn,
                  collection=> 'variable',
                  data=> {},
                  description=> '',
                  icon=> $_->icon,
                  #item: wtscm1,
                  mid=> '${'.$_->name.'}',
                  moniker=> $_->moniker,
                  name => 'variable: ${' . $_->name . '}',
                  pretty_properties=> '',
                  properties=> undef,
                  ts=>$_->ts, 
                  type=>  'object',
                  versionid=> $_->versionid,
             };
        } @vars;
    }
    
    if( ref $mids ) { 
        # return data ordered like the mids
        my @data_ordered;
        my %h = map { $_->{mid} => $_ } @data;
        push @data_ordered, delete $h{ $_ } for @$mids;
        push @data_ordered, values %h; # the rest of them at the bottom
        @data = @data_ordered; 
    }

    $c->stash->{json} = { data=>\@data, totalCount=>$total };
    $c->cache_set( $cache_key, $c->stash->{json} ) if $cache_key; 
    $c->forward('View::JSON');
}

# used by CIGrid to get dependents
#   

sub children : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my @chi = _ci( $p->{mid} // $p->{from_mid} )->children;
    my @data = map {
        my $d = $_;
        my $edge = delete $_->{_edge};
        my $ci = delete $_->{_ci};
        +{
            mid        =>$d->mid,
            rel_type   =>$edge->{rel_type},
            icon       =>$d->icon,
            class      => ref $d,
            collection => $d->collection,
            depth      => $edge->{depth},
            name       => $d->name,
            versionid  => $d->versionid,
        }
    } @chi;
    $c->stash->{json} = { data=>\@data, totalCount=>scalar @data };
    $c->forward('View::JSON');
}

## adds/updates foreign CIs

sub ci_create_or_update {
    my $self = shift;
    my %p = @_;
    return $p{mid} if length $p{mid};
    my $ns = $p{ns} || delete $p{data}{ns};
    my $class = $p{class};

    _fail _loc( 'Missing class for %1', $p{name} ) if !$class;
    
    # check if it's an update, in case of foreign ci

    if ( length $p{mid} ) {
        my $ci = _ci( $p{mid} );
        $ci->update( %{ $p{data} || {} } );
        $ci->save;
        return $p{mid};
    } else {
        my $name = $p{name};
        my $mid; 
        $class = "BaselinerX::CI::$p{class}";

        my @same_name_cis = DB->BaliMaster->search( {name => $name, collection => $p{collection} // $class->collection } )->hashref->all;

        if ( scalar @same_name_cis > 1 ) {
            for ( @same_name_cis ) {
                if ( _ci( $_->{mid} )->{ci_class} eq $class ) {
                    $mid = $_->{mid};
                    last;
                }
            }
        } elsif ( scalar @same_name_cis == 1 ) {
            $mid = $same_name_cis[ 0 ]->{mid};
        }

        if ( !$mid ) {
            my $d = { name => $name, %{ $p{data} || {} }, created_by=>$p{username} };
            my $ci = $class->new($d);
            return $ci->save;
        } else {
            my $obj = _ci( $mid );
            $obj->update( %{ $p{data} || {} });
            $obj->save;
            return $mid;
        }
    } 
};

=head2 sync

Used when external CIs come with no mid, but with ns.

=cut
sub sync : Local {
    my ($self, $c, $action) = @_;
    my $p = $c->req->params;

    my $collection = delete $p->{collection};
    my $class = delete $p->{class};
    my $name = delete $p->{name};
    my $mid = delete $p->{mid};
    my $ns = delete $p->{ns};
    my $repo_mid = $p->{repo};
    my $valid_repo = 1;

    if ( $p->{topic_mid} ) {
        my @projects = map { $_->{mid} } DB->BaliTopic->find( $p->{topic_mid} )->projects->hashref->all;

        if ( !@projects ) {
            $c->stash->{json} = { success=>\0, msg=>_loc('The changeset must be assigned to at least one project') };
            $valid_repo = 0;
        } else {
            my @repo_projects = map { $_->{mid} } ci->new($repo_mid)->related( isa => 'project');

            my $ok_repo = 0;
            for ( @repo_projects ) {
                if ( $_ ~~ @projects ) {
                    $ok_repo = 1;
                    last;
                }
            }
            if (!$ok_repo) {
                $c->stash->{json} = { success=>\0, msg=>_loc('The revision does not belong to any of the changeset projects' ) };
                $valid_repo = 0;
            }             
        }
    }

    if ( $valid_repo ) {
        my $data = exists $p->{ci_json} ? _from_json( $p->{ci_json} ) : $p;

        try {
            # check for prereq relationships
            my @ci_pre_mid;
            my %ci_data;
            while( my ($k,$v) = each %$data ) {
                if( $k eq 'ci_pre' ) {
                    for my $ci ( _array $v ) {
                        #_log( _dump( $ci ) );
                        push @ci_pre_mid, $self->ci_create_or_update( %$ci, username=>$c->username ) ;
                    }
                }
                elsif( $v =~ /^ci_pre:([0-9]+)$/ ) {
                    my $ix = $1;
                    $ci_data{ $k } = $ci_pre_mid[ $ix ];
                }
                else {
                    $ci_data{ $k } = $v;
                }
            }

            $mid = $self->ci_create_or_update( rel_field => $collection, name=>$name, class=>$class, 
                username=>$c->username, ns=>$ns, collection=>$collection, mid=>$mid, data=>\%ci_data );

            $c->stash->{json} = { success=>\1, msg=>_loc('CI %1 saved ok', $name) };
            $c->stash->{json}{mid} = $mid;
        } catch {
            my $err = shift;
            _log( $err );
            $c->stash->{json} = { success=>\0, msg=>_loc('CI error: %1', $err ) };
        };
    }
    $c->forward('View::JSON');
}

=head2 update

Create or update a CI.

=cut
sub update : Local {
    my ($self, $c, $action) = @_;
    my $p = $c->req->params;
    _debug $p;
    my $form_data = $p->{form_data};
    _fail _loc 'Invalid data format: form data is not hash' unless ref $form_data eq 'HASH';
    # cleanup
    for my $k ( keys %$form_data ) {
        delete $p->{$k} if $k =~ /^ext-comp-/
    }
    # don't store in yaml
    my $name = delete $form_data->{name};
    my $bl = delete $form_data->{bl};
    my $active = $form_data->{active};
    $form_data->{active} = $active = $active eq 'on' ? 1 : 0;
    
    my $mid = delete $p->{mid};
    my $collection = delete $p->{collection};
    $action ||= delete $p->{action};
    my $class = "BaselinerX::CI::$collection";    # XXX what?? fix the class vs. collection mess
    my $chi = delete $form_data->{children};
    delete $form_data->{version}; # form should not set version

    try {
        if( $action eq 'add' ) {
            my $ci = $class->new( name=>$name, bl=>$bl, active=>$active, moniker=>delete($form_data->{moniker}), %$form_data, created_by=>$c->username ); 
            $ci->save;
            $mid = $ci->mid;
            #$mid = $class->save( name=>$name, bl=>$bl, active=>$active, moniker=>delete($form_data->{moniker}), data=> $form_data ); 
        }
        elsif( $action eq 'edit' && defined $mid ) {
            #$c->cache_remove( qr/:$mid:/ );
            #$mid = $class->save( mid=>$mid, name=> $name, bl=>$bl, active=>$active, moniker=>delete($form_data->{moniker}), data => $form_data ); 

            #my $ci = $class->new( mid=>$mid, name=> $name, bl=>$bl, active=>$active, moniker=>delete($form_data->{moniker}), %$form_data, modified_by=>$c->username );
            my $ci = ci->find( $mid ) || _fail _loc 'CI %1 not found', $mid;
            $ci->update( mid=>$mid, name=> $name, bl=>$bl, active=>$active, moniker=>delete($form_data->{moniker}), %$form_data, modified_by=>$c->username );
            
            #my $ci = _ci( $mid );
            #$ci->update( mid=>$mid, name=> $name, bl=>$bl, active=>$active, moniker=>delete($form_data->{moniker}), %$form_data ); 
            #$ci->save;
            $mid = $ci->mid;
        }
        else {
            _fail _loc("Undefined action");
        }
        if( $chi ) {
            my $cis = ref $chi eq 'ARRAY' ? $chi : [ split /,/, $chi ]; 
            DB->BaliMasterRel->search({ from_mid=>$mid })->delete;
            for my $to_mid ( _array( $cis ) ) {
                my $rel_type = $collection . '_' . _ci( $to_mid )->collection;   # XXX consider sending the rel_type from js 
                DB->BaliMasterRel->create({ from_mid=>$mid, to_mid=>$to_mid, rel_type=>$rel_type });
                $c->cache_remove( qr/:$to_mid:/ );
            }
        }
        $c->stash->{json} = { success=>\1, msg=>_loc('CI %1 saved ok', $name) };
        $c->stash->{json}{mid} = $mid;
    } catch {
        my $err = shift;
        _error( $err );
        $c->stash->{json} = { success=>\0, msg=>_loc('CI error: %1', $err ) };
    };

    $c->forward('View::JSON');
}

=head2 load

Load a CI row.

=cut
sub load : Local {
    my ($self, $c, $action) = @_;
    my $p = $c->req->params;
    my $mid = $p->{mid};
    local $Baseliner::CI::get_form = 1;
    my $cache_key;
    if( length $mid ) {
        $cache_key = [ "ci:load:$mid:", $p ];
        if( my $cc = $c->cache_get( $cache_key ) ) {
            $c->stash->{json} = $cc;
            return $c->forward('View::JSON');
        }
    }
    local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;
    try {
        my $obj = Baseliner::CI->new( $mid );
        my $class = ref $obj;
        my $rec = $obj->load;
        Util->_unbless( $rec );
        $rec->{has_bl} = $obj->has_bl;
        $rec->{has_description} = $obj->has_description;
        $rec->{classname} = $rec->{class} = $class;
        $rec->{icon} = $obj->icon;
        $rec->{active} = $rec->{active} ? \1 : \0;
        $rec->{services} = [ $obj->service_list ];
        $c->stash->{json} = { success=>\1, msg=>_loc('CI %1 loaded ok', $mid ), rec=>$rec };
    } catch {
        my $err = shift;
        _error( $err );
        $c->stash->{json} = { success=>\0, msg=>_loc('CI load error: %1', $err ) };
    };
    $c->cache_set( $cache_key, $c->stash->{json} ) if defined $cache_key;
    $c->forward('View::JSON');
}

sub delete : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $mids = delete $p->{mids};

    try {
        $c->cache_clear();
        for( grep { length } _array( $mids ) ) {
            ci->delete( $_ );
        }
        $c->stash->{json} = { success=>\1, msg=>_loc('CIs deleted ok' ) };
        #$c->stash->{json} = { success=>\1, msg=>_loc('CI does not exist' ) };
    } catch {
        my $err = shift;
        _error( $err );
        $c->stash->{json} = { success=>\0, msg=>_loc('Error deleting CIs: %1', $err) };
    };
    $c->forward('View::JSON');
}

sub export : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $mids = delete $p->{mids};
    my $format = $p->{format} || 'yaml';

    try {
        my @cis = map { _ci( $_ ) } _array $mids;
        my $data;
        if( $format eq 'yaml' ) {
            $data = _dump( \@cis );
        }
        elsif( $format eq 'json' ) {
            $data = _encode_json( [ map { _damn( $_ ) } @cis ] );
        }
        else {
            _fail _loc "Unknown export format: %1", $format;
        }
        $c->stash->{json} = { success=>\1, msg=>_loc('CIs exported ok' ), data=>$data };
    } catch {
        my $err = shift;
        _error( $err );
        $c->stash->{json} = { success=>\0, msg=>_loc('Error exporting CIs: %1', $err) };
    };
    $c->forward('View::JSON');
}

sub export_html : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $mids = delete $p->{mids};
    my $format = $p->{format} || 'yaml';

    my @cis = map { _ci( $_ ) } _array $mids;
    $c->stash->{cis} = \@cis;
    $c->stash->{template} = '/comp/ci-data.html';
}

sub url : Local {
    my ($self, $c) = @_;
    my $mid = $c->req->params->{mid};
    $c->stash->{json} = try {
        my $ci = Baseliner::CI->new( $mid );
        { success=>\1, url=>$ci->url, title=>$ci->load->{name} };
    } catch {
        my $err = shift;
        _error( $err );
        { success=>\0, msg=>$err };
    };
    $c->forward('View::JSON');
}

sub json_tree : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $mids = delete $p->{mid} || delete $p->{mids};
    my $show_root = delete $p->{root} // 1;
    my $direction = delete $p->{direction} || 'related';
    my $d = length $p->{node_data} ? _from_json( delete $p->{node_data} ) : {};
    my %node_data = %$d if ref $d eq 'HASH';
    $p->{limit} //= 50;  
    my $prefix = $p->{add_prefix} // 1 ? $p->{id_prefix} || _nowstamp . int(rand 99999) . '-' : '';
    local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;
    my $k=0;
    $c->stash->{json} = try {
        my @all;
        for my $mid ( _array( $mids ) ) { 
            $mid =~ s{^.+-(.+)$}{$1}; 
            my $ci = _ci( $mid );
            my @rels = $ci->$direction( depth=>2, mode=>$p->{mode} || 'tree', unique=>1, %$p );
            my $recurse;
            $recurse = sub {
                my $chi = shift;
                my $name = $chi->{name};
                $name = substr($name,0,30).'...' if length $name > 30;
                $k++;
                +{
                    id       => $prefix . $chi->{mid},
                    name     => '#' . $chi->{mid} . ' ' . $name,
                    data => {
                        '$type' => 'icon',
                        %node_data,
                        icon     => $chi->{_ci}{ci_icon},
                    },
                    #data     => { '$type' => 'arrow' },
                    children => [ map { $recurse->($_) } _array( $chi->{ci_rel} ) ]
                }
            };
            my @data = map { $recurse->( $_ ) } @rels;
            my $d = {
                id => $prefix . $mid, 
                name => $ci->name, 
                data => {
                    %node_data,
                    icon => $ci->icon
                },
                children => \@data,
            };
            if( $show_root ) {
                push @all, $d;
            } else {
                push @all, @data;
            }
        }
        my $ret = @all == 1 
            ? $all[0]
            : {
                id=>_nowstamp,
                name=>'search', 
                data => { icon=>'/static/images/icons/ci.png', %node_data },
                children => \@all
            };
        { success=>\1, data=>$ret, count=>$k };
    } catch {
        my $err = shift;
        _error( $err );
        { success=>\0, msg=>$err };
    };
    $c->forward('View::JSON');
}

sub ping : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my @mids = _array delete $p->{mids};
    try {
        my $msg;
        for my $mid ( @mids ) {
            my $ci = _ci( $mid );
            if ( $ci->does( 'Baseliner::Role::CI::Infrastructure' ) ) {
                my ( $status, $out ) = $ci->ping;
                $msg .= "\nCI: ".$ci->name . "\nStatus: " . $status . "\nOutput:\n" . $out . "\n----------------------------------------------";
            }
        } ## end for $mid ( @mids )
        $c->stash->{json} = {success => \1, msg => $msg};
    } ## end try
    catch {
        my $err = shift;
        _error( $err );
        $c->stash->{json} = {success => \0, msg => $err};
    };
    $c->forward('View::JSON');

}

sub services : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $class = $p->{classname} || _fail( _loc('Missing parameter classname') );
    $c->stash->{json} = try {
        my @services = $class->services;
        {success => \1, data=>\@services};
    } ## end try
    catch {
        my $err = shift;
        _error( $err );
        {success => \0, msg => $err};
    };
    $c->forward('View::JSON');
}

# run_service:
sub service_run : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $class = $p->{classname} || _fail( _loc('Missing parameter classname') );
    require Baseliner::Core::Logger::Quiet;
    my $logger = Baseliner::Core::Logger::Quiet->new;
    my $ret;
    $c->stash->{json} = try {
        my $service = $c->registry->get( $p->{key} );
        my $service_js_output = $service->js_output;
        
        local $ENV{BASELINER_LOGCOLOR} = 0;
        my $ci = _ci( $p->{mid} );
        # TODO this is the future: 
        my $ret = $ci->run_service( $p->{key}, %{ $p->{data} || {} } );
        #my $ret = $c->model('Services')->launch( $service->key, obj=>$ci, c=>$c, logger=>$logger, data=>$p->{data}, capture=>1 );
        #_debug( $ret );
        #_debug( $logger );
        #my $console = delete $logger->{console};
        my $data = delete $ret->{return};
        $data = ref $data ? Util->_dump( $data ) : "$data";
        #{success => \1, console=>$console, data=>$data, ret=>Util->_dump($ret), js_output=>$service_js_output };
        {success => \1, console=>$ret->{output}, data=>$data, ret=>Util->_dump($ret), js_output=>$service_js_output };
    } 
    catch {
        my $err = shift;
        _error( $err );
        my $console = delete $logger->{console};
        {success => \0, msg => "$err", console=>$console, log=>Util->_dump($logger) };
    };
    $c->forward('View::JSON');

}

sub edit : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    local $Baseliner::CI::get_form = 1;

    my $has_permission;
    if ( $p->{mid} ) {
        my $ci = _ci($p->{mid});
        $has_permission = Baseliner->model('Permissions')->user_has_any_action( action => 'action.ci.admin.%.'. $ci->{_ci}->{collection}, username => $c->username );
    } else {
        $has_permission = 1;
    }

    $c->stash->{save} = $has_permission ? 'true' : 'false';
    $c->stash->{template} = '/comp/ci-editor.js';
}

sub import : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $yaml = $p->{yaml};
    $c->stash->{json} = try {
        my $d = _load( $yaml );
        my @mids;
        if( ref $d eq 'ARRAY' ) {
            push @mids, $self->import_one_ci( $_ ) for @$d;
        } else {
            push @mids, $self->import_one_ci( $d );
        }
        {success => \1, msg=>_loc('CIs created: %1', join',',@mids), mids=>\@mids };
    } 
    catch {
        my $err = shift;
        _error( $err );
        {success => \0, msg => $err};
    };
    $c->forward('View::JSON');
}

sub import_one_ci {
    my ($self,$d) = @_;
    my $mid = delete $d->{mid};
    if( my $cn = ref $d ) {
        if( my $row = DB->BaliMaster->search({ name=>$d->{name}, collection=>$d->collection })->first ) {
            my $now = Class::Date->now() ;
            $d->{name} = $d->{name} . ' (' . $now . ')';
        }
        return $d->save; 
    } else {
        _fail _loc 'No class name defined for ci %1 (%2)', $d->{name}, $mid;
    }
}

sub grid : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;

    my $has_permission;
   
    if ( $p->{collection} ) {
        $has_permission = Baseliner->model('Permissions')->user_has_any_action( action => 'action.ci.admin.%.'. $p->{collection}, username => $c->username );
    } else {
        $has_permission = 0;
    }

    $c->stash->{save} = $has_permission ? 'true' : 'false';
    $c->stash->{template} = '/comp/ci-gridtree.js';
}

sub index_sync : Local {
    my ($self, $c) = @_;
    _debug 'Deprecated';
}

# Global search

with 'Baseliner::Role::Search';
sub search_provider_name { 'CIs' };
sub search_provider_type { 'CI' };
sub search_query {
    my ($self, %p ) = @_;
    my $query = $p{query};
    my $limit = 50; #$p{limit} // 1000;
    my $where = {};
    
    return () if ! length $query;
    my $res = mdb->master_doc->search( query=>$query, limit=>1000,
        #project=>{name=>1,collection=>1}, 
        project=>{ _id=>0 },
        filter=>{ collection=>mdb->nin('topic','job') }
    );
    #my @mids = map { $_->{obj}{mid} } _array $res->{results};
    #$where->{'me.mid'} = mdb->in(@mids);
    return map {
        my $r = $_->{obj};
        my $text = Util->_encode_json( $r );
        my $coll = $r->{collection};
        my $class = Util->to_ci_class($coll);
        my $icon = $class->icon if $coll && $class->can('icon');
        $text =~ s/"|\{|\}|\'|\[|\]//g;
        my $info = sprintf "%s - %s (%s)", $r->{collection}, $r->{bl}, $r->{ts};
        my $desc = _strip_html( sprintf "%s", ($r->{name} // '') );
        if( length $desc ) {
            $desc = _utf8 $desc;  # strip html messes up utf8
            $desc =~ s/[^\w\s]//g; 
            #$desc =~ s/[^\x{21}-\x{7E}\s\t\n\r]//g; 
        }
        +{
            title => sprintf( '%s #%s %s', $r->{collection}, $r->{mid}, $r->{name} ),
            info  => $info,
            text  => $text, 
            url   => [ $r->{mid}, $r->{name}, '#999', $r->{collection}, $icon ],
            type  => 'ci',
            mid   => $r->{mid},
            id    => $r->{mid},
        }
    } _array $res->{results};
}

=head2

Support the following CI specific calls:

    /ci/8394/mymethod     => becomes _ci( 8394 )->mymethod( $json_and_param_data );
    /ci/grammar/mymethod  => becomes BaselinerX::CI::grammar->mymethod( $json_and_param_data );

    and optionally:

    /ci/grammar/mymethod?mid=1111  => becomes _ci( 1111 )->...

    TODO: missing RESTful support: GET, PUT, POST
    TODO: check security to Class, CI right here based on REST method

=cut
sub default : Path Args(2) {
    my ($self,$c,$arg,$meth) = @_;
    my $p = $c->req->params;
    my $collection = $p->{collection};
    my $res_key = delete $p->{_res_key}; # return call response in this hash key
    my $mid = $p->{mid};
    my $json = $c->req->{body_data};
    delete $p->{api_key};
    my $data = { username=>$c->username, %{ $p || {} }, %{ $json || {} } };
    _fail( _loc "Missing param method" ) unless length $meth;
    # if( my $field = $p->{_file_field} ) {
    #     $p->{$field} = $self->upload_file( $field );
    # }
    local $Baseliner::CI::_no_record = 1;
    try {
        my $ret;
        $meth = "$meth";
        my $to_args = sub { my ($obj)=@_; ( Function::Parameters::info( (ref $obj || $obj).'::'.$meth ) ? %$data : $data ) };
        if( Util->is_number( $arg ) ) {
            my $ci = ci->new( $arg );
            _fail( _loc "Method '%1' not found in class '%2'", $meth, ref $ci) unless $ci->can( $meth) ;
            $ret = $ci->$meth( $to_args->($ci) );
        } elsif( my $ci = ci->find($arg) ) {
            _fail( _loc "Method '%1' not found in class '%2'", $meth, ref $ci) unless $ci->can( $meth) ;
            $ret = $ci->$meth( $to_args->($ci) );
        } elsif( length $mid ) {
            my $ci = ci->new( $mid );
            _fail( _loc "Method '%1' not found in class '%2'", $meth, ref $ci) unless $ci->can( $meth) ;
            $ret = $ci->$meth( $to_args->($ci) );
        } elsif ( $arg eq 'undefined' && $collection ) {
            my $pkg = "BaselinerX::CI::$collection";
            _fail( _loc "Method '%1' not found in class '%2'", $meth, $pkg) unless $pkg->can( $meth) ;
            $ret = $pkg->$meth( $to_args->($pkg) );
        } else {
            my $pkg = "BaselinerX::CI::$arg";
            _fail( _loc "Method '%1' not found in class '%2'", $meth, $pkg) unless $pkg->can( $meth) ;
            $ret = $pkg->$meth( $to_args->($pkg) );
        }
        # prepare response
        my $json_res = {};
        my $call_res = { success=>\1 };
        if( ref $ret eq 'HASH' || Scalar::Util::blessed($ret) ) {
            Util->_unbless( $ret );
            $json_res = $ret;
        } elsif( ref $ret eq 'ARRAY' ) {
            Util->_unbless( $ret );
            $json_res = $ret;
        } else {
            $json_res = { data => $ret };
        }
        # direct response or into a key (like 'data'?)
        if( $res_key ) {
            $c->stash->{json} = { %$call_res, $res_key => $json_res };
        # merged
        } elsif( $json_res eq 'HASH' ) {  
            $c->stash->{json} = { %$call_res, %$json_res };
        # not a HASH, pure response
        } else { 
            $c->stash->{json} = $json_res;
        }
    } catch {
        my $err = shift;
        my $json = try { Util->_encode_json($p) } catch { '{ ... }' };
        _error "Error in CI call '$arg/$meth': $json\n$err";
        $c->stash->{json} = { msg=>"$err", success=>\0 }; 
    };
    $c->forward('View::JSON');
}

sub user_can_search {
    my ($self, $username) = @_;
    return Baseliner->model('Permissions')->user_has_action( username => $username, action => 'action.search.ci');
}
1;

