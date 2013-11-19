package BaselinerX::CI::report;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _array _loc _fail hash_flatten);
use v5.10;
use Try::Tiny;
with 'Baseliner::Role::CI::Internal';

has selected    => qw(is rw isa ArrayRef), default => sub{ [] };
has rows        => qw(is rw isa Num default 100);
has permissions => qw(is rw isa Any default private);
has sql         => qw(is rw isa Any);
has mode        => qw(is rw isa Maybe[Str] default lock);
has owner       => qw(is rw isa Maybe[Str]);
has_ci 'user';

sub icon { '/static/images/icons/report.png' }

sub rel_type {
    {
    user  => [from_mid => 'report_user'],
    }
}


sub report_list {
    my ($self,$p) = @_;
    
    my %meta = map { $_->{id_field} => $_ } _array( Baseliner->model('Topic')->get_meta() );  # XXX should be by category, same id fields may step on each other
    my $mine = $self->my_searches({ username=>$p->{username}, meta=>\%meta });
    my $public = $self->public_searches({ meta=>\%meta, username=>$p->{username} });
    
    my @trees = (
            {
                text => _loc('My Searches'),
                icon => '/static/images/icons/report.png',
                mid => -1,
                draggable => \0,
                children => $mine,
                url => '/ci/report/my_searches',
                data => [],
                menu => [
                    {   text=> _loc('New search') . '...',
                        icon=> '/static/images/icons/report.png',
                        eval=> { handler=> 'Baseliner.new_search'},
                    } 
                ],
                expanded => \1,
            },
            {
                text => _loc('Public Searches'),
                icon => '/static/images/icons/report.png',
                url => '/ci/report/public_searches',
                mid => -1,
                draggable => \0,
                children => $public,
                data => [],
                expanded => \1,
            },
    );
    return \@trees; 
}

sub my_searches {
    my ($self,$p) = @_;
    my $userci = Baseliner->user_ci( $p->{username} );
    my $username = $p->{username};
    #DB->BaliMasterRel->search({ to_mid=>$userci->mid, rel_field=>'report_user' });
    my @searches = $self->search_cis({ owner=>$username, '$or' => [{ permissions=>'private' }, { permissions=>undef } ] }); 
    my @mine;
    for my $folder ( @searches ){
        push @mine,
            {
                mid     => $folder->mid,
                text    => $folder->name,
                icon    => '/static/images/icons/topic.png',
                menu    => [
                    {
                        text   => _loc('Edit') . '...',
                        icon   => '/static/images/icons/report.png',                        
                        eval   => { handler => 'Baseliner.edit_search' }
                    },
                    {
                        text   => _loc('Delete') . '...',
                        icon   => '/static/images/icons/folder_delete.gif',
                        eval   => { handler => 'Baseliner.delete_search' }
                    }                    
                ],
                data    => {
                    click   => {
                        icon    => '/static/images/icons/topic.png',
                        url     => '/comp/topic/topic_grid.js',
                        type    => 'comp',
                        title   => $folder->name,
                    },
                    #store_fields   => $folder->fields,
                    #columns        => $folder->fields,
                    fields         => $folder->selected_fields({ meta=>$p->{meta} }),
                    id_report      => $folder->mid,
                    report_name    => $folder->name,
                    report_rows    => $folder->rows,
                    #column_mode    => 'full', #$folder->mode,
                    hide_tree      => \1,
                },
                rows    => $folder->rows,
                permissions => $folder->permissions,
                leaf    => \1,
            };
    }    
    return \@mine;
}

sub public_searches {
    my ($self,$p) = @_;
    my @searches = $self->search_cis( permissions=>'public' ); 
    my %user_categories = map {
        $_->{id} => 1;
    } Baseliner->model('Topic')->get_categories_permissions( username => $p->{username}, type => 'view' );
    
    my @public;
    for my $folder ( @searches ){
        my %fields = map { $_->{type}=>$_->{children} } _array( $folder->selected );
        # check categories permissions
        my @categories = map { $_->{id_category} } _array($fields{categories});
        my @user_cats = grep { exists $user_categories{ $_ } } @categories;
        next if @categories > @user_cats;  # user cannot see category, skip this search
        push @public,
            {
                mid     => $folder->mid,
                text    => sprintf( '%s (%s)', $folder->name, $folder->owner ), 
                icon    => '/static/images/icons/topic.png',
                #menu    => [ ],
                data    => {
                    click   => {
                        icon    => '/static/images/icons/topic.png',
                        url     => '/comp/topic/topic_grid.js',
                        type    => 'comp',
                        title   => $folder->name,
                    },
                    #store_fields   => $folder->fields,
                    #columns        => $folder->fields,
                    fields         => $folder->selected_fields({ meta=>$p->{meta} }),
                    id_report      => $folder->mid,
                    report_rows    => $folder->rows,
                    report_name    => $folder->name,
                    #column_mode    => 'full', #$folder->mode,
                    hide_tree      => \1,
                },
                leaf    => \1,
            };
    }    
    return \@public;
}

