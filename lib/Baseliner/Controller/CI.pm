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

sub gridtree : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $parent = $p->{anode};
    my $mid = $p->{mid};
    my $total;

    my @tree;

    #if( ! length $p->{anode} ) {
    if( ! length $p->{anode} && ! $p->{type} ) {
        @tree = $self->tree_roles;
    }
    elsif( $p->{type} eq 'role' ) {
        @tree = $self->tree_classes( role=>$p->{class}, parent=>$p->{anode} );
    }
    elsif( $p->{type} eq 'class' ) {
        ($total, @tree) = $self->tree_objects( class=>$p->{class}, parent=>$p->{anode}, start=>$p->{start}, limit=>$p->{limit}, query=>$p->{query} );
    }
    elsif( $p->{type} eq 'object' ) {
        @tree = $self->tree_object_info( mid=>$p->{mid}, parent=>$p->{anode} );
    }
    elsif( $p->{type} eq 'depend_from' ) {
        @tree = $self->tree_object_depend( from=>$p->{mid}, parent=>$p->{anode} , start=>$p->{start}, limit=>$p->{limit} );
    }
    elsif( $p->{type} eq 'depend_to' ) {
        @tree = $self->tree_object_depend( to=>$p->{mid}, parent=>$p->{anode} , start=>$p->{start}, limit=>$p->{limit} );
    }
    
    _debug _dump( \@tree );

    $total = scalar( @tree ) unless defined $total;
    $c->stash->{json} = { total=>$total, totalCount=>$total, data=>\@tree, success=>\1 };
    $c->forward('View::JSON');
}

