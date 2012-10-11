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
    my $total;
    my @tree;

    if ( !length $p->{anode} && !$p->{type} ) {
        @tree = $self->tree_roles;
    } elsif ( $p->{type} eq 'role' ) {
        @tree = $self->tree_classes( role => $p->{class}, parent => $p->{anode} );
    } elsif ( $p->{type} eq 'class' ) {
        ( $total, @tree ) = $self->tree_objects(
            class  => $p->{class},
            parent => $p->{anode},
            start  => $p->{start},
            limit  => $p->{limit},
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
            collection => $p->{collection}
        );
    } elsif ( $p->{type} eq 'depend_to' ) {
        ( $total, @tree ) = $self->tree_object_depend(
            to         => $p->{mid},
            parent     => $p->{anode},
            start      => $p->{start},
            limit      => $p->{limit},
            query      => $p->{query},
            collection => $p->{collection}
        );
    }
    
    #_debug _dump( \@tree );
    $total = scalar( @tree ) unless defined $total;
    return ($total,@tree);
}

sub tree_roles {
    my ($self)=@_;
    #my $last1 = '2011-11-04 10:49:22';
           #+{ $_->get_columns, _id => $_->mid, _parent => undef, _is_leaf => \1, size => $size }
    my $cnt = 1;
    my @tree = map {
        my $role = $_->{role};
        my $name = $_->{name};
        $role = 'Generic' if $name eq ''; 
        +{  
            _id => $cnt++,
            _parent  => undef,
            _is_leaf     => \0,
            type => 'role', 
            mid => $cnt,
            item     => $name,
            class    => $role,
            icon     => '/static/images/ci/class.gif',
            versionid  => 1,
            ts       => '-',
            tags     => [],
            properties => undef,

            #children => [], #\@chi
            }
    } $self->list_roles;
    return @tree;
}

sub tree_classes {
    my ($self, %p)=@_;
    my $role = $p{role};
    my $cnt = substr( _nowstamp(), -6 ) . ( $p{parent} * 1 );
    my @tree = map {
        my $item = $_;
        my $collection = $_->collection;
        my $ci_form = $self->form_for_collection( $collection );
        $item =~ s/^BaselinerX::CI:://g;
        $cnt++;
        +{  _id        => ++$cnt,
            _parent  => $p{parent} || undef,
            _is_leaf   => \0,
            type       => 'class',
            #mid        => $cnt,
            item       => $item,
            collection => $collection,
            ci_form  => $ci_form,
            class      => $_,
            icon       => $_->icon,
            has_bl     => $_->has_bl,
            has_description     => $_->has_description,
            versionid    => '',
            ts         => '-',
            properties => '',
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

sub tree_objects {
    my ($self, %p)=@_;
    my $class = $p{class};
    my $collection = $p{collection} // $class->collection;
    my $page = to_pages( start=>$p{start}, limit=>$p{limit} );
    my $where;
    $p{query} and $where = query_sql_build(
           query  => $p{query},
           fields => {
               name => 'name',
            }
    );
    $where->{collection} = $collection;

    my $rs = Baseliner->model('Baseliner::BaliMaster')->search(
        $where, { order_by=>{ -asc=>['mid'] }, rows=>$p{limit}, page=>$page }
    );
    my $total = $rs->pager->total_entries;
    my $cnt = substr( _nowstamp(), -6 ) . ( $p{parent} * 1 );
    my @tree = map {
        my $data = _load( $_->{yaml} );
        my $ci_form = $self->form_for_collection( $_->{collection} );
        # list properties: field: value, field: value ...
        my $pretty = join(', ',map {
            my $d = $data->{$_};
            $d = '**' x length($d) if $_ =~ /password/;
            "$_: $d"
        } grep { length $data->{$_} } keys %$data );
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
            icon              => $class->icon,
            ts                => $_->{ts},
            bl                => $_->{bl},
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
    #my $cnt = substr( _nowstamp(), -6 ) . ( $p{parent} * 1 );
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
    _error \@tree;
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
    } grep /^Baseliner::Role::CI/, keys %cl;
}

# used by Baseliner.store.CI
#   (used in ci forms)

sub store : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $name = delete $p->{name};
    my $collection = delete $p->{collection};
    my $action = delete $p->{action};

    my @data;
    my $total = 0; 

    if( my $class = $p->{class} ) {
        $class = "BaselinerX::CI::$class" if $class !~ /^Baseliner/;
        ($total, @data) = $self->tree_objects( class=>$class, parent=>0, start=>$p->{start}, limit=>$p->{limit}, query=>$p->{query} );
    }
    elsif( my $role = $p->{role} ) {
        $role = "Baseliner::Role::CI::$role" if $role !~ /^Baseliner/;
        for my $class(  packages_that_do( $role ) ) {
            my ($t, @rows) = $self->tree_objects( class=>$class, parent=>0, start=>$p->{start}, limit=>$p->{limit}, query=>$p->{query} );
            push @data, @rows; 
            $total += $t;
        }
    }

    _debug _dump \@data;

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
    try {
        my $obj = Baseliner::CI->new( $mid );
        my $rec = $obj->load;
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

1;

