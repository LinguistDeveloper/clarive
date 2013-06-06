package Baseliner::Controller::CI;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

register 'action.ci.admin' => { name => 'Admin CIs' };
register 'menu.tools.ci' => {
    label    => 'CI Viewer',
    url_comp => '/comp/ci-viewer-tree.js',
    title    => 'CI Viewer',
    icon     => '/static/images/ci/ci.png',
    actions  => ['action.ci.admin']
};

# gridtree - the adjacency list treegrid
sub gridtree : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;

    my ($total, @tree ) = $self->dispatch( $p );
    $c->stash->{json} = { total=>$total, totalCount=>$total, data=>\@tree, success=>\1 };
    $c->forward('View::JSON');
}

# list - used by the west navigator
sub list : Local {
    my ($self, $c) = @_;
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
            url  => '/comp/ci-gridtree.js',
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

    _log "Buscando ".$p->{type}." ".$p->{class};
    if ( !length $p->{anode} && !$p->{type} ) {
        @tree = $self->tree_roles( user => $p->{user} );
    } elsif ( $p->{type} eq 'role' ) {
        @tree = $self->tree_classes( role => $p->{class}, parent => $p->{anode}, user => $p->{user}, role_name => $p->{item} );
    } elsif ( $p->{type} eq 'class' ) {
        ( $total, @tree ) = $self->tree_objects(
            class  => $p->{class},
            parent => $p->{anode},
            start  => $p->{start},
            limit  => $p->{limit},
            pretty => $p->{pretty},
            query  => $p->{query},
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
    
    #_debug _dump( \@tree );
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
            ->user_has_any_action( username => $user, action => 'action.ci.admin.' . $name . '.%') )
        {
            _log 'Encontrado '. 'action.admin.ci.' . $name;
            $role = 'Generic' if $name eq '';
            push @tree, {
                _id        => $cnt++,
                _parent    => undef,
                _is_leaf   => \0,
                type       => 'role',
                mid        => $cnt,
                item       => $name,
                class      => $role,
                icon       => '/static/images/ci/class.gif',
                versionid  => 1,
                ts         => '-',
                tags       => [],
                properties => undef,

                #children => [], #\@chi
            };
        } ## end if ( Baseliner->model(...))
    } $self->list_roles;
    _log _dump @tree;
    return @tree;

} ## end sub tree_roles