sub report_update {
    my ($self, $p) = @_;
    my $action = $p->{action};
    my $username = $p->{username};
    my $mid = $p->{mid};
    my $data = $p->{data};
    
    my $user = Baseliner->user_ci( $username );
    if(!$user){
        _fail _loc('Error user does not exist. ');
    }
    
    my $ret;
    
    given ($action) {
        when ('add') {
            try{
                $self = $self->new() unless ref $self;
                my @cis = $self->search_cis( name=>$data->{name} );
                if(!@cis){
                    $self->selected( $data->{selected} ) if ref $data->{selected};
                    $self->name( $data->{name} );
                    $self->user( $user );
                    $self->owner( $username );
                    $self->permissions( $data->{permissions} );
                    $self->rows( $data->{rows} );
                    $self->sql( $data->{sql} );
                    $self->save;
                    $ret = { msg=>_loc('Search added'), success=>\1, mid=>$self->mid };
                } else {
                    _fail _loc('Search name already exists, introduce another search name');
                }
            }
            catch{
                _fail _loc('Error adding search: %1', shift());
            };
        }
        when ('update') {
            try{
                my @cis = $self->search_cis( name=>$data->{name} );
                if( @cis && $cis[0]->mid != $self->mid ) {
                    _fail _loc('Search name already exists, introduce another search name');
                }
                else {
                    $self->name( $data->{name} );
                    $self->rows( $data->{rows} );
                    $self->sql( $data->{sql} );
                    $self->owner( $username );
                    $self->permissions( $data->{permissions} );
                    $self->selected( $data->{selected} ) if ref $data->{selected}; # if the selector tab has not been show, this is submitted undef
                    $self->save;
                    $ret = { msg=>_loc('Search modified'), success=>\1, mid=>$self->mid };
                }
            }
            catch{
                _fail _loc('Error modifing search: %1', shift());
            };
        }
        when ('delete') {
            try {
                $self->delete;
                $ret = { msg=>_loc('Search deleted'), success=>\1 };
            } catch {
                _fail _loc('Error deleting search: %1', shift());
            };
        }
    }
    $ret;
}

sub dynamic_fields {
    my ($self,$p) = @_;
    my @tree;
    push @tree, mdb->topic->all_keys;
    return \@tree;
}