sub list : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $parent = $p->{anode};
    my $mid = $p->{mid};
    my $total;
    #if( $parent > 0 ) {
    #    $c->stash->{json} = { total=>0, data=>[], success=>\1 };
    #    return $c->forward('View::JSON');
    #}

    my @tree;

    if( ! length $p->{anode} ) {
        @tree = $self->tree_roles;
    }
    elsif( $p->{type} eq 'role' ) {
        @tree = $self->tree_classes( role=>$p->{class}, parent=>$p->{anode} );
    }
    elsif( $p->{type} eq 'class' ) {
        ($total, @tree) = $self->tree_objects( class=>$p->{class}, parent=>$p->{anode} );
    }
    elsif( $p->{type} eq 'object' ) {
        @tree = $self->tree_object_info( mid=>$p->{mid}, parent=>$p->{anode} );
    }
    elsif( $p->{type} eq 'depend_from' ) {
        @tree = $self->tree_object_depend( from=>$p->{mid}, parent=>$p->{anode} );
    }
    elsif( $p->{type} eq 'depend_to' ) {
        @tree = $self->tree_object_depend( to=>$p->{mid}, parent=>$p->{anode} );
    }
    
    @tree = map {
        my $n = {};
        $_->{anode} = $_->{_id};
        $n->{leaf} = $_->{type} =~ /role/ ? $_->{_is_leaf} : \1;
        $n->{text} = $_->{item};
        $n->{icon} = $_->{icon};
        #$_->{id} = $_->{_id};
        $n->{url} = '/ci/list';
        $n->{data} = $_;
        $n->{data}{click} = { url=>'/comp/ci-gridtree.js', type=>'comp', icon=>$_->{icon} };
        $n;
    } @tree;
    _debug _dump( \@tree );

    #$c->stash->{json} = { total=>scalar(@tree), data=>\@tree, success=>\1 };
    $total = scalar( @tree ) unless defined $total;
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub grid : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $parent = $p->{anode};
    my $mid = $p->{mid};
    my $total;
    my @tree;
    if( $p->{type} eq 'class' ) {
        ($total, @tree) = $self->tree_objects( class=>$p->{class}, parent=>$p->{anode}, start=>$p->{start}, limit=>$p->{limit}, query=>$p->{query} );
    }
    elsif( $p->{type} eq 'object' ) {
        @tree = $self->tree_object_info( mid=>$p->{mid}, parent=>$p->{anode}, start=>$p->{start}, limit=>$p->{limit}  );
    }
    elsif( $p->{type} eq 'depend_from' ) {
        @tree = $self->tree_object_depend( from=>$p->{mid}, parent=>$p->{anode}, start=>$p->{start}, limit=>$p->{limit}  );
    }
    elsif( $p->{type} eq 'depend_to' ) {
        @tree = $self->tree_object_depend( to=>$p->{mid}, parent=>$p->{anode}, start=>$p->{start}, limit=>$p->{limit}  );
    }
    @tree = map {
        $_->{leaf} = $_->{type} =~ /role/ ? $_->{_is_leaf} : \1;
        $_->{text} = $_->{item};
        #$_->{id} = $_->{_id};
        $_->{anode} = $_->{_id};
        $_
    } @tree;
    $total = scalar( @tree ) unless defined $total;
    $c->stash->{json} = { totalCount=>$total, data=>\@tree, success=>\1 };
    $c->forward('View::JSON');
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
        $item =~ s/^BaselinerX::CI:://g;
        $cnt++;
        +{  _id        => ++$cnt,
            _parent    => $p{parent},
            _is_leaf   => \0,
            type       => 'class',
            #mid        => $cnt,
            item       => $item,
            collection => $collection,
            class      => $_,
            icon       => $_->icon,
            versionid    => '',
            ts         => '-',
            properties => '',
        }
    } packages_that_do( $role );
    return @tree; 
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
        # list properties: field: value, field: value ...
        my $pretty = join(', ',map {
            my $d = $data->{$_};
            $d = '**' x length($d) if $_ =~ /password/;
            "$_: $d"
        } grep { length $data->{$_} } keys %$data );
        my $noname = $_->{collection}.':'.$_->{mid};
        +{
            _id               => ++$cnt,
            _parent           => $p{parent},
            _is_leaf          => \0,
            mid               => $_->{mid},
            name              => ( $_->{name} // $noname ),
            item              => ( $_->{name} // $data->{name} // $noname ),
            type              => 'object',
            class             => $class,
            icon              => $class->icon,
            ts                => $_->{ts},
            bl                => $_->{bl},
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
    my $join = {};
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
        $where, { %$join }
    );
    my $cnt = substr( _nowstamp(), -6 ) . ( $p{parent} * 1 );
    my @tree = map {
        my $class = 'BaselinerX::CI::GenericServer';  # TODO reverse lookup
        my $data = _load( $_->{yaml} );
        my $bl = [ split /,/, $_->{bl} ];
        +{
            _id        => ++$cnt,
            _parent    => $p{parent},
            _is_leaf   => \0,
            mid        => $_->{$rel_type}{mid},
            item       => ( $_->{name} // $data->{name} // $_->{$rel_type}{collection} . ":" . $_->{$rel_type}{mid} ),
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
}

sub tree_object_info {
    my ($self, %p)=@_;
    my $mid = $p{mid};
    my $cnt = substr( _nowstamp(), -6 ) . ( $p{parent} * 1 );
    my @tree = (
        {
            _id      => $cnt++,
            _parent  => $p{parent},
            _is_leaf => \0,
            mid      => $mid,
            item     => _loc('Depends On'), 
            type     => 'depend_from',
            class    => '-',
            icon     => '/static/images/ci/in.png',
            ts       => '-',
            versionid  => '',
        },
        {
            _id      => $cnt++,
            _parent  => $p{parent},
            _is_leaf => \0,
            mid      => $mid,
            item     => _loc('Depend On Me'), 
            type     => 'depend_to',
            class    => '-',
            icon     => '/static/images/ci/out.png',
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

sub sync : Local {
    my ($self, $c, $action) = @_;
    my $p = $c->req->params;
    my $mid = delete $p->{mid};
    my $collection = delete $p->{collection};
    my $class = delete $p->{class};
    my $name = delete $p->{name};

    my $data = exists $p->{ci_json} ? _from_json( $p->{ci_json} ) : $p;
    my $ci_create_or_update = sub {
        my $ci = shift;
        my $mid;
        # check if needed, in case of foreign ci
        if( my $ns = $p->{ns} ) {
            my $row = $c->model('Baseliner::BaliMaster')->search({ ns=>$ns })->first;
            if( ref $row ) {  # it's an update
                $row->name( $name );
                $row->collection( $name );
                $row->yaml( _dump( $data ) );
                $row->update;
            }
        }
        if( !$collection && exists $p->{class} ) {
            my $class = "BaselinerX::CI::$p->{class}";
            $collection = $class->collection;
            _fail _loc( 'Missing collection for %1', $class ) unless $collection;
        } else {
            _fail _loc( 'Missing collection for %1', $name ) unless $collection;
        }
    };

    try {
        # check for relationships
        while( my ($k,$v) = each %$data ) {
            if( $k eq 'ci' ) {
                for my $ci ( _array $v ) {
                    $ci_create_or_update->( $ci ) ;
                }
            }
            elsif( ref $v eq 'ARRAY' ) {
            }
        }

        $c->stash->{json} = { success=>\1, msg=>_loc('CI %1 saved ok', $name) };
        $c->stash->{json}{mid} = $mid;
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg=>_loc('CI error: %1', $err ) };
    };

    $c->forward('View::JSON');
}

sub update : Local {
    my ($self, $c, $action) = @_;
    my $p = $c->req->params;
    # don't store in yaml
    my $name = delete $p->{name};
    my $bl = delete $p->{bl};
    my $mid = delete $p->{mid};
    my $collection = delete $p->{collection};
    $action ||= delete $p->{action};

    try {
        if( $action eq 'add' ) {
            my $master_row = master_new $collection => $name => $p;
            $mid = $master_row->mid;
        }
        elsif( $action eq 'edit' && defined $mid ) {
            my $row = $c->model('Baseliner::BaliMaster')->find( $mid );
            if( $row ) {
                $row->name( $name );
                $row->yaml( _dump( $p ) );
                $row->bl( join ',', _array $bl ); # TODO mid rel bl 
                $row->update;
                _log _dump { $row->get_columns };
            }
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

1;