sub tree_classes {
    my ( $self, %p ) = @_;
    my $role = $p{role};
    my $user = $p{user};
    my $cnt = substr( _nowstamp(), -6 ) . ( $p{parent} * 1 );
    my @tree;
    map {
        my $item       = $_;
        my $collection = $_->collection;
        my $ci_form = $self->form_for_collection( $collection );
        $item =~ s/^BaselinerX::CI:://g;
        if ( Baseliner->model( 'Permissions' )
            ->user_has_action( username => $user, action => 'action.ci.admin.' .$p{role_name}.'.'. $item ) )
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

sub form_for_collection {
    my ($self, $collection )=@_;
    my $ci_form = sprintf "/ci/%s.js", $collection;
    my $component_exists = -e Baseliner->path_to( 'root', $ci_form );
    return $component_exists ? $ci_form : '';
}

# adjacency flat tree
sub tree_objects {
    my ($self, %p)=@_;
    my $class = $p{class};
    my $collection = $p{collection} // $class->collection;
    my $opts = { order_by=>{ -asc=>['mid'] } };
    my $page;
    if( length $p{start} && length $p{limit} ) {
        $page =  to_pages( start=>$p{start}, limit=>$p{limit} );
        $opts->{rows} = $p{limit};
        $opts->{page} = $page;
    }
    my $where = {};
    $p{query} and $where = query_sql_build(
           query  => $p{query},
           fields => {
               name => 'name',
            }
    );
    $where->{collection} = $collection;
    $where = { %$where, %{ $p{where} } } if $p{where};
    
    if( $p{mids} ) {
        $where->{mid} = $p{mids};
    }

    my $rs = Baseliner->model('Baseliner::BaliMaster')->search( $where, $opts );
    my $total = defined $page ? $rs->pager->total_entries : $rs->count;
    my (%forms, %icons);  # caches
    my @tree = map {
        my $data = _load( $_->{yaml} );
        my $ci_form = $forms{ $_->{collection} } 
            // ( $forms{ $_->{collection} } = $self->form_for_collection( $_->{collection} ) );
        
        # list properties: field: value, field: value ...
        my $pretty = $p{pretty} 
            ?  do { join(', ',map {
                my $d = $data->{$_};
                $d = '**' x length($d) if $_ =~ /password/;
                "$_: $d"
                } grep { length $data->{$_} } keys %$data ) }
            : '';
        my $noname = $_->{collection}.':'.$_->{mid};
        +{
            _id               => $_->{mid},
            _parent           => $p{parent} || undef,
            _is_leaf          => \0,
            mid               => $_->{mid},
            name              => ( $_->{name} // $noname ),
            item              => ( $_->{name} // $data->{name} // $noname ),
            ci_form           => $ci_form,
            type              => 'object',
            class             => $class,
            icon              => ( $icons{ $class } // ( $icons{$class} = $class->icon ) ),
            ts                => $_->{ts},
            bl                => $_->{bl},
            description       => $data->{description},
            active            => ( $_->{active} eq 1 ? \1 : \0 ),
            data              => $data,
            properties        => $_->{yaml},
            pretty_properties => $pretty,
            versionid         => $_->{versionid},
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
            item       => ( $_->{$rel_type}{name} // $data->{name} // $_->{$rel_type}{collection} ).':'.$_->{$rel_type}{mid}, # // $data->{name} // $_->{$rel_type}{collection} . ":" . $_->{$rel_type}{mid} ),
            type       => 'object',
            class      => $class,
            bl         => $bl,
            collection => $_->{$rel_type}{collection},
            icon       => $class->icon,
            ts         => $_->{$rel_type}{ts},
            data       => $data,
            properties => $_->{yaml},
            versionid    => $_->{versionid},
            }
    } $rs->hashref->all;
    _debug \@tree;
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
    _debug \@tree;
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
            icon     => '/static/images/icons/topic.png',
            ts       => '-',
            versionid  => '',
        },
    );
    return @tree;
}

sub list_roles {
    my ($self, $role) = @_;
    sub name_transform {
        my $name = shift;
        ($name) = $name =~ /^.*::CI::(.*)$/;
        $name =~ s{::}{}g;
        $name =~ s{([a-z])([A-Z])}{$1_$2}g; 
        lc $name || 'ci';
    }
    my %cl=Class::MOP::get_all_metaclasses;
    map {
        my $role = $_;
        +{
            role => $role,
            name => name_transform( $role ),
        }
    } grep /^Baseliner::Role::CI::/, keys %cl;
}

# used by Baseliner.store.CI
#   (used in ci forms)

sub store : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $name = delete $p->{name};
    my $collection = delete $p->{collection};
    my $action = delete $p->{action};
    my $where = {};
    local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;

    if ( $p->{mid} ) {
        my @rel_items =
            map { $_->{to_mid} }
            Baseliner->model('Baseliner::BaliMasterRel')->search( { from_mid => $p->{mid}, rel_type => $p->{rel_type} } )
            ->hashref->all;
        $where->{mid} = \@rel_items;
    }
    
    my $mids = delete $p->{mids};
    if( length $mids ) {
        $mids = [ grep { defined } split /,+/, $mids ] unless ref $mids eq 'ARRAY';
    }
    
    my @data;
    my $total = 0; 

    if( my $class = $p->{class} ) {
        $class = "BaselinerX::CI::$class" if $class !~ /^Baseliner/;
        ($total, @data) = $self->tree_objects( class=>$class, parent=>0, start=>$p->{start}, limit=>$p->{limit}, query=>$p->{query}, where=>$where, mids=>$mids, pretty=>$p->{pretty} );
    }
    elsif( my $role = $p->{role} ) {
        my @roles;
        for my $r ( _array $role ) {
            if( $r !~ /^Baseliner/ ) {
                $r = $r eq 'CI' ? "Baseliner::Role::CI" : "Baseliner::Role::CI::$r" ;
            }
            push @roles, $r;
        }
        for my $class(  packages_that_do( @roles ) ) {
            my ($t, @rows) = $self->tree_objects( class=>$class, parent=>0, start=>$p->{start}, limit=>$p->{limit}, query=>$p->{query}, mids=>$mids, pretty=>$p->{pretty});
            push @data, @rows; 
            $total += $t;
        }
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
    $c->forward('View::JSON');
}

## adds/updates foreign CIs

sub ci_create_or_update {
    my %p = @_;
    return $p{mid} if length $p{mid};
    my $ns = $p{ns} || delete $p{data}{ns};
    # check if it's an update, in case of foreign ci
    if( $ns ) {
        my $row = Baseliner->model('Baseliner::BaliMaster')->search({ ns=>$ns })->first;
        if( ref $row ) {  # it's an update
            if( ref $p{data} ) {
                $p{yaml} = _dump( delete $p{data} );
                $row->yaml( $p{yaml} );
                $row->update;
            }
            #$row->name( $name ) if defined $name;
            #$row->collection( $p{collection} ) if defined $p{collection};
            #$row->yaml( _dump( $p{data} ) );
            return $row->mid;
        }
    }
    # new
    # find collection
    my $collection = $p{collection};
    my $name = $p{name};
    if( !$collection && exists $p{class} ) {
        my $class = "BaselinerX::CI::$p{class}";
        $collection = $class->collection;
        _fail _loc( 'Missing collection for class %1', $class ) unless $collection;
    } else {
        _fail _loc( 'Missing collection for %1', $name ) unless $collection;
    }
    my $master_row = master_new $collection => $name => $p{data};
    $master_row->ns( $ns ) if $p{ns};
    $master_row->update;
    return $master_row->mid;
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

    my $data = exists $p->{ci_json} ? _from_json( $p->{ci_json} ) : $p;

    try {
        # check for prereq relationships
        my @ci_pre_mid;
        my %ci_data;
        while( my ($k,$v) = each %$data ) {
            if( $k eq 'ci_pre' ) {
                for my $ci ( _array $v ) {
                    _log( _dump( $ci ) );
                    push @ci_pre_mid, ci_create_or_update( %$ci ) ;
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

        $mid = ci_create_or_update( name=>$name, class=>$class, ns=>$ns, collection=>$collection, mid=>$mid, data=>\%ci_data );

        $c->stash->{json} = { success=>\1, msg=>_loc('CI %1 saved ok', $name) };
        $c->stash->{json}{mid} = $mid;
    } catch {
        my $err = shift;
        _log( $err );
        $c->stash->{json} = { success=>\0, msg=>_loc('CI error: %1', $err ) };
    };

    $c->forward('View::JSON');
}

=head2 update

Create or update a CI.

=cut
sub update : Local {
    my ($self, $c, $action) = @_;
    my $p = $c->req->params;
    # cleanup
    for my $k ( keys %$p ) {
        delete $p->{$k} if $k =~ /^ext-comp-/
    }
    # don't store in yaml
    my $name = delete $p->{name};
    my $bl = delete $p->{bl};
    my $mid = delete $p->{mid};
    my $active = $p->{active};
    $p->{active} = $active = $active eq 'on' ? 1 : 0;
    my $collection = delete $p->{collection};
    $action ||= delete $p->{action};
    my $class = "BaselinerX::CI::$collection";

    try {
        if( $action eq 'add' ) {
            $mid = $class->save( name=>$name, bl=>$bl, active=>$active, data=> $p ); 
        }
        elsif( $action eq 'edit' && defined $mid ) {
            $mid = $class->save( mid=>$mid, name=> $name, bl=>$bl, active=>$active, data => $p ); 
        }
        else {
            _fail _loc("Undefined action");
        }
        $c->stash->{json} = { success=>\1, msg=>_loc('CI %1 saved ok', $name) };
        $c->stash->{json}{mid} = $mid;
    } catch {
        my $err = shift;
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
    local $Baseliner::CI::mid_scope = {} unless $Baseliner::CI::mid_scope;
    try {
        my $obj = Baseliner::CI->new( $mid );
        my $class = ref $obj;
        my $rec = $obj->load;
        $rec->{has_bl} = $obj->has_bl;
        $rec->{has_description} = $obj->has_description;
        $rec->{classname} = $rec->{class} = $class;
        $rec->{icon} = $obj->icon;
        $rec->{active} = $rec->{active} ? \1 : \0;
        $c->stash->{json} = { success=>\1, msg=>_loc('CI %1 loaded ok', $mid ), rec=>$rec };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg=>_loc('CI load error: %1', $err ) };
    };
    $c->forward('View::JSON');
}

sub delete : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $mids = delete $p->{mids};

    try {
        my $cnt = $c->model('Baseliner::BaliMaster')->search( { mid=>$mids })->delete;
        $c->stash->{json} = { success=>\1, msg=>_loc('CIs deleted ok' ) };
        #$c->stash->{json} = { success=>\1, msg=>_loc('CI does not exist' ) };
    } catch {
        my $err = shift;
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
        { success=>\0, msg=>shift() };
    };
    $c->forward('View::JSON');
}

sub json_tree : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $mid = delete $p->{mid};
    my $direction = delete $p->{direction} || 'related';
    my $k = 1;
    $c->stash->{json} = try {
        my $ci = _ci( $mid );
        my @rels = $ci->$direction( depth=>2, mode=>'tree', %$p );
        my $recurse;
        $recurse = sub {
            my $chi = shift;
            $k++;
            +{
                id       => $k . '-' . $chi->{mid},
                name     => $chi->{name},
                data => {
                    '$type' => 'icon',
                    icon     => $chi->{_ci}{ci_icon},
                },
                #data     => { '$type' => 'arrow' },
                children => [ map { $recurse->($_) } _array( $chi->{ci_rel} ) ]
            }
        };
        my @data = map { $recurse->( $_ ) } @rels; 
        my $d = {
            id => $mid, 
            name => $ci->name, 
            data => {
                icon => $ci->icon
            },
            children => \@data,
        };
        _debug $d;
        { success=>\1, data=>$d };
    } catch {
        { success=>\0, msg=>shift() };
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
        $c->stash->{json} = {success => \0, msg => shift()};
    };
    $c->forward('View::JSON');

}

1;

