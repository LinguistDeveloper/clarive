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
    my $public = $self->public_searches({ meta=>\%meta });
    
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
    my @searches = $self->search_cis({ '$or' => [{ permissions=>'private' }, { permissions=>undef } ] }); 
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
    my @public;
    for my $folder ( @searches ){
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
    my @tree = (
        { text=>_loc('Values'),
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
                {
                    text     => $_,
                    icon     => '/static/images/icons/field-add.png',
                    id_field => $_,
                    type     => 'select_field',
                    leaf     => \1
                }
            } mdb->topic->all_keys
        ],
    };
    push @tree, map { 
        my $cat = $_;
        my @chi = map { +{ 
                %$_,
                text => _loc($_->{name_field}), 
                icon => '/static/images/icons/field-add.png',
                type => 'select_field',
                category => $cat,
                leaf=>\1, 
             } } 
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
    my %ret = ( ids=>['mid','topic_mid','category_name','category_color','modified_on'], names=>[] );
    my %fields = map { $_->{type}=>$_->{children} } _array( $self->selected );
    my $meta = $p->{meta};
    for ( _array($fields{select}) ) {
        my $id = $data_field_map{$_->{id_field}} // $_->{id_field};
        $id =~ s/\.+/-/g;  # convert dot to dash to avoid JsonStore id problems
        my $as = $_->{as} // $_->{name_field};
        push @{ $ret{ids} }, $id;
        push @{ $ret{names} }, $as; 
        push @{ $ret{columns} }, { as=>$as, id=>$id, meta_type=>$meta->{$id}{meta_type} };
    }
    return \%ret;
}

method run( :$start=0, :$limit=undef, :$username=undef ) {
    my $rows = $limit // $self->rows;
    my %fields = map { $_->{type}=>$_->{children} } _array( $self->selected );
    
    my %meta = map { $_->{id_field} => $_ } _array( Baseliner->model('Topic')->get_meta() );  # XXX should be by category, same id fields may step on each other

    my @selects = map { ( $_->{meta_select_id} // $select_field_map{$_->{id_field}} // $_->{id_field} ) => 1 } _array($fields{select});
    #_debug \@selects;

    my @where = grep { defined } map { 
        my $field=$_;
        #_debug $field->{id_field};
        #my $id = $field_map{$field->{id_field}} // $field->{id_field};
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
    #_debug \@where;
    
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

    my @sort = map { $_->{id_field} => 1 } _array($fields{sort});
    
    my $find = @where ? { '$and'=>[ @where ] } : {};
    my $rs = mdb->topic->find($find);
    my $cnt = $rs->count;
    _debug \%meta;
    my @data = $rs
      ->sort({ @sort })
      ->fields({ _id=>0 })
      ->skip( $start )
      ->limit($rows)
      ->all;
    #->fields({ @selects, _id=>0, mid=>1 })
    my %cache_topics;
    my @topics = map { 
        my %f = hash_flatten($_);
        %f = map { 
            my $k = $_; my $k2 = $_; 
            $k2 =~ s/\.+/_/g; # convert dots to underscore, otherwise javascript unhappy
            #$k2 = $data_field_map{$k2} // $k2;
            my $v = $f{$k}; 
            $v = Class::Date->new($v)->string if $k2 =~ /modified_on|created_on/;
            my $mt = $meta{$k}{meta_type} // '';
            if( $mt =~ /release|ci/ ) { 
                $v = $cache_topics{$v} 
                    // ( $cache_topics{$v} = mdb->topic->find_one({ mid=>"$v" },
                        { title=>1, mid=>1, is_changeset=>1, is_release=>1, category=>1 }) );
            }
            $k2 => $v; 
        } keys %f;
        $f{topic_mid} = $f{mid};
        \%f;
    } @data; 
    #_debug \@topics;
    return ( $cnt, @topics );
}

1;

__END__

