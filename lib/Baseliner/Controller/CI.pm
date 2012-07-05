package Baseliner::Controller::CI;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
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
        $n->{data}{click} = { url=>'/comp/ci-gridtree.js', type=>'comp', icon=>$p->{icon} };
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
            mid        => $cnt,
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
            "$_: $data->{$_}"
        } grep { length $data->{$_} } keys %$data );
        my $noname = $_->{collection}.':'.$_->{mid};
        +{
            _id      => ++$cnt,
            _parent  => $p{parent},
            _is_leaf => \0,
            mid      => $_->{mid},
            name     => ($_->{name} // $noname ),
            item     => ( $_->{name} // $data->{name} // $noname ),
            type     => 'object',
            class    => $class,
            icon     => $class->icon,
            ts      => $_->{ts},
            data     => $data,
            properties     => $_->{yaml},
            pretty_properties => $pretty,
            version  => '',
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
        +{
            _id        => ++$cnt,
            _parent    => $p{parent},
            _is_leaf   => \0,
            mid        => $_->{$rel_type}{mid},
            item       => ( $_->{name} // $data->{name} // $_->{$rel_type}{collection} . ":" . $_->{$rel_type}{mid} ),
            type       => 'object',
            class      => $class,
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

sub store : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $name = delete $p->{name};
    my $collection = delete $p->{collection};
    my $action = delete $p->{action};

    my @data;
    my $total = 0; 

    if( my $role = $p->{role} ) {
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

sub update : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $name = delete $p->{name};
    my $collection = delete $p->{collection};
    my $action = delete $p->{action};

    if( $action eq 'add' ) {
        master_new $collection => $name => $p;
    }
    

    $c->stash->{json} = { success=>\1, msg=>_loc('CI %1 saved ok', $name) };
    $c->forward('View::JSON');
}

1;

__END__
(function(params) {
    var store = {
        reload: function() {
           tree.root.reload(); 
        }
    };
    <& /comp/search_field.mas &>
    var search_field = new Ext.app.SearchField({
        store: store,
        params: {start: 0, limit: 100 },
        emptyText: _('<Enter your search string>')
    });
    var render_tags = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( typeof value == 'object' ) {
            var va = value.slice(0); // copy array
            return Baseliner.render_tags( va, metadata, rec );
        } else {
            return Baseliner.render_tags( value, metadata, rec );
        }
    };
    var render_mapping = function(value,metadata,rec,rowIndex,colIndex,store) {
        var ret = '<table>';
        ret += '<tr>'; 
        var k = 0;
        for( var k in value ) {
            if( value[k]==undefined ) value[k]='';
            ret += '<td style="font-size: 10px;font-weight: bold;padding: 1px 3px 1px 3px;">' + _(k) + '</td>'
            ret += '<td width="80px" style="font-size: 10px; background: #f5f5f5;padding: 1px 3px 1px 3px;"><code>' + value[k] + '</code></td>'
            if( k % 2 ) {
                ret += '</tr>'; 
                ret += '<tr>'; 
            }
        }
        ret += '</table>';
        return ret;
    };
    var tree = new Ext.ux.tree.TreeGrid({
        width: 500,
        height: 300,
        lines: true,
		stripeRows: true,
        enableSort: false,
        enableDD: true,
        dataUrl: '/cia/list',
        //dataUrl: '/cia/data.json',
        tbar: [ search_field,
            { xtype:'button', text: 'Crear', icon: '/static/images/icons/edit.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: 'Borrar', icon: '/static/images/icons/delete.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: 'Etiquetar', icon: '/static/images/icons/tag.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: 'Exportar', icon: '/static/images/icons/downloads_favicon.png', cls: 'x-btn-text-icon' },
        ],
        columns:[
            {
                header: 'Item',
                dataIndex: 'item',
                width: 230
            },
            {
                header: 'Class',
                width: 120,
                dataIndex: 'class'
            },
            {
                header: 'Version',
                width: 80,
                dataIndex: 'version'
            },
            {
                header: 'Last Scan',
                width: 120,
                dataIndex: 'last'
            },
            {
                header: _('Tags'),
                width: 140,
                tpl: new Ext.XTemplate('{tags:this.renderer}', {
                    renderer: function(v) {
                        if( v== undefined ) return '';
                        return render_tags(v);
                    }
                }),
                dataIndex: 'tags'
            },
            {
                header: 'Properties',
                width: 250,
                tpl: new Ext.XTemplate('{properties:this.renderer}', {
                    renderer: function(v) {
                        if( v== undefined ) return '';
                        return render_mapping(v);
                    }
                }),
                dataIndex: 'properties'
            }
        ]
    });
    return tree;
})