sub all_fields {
    my ($self,$p) = @_;
    
    my @cats = DB->BaliTopicCategories->search(undef,{ order_by=>{ -asc=>'name' } })->hashref->all;
    my @tree;
    push @tree, (
        { text=>_loc('Categories'),
            leaf=>\0,
            expanded => \1,
            icon => '/static/images/icons/topic_one.png',
            children=>[
                map { 
                    $_->{text} = $_->{name};
                    $_->{icon}='/static/images/icons/topic_one.png'; 
                    $_->{id_category}= delete $_->{id};
                    $_->{type}='category'; $_->{leaf}=\1; $_ } 
                sort { $a->{name_field} cmp $b->{name_field} }
                DB->BaliTopicCategories->hashref->all
            ]
        }
    );
    push @tree, (
        { text=>_loc('Filters'),
            leaf=>\0,
            expanded => \1,
            icon => '/static/images/icons/search.png',
            children=>[
                map { $_->{icon}='/static/images/icons/where.png'; $_->{type}='value'; $_->{leaf}=\1; $_ } 
                (
                    { text=>_loc('String'), where=>'string', field=>'string', },
                    { text=>_loc('Like'), where=>'like', field=>'string' },
                    { text=>_loc('Number'), where=>'number', field=>'number' },
                    { text=>_loc('Date'), where=>'date', field=>'date' },
                    { text=>_loc('CIs'), where=>'cis', field=>'ci' },
                    { text=>_loc('Status'), where=>'status', field=>'status' },
                )
            ]
        }
    );
    push @tree, {
        text => _loc('Dynamic'),
        leaf => \0,
        icon     => '/static/images/icons/all.png',
        #url  => '/ci/report/dynamic_fields',
        children => [
            map {
                my $key = $_;
                my ($prefix,$data_key) = split( /\./, $key, 2);
                {
                    text     => $key,
                    icon     => '/static/images/icons/field-add.png',
                    id_field => $prefix,
                    data_key => $data_key,
                    type     => 'select_field',
                    leaf     => \1
                }
            } 
            grep !/^_/, 
            grep !/\.[0-9]+$/, 
            mdb->topic->all_keys
        ],
    };

    # Fields that are common to every topic (system fields)
    my @fieldlets = _array( Baseliner->model('Topic')->get_meta() );
    #_error \@fieldlets;
    my %common_list = ( created_on=>1, created_by=>1, modified_on=>1, modified_by=>1 );
    my %hidden_list = ( labels=>1, included_into=>1, progress=>1, 
         ( map {$_->{id_field}=>1} grep {$_->{type} eq 'separator' || $_->{meta_type} eq 'history'} grep {exists $_->{type}} @fieldlets) );
     
    my %common_fields = map { $_->{id_field} => $_ } 
        # any fields that are 'system', or are in the common_list and are not in the hidden list
        grep { ($_->{origin} eq 'system' || exists $common_list{$_->{id_field}}) 
            && !exists $hidden_list{$_->{id_field}} } 
        @fieldlets;

    push @tree, {
        text => _loc('Commons'),
        leaf => \0,
        icon     => '/static/images/icons/topic.png',
        #url  => '/ci/report/dynamic_fields',
        children => [
            map {
                {
                    text      => _loc( $_->{name_field} ),
                    icon      => '/static/images/icons/field-add.png',
                    id_field  => $_->{id_field},
                    header    => $_->{name_field},
                    meta_type => $_->{meta_type},
                    gridlet   => $_->{gridlet},
                    type      => 'select_field',
                    leaf      => \1,
                }
            } 
            sort { lc $a->{name_field} cmp lc $b->{name_field} } 
            values %common_fields
        ],
    };

    # Custom Fields, separated by topic
    push @tree, map { 
        my $cat = $_;
        my @chi = map { +{ 
                %$_,
                text        => _loc($_->{name_field}), 
                icon        => '/static/images/icons/field-add.png',
                type        => 'select_field',
                meta_type   => $_->{meta_type},
                gridlet     => $_->{gridlet},
                category    => $cat,
                leaf        =>\1, 
             } } 
            sort { lc $a->{name_field} cmp lc $b->{name_field} } 
            grep { !exists $common_fields{$_->{id_field}} && !exists $hidden_list{$_->{id_field}} } 
            _array( Baseliner->model('Topic')->get_meta( undef, $cat->{id} ) ); 
        +{  text => _loc($cat->{name}),
            data => $cat, 
            icon => '/static/images/icons/topic.png',
            expanded => \0,
            draggable => \0,
            children =>\@chi, 
        }
    } @cats;

    return \@tree;
}

sub field_tree {
    my ($self,$p) = @_;
    return $self->selected;
} 

our %data_field_map = (
    status => 'category_status_name',
    status_new => 'category_status_name',
    name_status => 'category_status_name',       
    'category_status.name' => 'category_status_name',       
);

our %select_field_map = (
    status => 'category_status.name',
    status_new => 'category_status.name',
    name_status => 'category_status.name',       
);

our %where_field_map = ();

sub selected_fields {
    my ($self, $p ) = @_; 
    my %ret = ( ids=>['mid','topic_mid','category_name','category_color','modified_on'] );
    my %fields = map { $_->{type}=>$_->{children} } _array( $self->selected );
    my $meta = $p->{meta};
    for my $select_field ( _array($fields{select}) ) {
        my $id = $data_field_map{$select_field->{id_field}} // $select_field->{id_field};
        $id =~ s/\.+/-/g;  # convert dot to dash to avoid JsonStore id problems
        my $as = $select_field->{as} // $select_field->{name_field};
        push @{ $ret{ids} }, $id;   # sent to the Topic Store as report data keys
        push @{ $ret{columns} }, { as=>$as, id=>$id, meta_type=>$meta->{$id}{meta_type}, %$select_field };
    }
    #_debug \%ret;
    return \%ret;
}

method run( :$start=0, :$limit=undef, :$username=undef, :$query=undef ) {
    my $rows = $limit // $self->rows;
    my %fields = map { $_->{type}=>$_->{children} } _array( $self->selected );
    
    my %meta = map { $_->{id_field} => $_ } _array( Baseliner->model('Topic')->get_meta() );  # XXX should be by category, same id fields may step on each other
    my @selects = map { ( $_->{meta_select_id} // $select_field_map{$_->{id_field}} // $_->{id_field} ) => 1 } _array($fields{select});

    my @where = grep { defined } map { 
        my $field=$_;
        my $id = $field->{meta_where_id} // $where_field_map{$_->{id_field}} // $field->{id_field};
        my @chi = _array($field->{children});
        my @ors;
        for my $val ( @chi ) {
            my $cond = $val->{oper} 
                ? { $id => { $val->{oper} => $val->{value} } }
                : { $id => $val->{value} };
            push @ors, $cond; 
        }
        @ors ? { '$or' => \@ors } : undef;
    } _array($fields{where});
    
    # filter user projects
    if( $username && !Baseliner->is_root($username) ) {
        my @ids_project = Baseliner->model('Permissions')->user_projects_with_action(
            username => $username,
            action   => 'action.job.viewall',
            level    => 1
        );
        my @and_project;
        for my $field_project ( grep { $_->{meta_type} eq 'project' } values %meta ) {
            push @where, { $field_project->{id_field} => mdb->in(@ids_project) };  
        }
    }
    
    if( length $query ) {
        my @qmids = map { $_->{obj}{mid} } _array(mdb->topic->search( query=>$query, limit=>999999, project=>{ mid=>1 } )->{results});
        push @where, { mid=>mdb->in(@qmids) };
    }

    # filter categories
    if( my @categories = map { {'id_category' => $_->{id_category}} } _array($fields{categories}) ) {
        push @where, { '$or'=>\@categories };
    }
    my @sort = map { $_->{id_field} => 0+($_->{sort_direction} // 1) } _array($fields{sort});
    
    my $find = @where ? { '$and'=>[ @where ] } : {};
    my $rs = mdb->topic->find($find);
    my $cnt = $rs->count;
    #_debug \%meta;
    my @data = $rs
      ->sort({ @sort })
      ->fields({ _id=>0 })
      ->skip( $start )
      ->limit($rows)
      ->all;
    #->fields({ @selects, _id=>0, mid=>1 })
    my %scope_topics;
    my %scope_cis;
    my @topics = map { 
        my %row = %$_;
        while( my($k,$v) = each %row ) {
            $row{$k} = Class::Date->new($v)->string if $k =~ /modified_on|created_on/;
            my $mt = $meta{$k}{meta_type} // '';
            #  get additional fields ?   
            #  TODO for sorting, do this before and save to report_results collection (capped?) 
            #       with query id and query ts, then sort
            #_error "MT===$mt, K==$k";
            if( $mt =~ /ci|project|revision|user/ ) { 
                $row{$k} = $scope_cis{$v} 
                    // do{ 
                        my @objs = mdb->master_doc->find({ mid=>mdb->in($v) },{ _id=>0 })->all;
                        $scope_cis{$_->{mid}} = $_ for @objs; 
                        \@objs;
                        };
            } elsif( $mt =~ /release|topic/ ) { 
                $row{$k} = $scope_topics{$v} 
                    // do {
                        my @objs = mdb->topic->find({ mid=>mdb->in($v) },
                                { title=>1, mid=>1, is_changeset=>1, is_release=>1, category=>1, _id=>0 })->all;
                        $scope_cis{$_->{mid}} = $_ for @objs; 
                        \@objs;   
                    };
            } elsif( $mt eq 'calendar' && ( my $cal = ref $row{$k} ? $row{$k} : undef ) ) { 
                for my $slot ( keys %$cal ) {
                    $cal->{$slot}{$_} //= '' for qw(end_date plan_end_date start_date plan_start_date);
                }
            }
        }
        $row{topic_mid} = $row{mid};
        $row{category_color} = $row{category}{color};
        $row{category_name} = $row{category}{name};
        $row{category_id} = $row{category}{id};
        \%row;
    } @data; 
    #_debug \@topics;
    return ( 0+$cnt, @topics );
}

1;

__END__

