package BaselinerX::CI::report;
use Baseliner::Moose;

use v5.10;
use Try::Tiny;
use experimental 'autoderef', 'switch';
use Baseliner::Utils;
use Baseliner::Model::Permissions;
use Baseliner::Model::Users;
use Baseliner::Model::Topic;
use Baseliner::RuleRunner;

with 'Baseliner::Role::CI::Internal';

has selected    => qw(is rw isa ArrayRef), default => sub{ [] };
has rows        => qw(is rw isa Num default 100);
has recursivelevel   => qw(is rw isa Num default 2);
has permissions => qw(is rw isa Any default private);
has usersandroles => qw(is rw isa Any default private);
has sql         => qw(is rw isa Any);
has mode        => qw(is rw isa Maybe[Str] default lock);
has owner       => qw(is rw isa Maybe[Str]);
has_ci 'user';

sub icon { '/static/images/icons/report.svg' }

sub rel_type {
    {
    user  => [from_mid => 'report_user'],
    }
}

sub root_reports {
    my ($self,$p) = @_;

    my @searches = $self->search_cis( sort=>"name" );
    my @public;
    for my $folder ( @searches ){
        push @public,{
            mid     => $folder->mid,
            text    => sprintf( '%s (%s)', $folder->name, $folder->owner ),
            icon    => '/static/images/icons/report-default.svg',
            menu    => [ ],
            data    => {
                click   => {
                    icon    => '/static/images/icons/report-default.svg',
                    url     => '/comp/lifecycle/report_run.js',
                    type    => 'eval',
                    title   => $folder->name,
                },
                id_report      => $folder->mid,
                report_rows    => $folder->rows,
                report_name    => $folder->name,
                column_mode    => 'full', #$folder->mode,
                hide_tree      => \1,
            },
            leaf    => \1,
        };
    }
    return \@public;
}


sub report_list {
    my ($self,$p) = @_;

    my %meta = map { $_->{id_field} => $_ } _array( Baseliner->model('Topic')->get_meta(undef, undef, $p->{username}) );  # XXX should be by category, same id fields may step on each other
    my $mine = $self->my_searches({ username=>$p->{username}, meta=>\%meta });
    my $reports_available = $self->reports_available({ username=>$p->{username}, meta=>\%meta });
    my $reports_from_rule = $self->reports_from_rule({ username=>$p->{username}, meta=>\%meta });
    my $public = $self->public_searches({ meta=>\%meta, username=>$p->{username} });
    my @trees = (
            {
                text => _loc('My Reports'),
                icon => '/static/images/icons/report.svg',
                mid => -1,
                draggable => \0,
                children => $mine,
                url => '/ci/report/my_searches',
                data => [],
                menu => [
                    {   text=> _loc('New search') . '...',
                        icon=> '/static/images/icons/magnifier.svg',
                        eval=> { handler=> 'Baseliner.new_search'},
                    }
                ],
                expanded => \1,
            },
            {
                text => _loc('Public Reports'),
                icon => '/static/images/icons/report.svg',
                url => '/ci/report/public_searches',
                mid => -1,
                draggable => \0,
                children => $public,
                data => [],
                expanded => \1,
            }
    );
    #root user can view all reports of all users.
    if (Baseliner::Model::Permissions->is_root( $p->{username} )){
        my $root_reports = $self->root_reports({ meta=>\%meta, username=>$p->{username} });
        push @trees, ({
                text => _loc('All') . " (Root)",
                icon => '/static/images/icons/report.svg',
                url => '/ci/report/root_reports',
                mid => -1,
                draggable => \0,
                children => $p->{show_reports} ? undef : $root_reports,
                data => [],
                expanded => $p->{show_reports} ? \0 : \1,
            });
    }
    if ($p->{show_reports} eq 'true'){
        push @trees, ({
            text => _loc('Internal Reports'),
            icon => '/static/images/icons/report.svg',
            mid => -1,
            draggable => \0,
            children => $reports_available,
            url => '/ci/report/reports_available',
            data => [],
            expanded => \1,
        });
        push @trees, ({
            text => _loc('Rule Reports'),
            icon => '/static/images/icons/report.svg',
            mid => -1,
            draggable => \0,
            children => $reports_from_rule,
            url => '/ci/report/reports_from_rule',
            data => [],
            expanded => \1,
        });
    }
    return \@trees;
}

sub reports_available {
    my ($self,$p) = @_;
    my $userci = Baseliner->user_ci( $p->{username} );
    my $username = $p->{username};
    my @tree;
    for my $key ( Baseliner->registry->starts_with( 'report.' ) ) {
        my $reg = Baseliner->registry->get( $key );
        # check security
        if( my $han = $reg->security_handler ) {
            my $can = $han->($reg, $username);
            next unless $can;
        }
        my $name = $reg->name // $key;
        my $n = {
            key => $key,
            text => _loc($name),
            icon => $reg->icon,
            leaf => \1,
            data    => {
                click   => {
                    icon    => $reg->icon,
                    url     => '/comp/topic/topic_report.js',
                    type    => 'eval',
                    title   => $name,
                },
                id_report      => $key,
                report_name    => $name,
                hide_tree      => \1,
                custom_form    => $reg->form,
            }
        };
        push @tree, $n;
    }
    @tree = sort { $a->{text} cmp $b->{text} }  @tree;
    return \@tree;
}

sub reports_from_rule {
    my $self = shift;
    my ( $p ) = @_;

    my $username = $p->{username};

    my @active_report_rules =
      mdb->rule->find( { rule_type => 'report', rule_active => mdb->true } )->sort( { id => 1 } )->all;

    my @tree;
    for my $rule (@active_report_rules) {
        my $stash = {
            step          => 'meta',
            report_params => +{%$p},
            report_meta   => {
                fields => {
                    ids     => ['info'],
                    columns => [ { id => 'info', text => 'Info' } ],
                },
                report_name => 'No Data',
                report_type => 'jobs',
                hide_tree   => \1,
            }
        };

        my $rule_runner = Baseliner::RuleRunner->new;
        $rule_runner->find_and_run_rule( id_rule => $rule->{id}, stash => $stash );

        my $permissions = Baseliner::Model::Permissions->new;

        my $is_access_allowed = $permissions->is_root($username)
          || (
            ref $stash->{report_security} eq 'CODE'
            ? $stash->{report_security}->( username => $username )
            : $stash->{report_security}
          );

        if ($is_access_allowed) {
            my $node = {
                key  => "$rule->{id}",
                text => $rule->{rule_name},
                icon => '/static/images/icons/rule.svg',
                leaf => \1,
                data => {
                    click => {
                        icon  => '/static/images/icons/rule.svg',
                        url   => '/comp/topic/topic_report.js',
                        type  => 'eval',
                        title => $rule->{rule_name},
                    },
                    id_report_rule => "$rule->{id}",
                    report_name    => $rule->{rule_name},
                    hide_tree      => \1,

                    #custom_form    => $reg->form,
                }
            };
            push @tree, $node;
        }
    }

    return \@tree;
}

sub report_meta {
    my ( $self, $p ) = @_;

    my $config = $p->{config} // {};

    if ( my $id = $p->{id_report_rule} ) {
        my $stash = {
            step          => 'meta',
            report_params => +{%$p},
            report_meta   => {
                fields => {
                    ids     => ['info'],
                    columns => [ { id => 'info', text => 'Info' } ],
                },
                report_name => 'No Data',
                report_type => 'jobs',
                hide_tree   => \1,
            }
        };

        my $rule_runner = Baseliner::RuleRunner->new;
        $rule_runner->find_and_run_rule( id_rule => $p->{id_report_rule}, stash => $stash );

        my $meta = ( ref $$stash{report_meta} eq 'CODE' ? $stash->{report_meta}->(%$config) : $stash->{report_meta} ) // {};
        return $meta;
    }
    elsif ( my $key = $p->{id_report} ) {
        my $report = Baseliner->registry->get($key);
        return $report->meta_handler->($config);
    }
    else {
        _fail 'Missing report id';
    }
}

sub my_searches {
    my ($self,$p) = @_;
    my $userci = Baseliner->user_ci( $p->{username} );
    my $username = $p->{username};

    my @searches = $self->search_cis( owner=>$username, sort=>"name");
    my @mine;
    for my $folder ( @searches ){
        my $name           = $folder->name;
        my $id_report      = $folder->mid;
        my $report_name    = $folder->name;
        my $report_rows    = $folder->rows;
        my $rows    = $folder->rows;
        my $permissions = $folder->permissions;
        my $usersandroles = $folder->usersandroles;
        my $recursivelevel = $folder->recursivelevel;
        push @mine,
            {
                mid     => $folder->mid,
                text    => $name,
                icon    => '/static/images/icons/report-default.svg',
                menu    => [
                    {
                        text   => _loc('Edit') . '...',
                        icon   => '/static/images/icons/edit.svg',
                        eval   => { handler => 'Baseliner.edit_search' }
                    },
                    {
                        text   => _loc('Delete') . '...',
                        icon   => '/static/images/icons/delete.svg',
                        eval   => { handler => 'Baseliner.delete_search' }
                    }
                ],
                data    => {
                    click   => {
                        icon    => '/static/images/icons/report-default.svg',
                        url     => '/comp/lifecycle/report_run.js',
                        type    => 'eval',
                        title   => $name,
                    },
                    # fields         => $folder->selected_fields({ meta=>$p->{meta}, username => $p->{username}  }),
                    id_report      => $id_report,
                    report_name    => $report_name,
                    report_rows    => $report_rows,
                    hide_tree      => \1,
                },
                rows    => $rows,
                permissions => $permissions,
                usersandroles => $usersandroles,
                recursivelevel => $recursivelevel,
                leaf    => \1,
            };
    }
    return \@mine;
}

sub public_searches {
    my ($self,$p) = @_;

    my @usersandroles = map { 'role/'.$_} Baseliner::Model::Permissions->user_roles_ids( $p->{username} );
    push @usersandroles, 'user/'.ci->user->find_one({name => $p->{username}})->{mid};
    push @usersandroles, undef;

    # my @searches = $self->search_cis( owner=> { '$ne' => $p->{username}}, permissions=>'public', usersandroles => mdb->in(@usersandroles) );
    my @searches = $self->search_cis(
        owner=> { '$ne' => $p->{username}},
        permissions=>'public',
        '$or'=>[{usersandroles => mdb->in(_unique @usersandroles)},{usersandroles => '' }],
        sort=>"name"
        );

    my @public;
    for my $folder ( @searches ){
        push @public,{
            mid     => $folder->mid,
            text    => sprintf( '%s (%s)', $folder->name, $folder->owner ),
            icon    => '/static/images/icons/report-default.svg',
            menu    => [ ],
            data    => {
                click   => {
                    icon    => '/static/images/icons/report-default.svg',
                    url     => '/comp/lifecycle/report_run.js',
                    type    => 'eval',
                    title   => $folder->name,
                },
            #     #store_fields   => $folder->fields,
            #     #columns        => $folder->fields,
            #     fields         => $folder->selected_fields({ meta => $p->{meta}, username => $p->{username} }),
                id_report      => $folder->mid,
                report_rows    => $folder->rows,
                report_name    => $folder->name,
                column_mode    => 'full', #$folder->mode,
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
    my $user = ci->user->search_ci(name=>$username);
    if(!$user){
        _fail _loc('Error user does not exist. ');
    }

    my $ret;

    given ($action) {
        when ('add') {
            try{
                $self = $self->new() unless ref $self;
                my @cis = $self->search_cis( name=>$data->{name}, owner=>$username );
                if(!@cis){
                    $self->selected( $data->{selected} ) if ref $data->{selected};
                    $self->name( $data->{name} );
                    $self->user( $user );
                    $self->owner( $username );
                    $self->permissions( $data->{permissions} );
                    $self->usersandroles( $data->{usersandroles} );
                    $self->recursivelevel( $data->{recursivelevel} );
                    $self->rows( $data->{rows} );
                    $self->sql( $data->{sql} );
                    $self->save;
                    $ret = { msg=>_loc('Search added'), success=>\1, mid=>$self->mid };
                } else {
                    #_fail _loc('Search name already exists, introduce another search name');
                    $ret = { msg=>_loc('Search name already exists, introduce another search name')};
                }
            }
            catch{
                _fail _loc('Error adding search: %1', shift());
            };
        }
        when ('update') {
            try{
                my @cis = $self->search_cis( name=>$data->{name}, owner=>$username );
                if( @cis && $cis[0]->mid ne $self->mid ) {
                    _fail _loc('Search name already exists, introduce another search name');
                }
                else {
                    $self->name( $data->{name} );
                    #Util->_warn( $data );
                    $self->rows( $data->{rows} );
                    $self->sql( $data->{sql} );
                    $self->owner( $username );
                    $self->permissions( $data->{permissions} );
                    $self->usersandroles( $data->{usersandroles} );
                    $self->recursivelevel( $data->{recursivelevel} );
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
                mdb->category->update( { default_grid => $self->{mid} }, { '$unset' => { default_grid => '' } },{multiple => 1} );
                $self->delete;
                $ret = { msg => _loc('Search deleted'), success => \1 };
            }
            catch {
                _fail _loc( 'Error deleting search: %1', shift() );
            };
        }

    }
    return $ret;
}

sub dynamic_fields {
    my ($self,$p) = @_;
    my @tree;
    push @tree, _unique grep { defined } map { $$_{id_field} } _array( model->Topic->get_meta );
    return \@tree;
}

sub all_fields {
    my ( $self, $p ) = @_;

    my $username = $p->{username};
    my $id_category = $p->{id_category} ? $p->{id_category} : undef;

    my @tree;

    my @user_categories =
      Baseliner::Model::Topic->new->get_categories_permissions( username => $username, type => 'view' );

    if ( !$id_category ) {
        my @children;
        foreach my $category (@user_categories) {
            push @children,
              {
                text => $category->{name},
                icon => '/static/images/icons/ci-report-selected-category.svg',
                data => {
                    'id_category'   => $category->{id},
                    'name_category' => $category->{name},
                    'fields' => [ map {[$_->{id_field} => $_->{text}]} @{ $self->_category_fields($username, $category) } ]
                },
                type => 'category',
                leaf => \0
              };
        }

        push @tree,
          (
            {
                text      => _loc('Categories'),
                leaf      => \0,
                draggable => \0,
                expanded  => \1,
                icon      => '/static/images/icons/ci-report-category.svg',
                children  => \@children
            }
          );

        my $reports_config = BaselinerX::Type::Model::ConfigStore->get('config.reports');
        if ( $reports_config->{fields_dynamics} && $reports_config->{fields_dynamics} ne 'NO' ) {
            my $has_action =
              Baseliner::Model::Permissions->new->user_has_action( $username, 'action.reports.dynamics' );
            if ($has_action) {
                push @tree, {
                    text      => _loc('Dynamic'),
                    leaf      => \0,
                    icon      => '/static/images/icons/all.svg',
                    url       => '/ci/report/dynamic_fields',
                    draggable => \0,
                    children  => [
                        map {
                            my $key = $_;
                            my ( $prefix, $data_key ) = split( /\./, $key, 2 );
                            {
                                text     => $key,
                                icon     => '/static/images/icons/ci-report-add-field.svg',
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
            }
        }
    }
    else {
        my ($category) = grep { $id_category eq $_->{id} } @user_categories;

        if ($category) {
            push @tree, @{ $self->_category_fields($username, $category)};
        }
    }

    return \@tree;
}

sub _category_fields {
    my $self=  shift;
    my ($username, $category) = @_;

    my $meta = Baseliner::Model::Topic->new->get_meta( undef, $category->{id}, $username );
    $meta = Baseliner::Model::Topic->new->get_meta_permissions(
        username    => $username,
        meta        => $meta,
        id_category => $category->{id},
        id_status   => '*',
    );

    my @tree;
    foreach my $fieldlet ( sort { _loc( $a->{name_field} ) cmp _loc( $b->{name_field} ) } @$meta ) {
        push @tree,
          {
            text               => _loc( $fieldlet->{name_field} ),
            id_field           => $fieldlet->{id_field},
            icon               => '/static/images/icons/ci-report-add-field.svg',
            type               => 'select_field',
            meta_type          => $fieldlet->{meta_type},
            collection         => $fieldlet->{collection},
            collection_extends => $fieldlet->{collection_extends},
            ci_class           => $fieldlet->{ci_class},
            filter             => $fieldlet->{filter},
            gridlet            => $fieldlet->{gridlet},
            category           => $category->{name},
            options            => $fieldlet->{options},
            format             => $fieldlet->{format},
            leaf               => \1
          };
    }

    return \@tree;
}

sub field_tree {
    my ($self,$p) = @_;
    return $self->selected;
}

our %data_field_map = (
    category => 'category_name',
    status => 'category_status_name',
    status_new => 'category_status_name',
    name_status => 'category_status_name',
    'category_status.name' => 'category_status_name',
);

our %select_field_map = (
    category => 'category.name',
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

    if ( !$meta ) {
        my %meta_temp = map {  $_->{id_field} => $_ } _array( Baseliner::Model::Topic->new->get_meta(undef, undef, $p->{username}) );
        $meta = \%meta_temp;
    }

    my @categories = map { $_->{data}->{id_category} } _array($fields{categories});
    my @status = values +{ ci->status->statuses( id_category=>\@categories ) };

    my %filters;
    for my $filter ( _array($fields{where}) ) {
        my %type_filter = map { $_->{type}=>$_->{children} } _array( $filter );
        for my $type ( _array($type_filter{where_field}) ) {
            given ($type->{field}) {
                when ('status') {
                    if($type->{value} eq 'default'){
                        my (@options, @values);
                        map {
                            push @options, $_->{name};
                            push @values, $_->{id_status};
                        } @status;
                        $filters{$filter->{id_field}} = { type => $type->{field}, options => @options ? \@options : undef, values => @values ? \@values: undef};
                    }else{
                        $filters{$filter->{id_field}} = { type => $type->{field}, options => exists $type->{options} ? $type->{options} : undef, values => $type->{value}};
                    }
                };
                when ('ci') {
                    if($type->{value} && $type->{value} eq 'default'){
                        my $collection = $filter->{collection} // $filter->{ci_class} ;
                        my @cis;
                        my (@options, @values);

                        my @mids = Baseliner::Model::Permissions->new->user_security_dimension( $p->{username}, $collection );

                        if( @mids ) {
                            @cis = ci->$collection->find({ mid=>mdb->in(@mids) })->fields({ _id=>0, name=>1, mid=>1 })->sort({ name=>1 })->all;
                        } else {
                            @cis = ci->$collection->find({})->fields({ _id=>0, name=>1, mid=>1 })->sort({ name=>1 })->all;
                        }

                        map {
                            push @options, $_->{name};
                            push @values, $_->{mid};
                        } @cis;

                        push @options, _loc('Undefined');
                        push @values, '-1';

                        $filters{$filter->{id_field}} = { type => $type->{field}, options => @options ? \@options : undef, values => @values ? \@values: undef};
                    }
                    else{
                        $filters{$filter->{id_field}} = { type => $type->{field}, options => exists $type->{options} ? $type->{options} : undef, values => $type->{value}};
                    }
                }
                default{
                    $filters{$filter->{id_field}} = { type => $type->{field}, options => exists $type->{options} ? $type->{options} : undef, values => $type->{value}};
                }
            }
        }
    }

    for my $select_field ( _array($fields{select}) ) {
        my $id = $data_field_map{$select_field->{id_field}} // $select_field->{id_field};
        my $filter_type = exists $filters{$select_field->{id_field}} ?  $filters{$select_field->{id_field}} : undef;
        if ( $filter_type) {
            $filter_type->{category} = $select_field->{category};
        }

        $id =~ s/\.+/-/g;  # convert dot to dash to avoid JsonStore id problems
        my $as = $select_field->{as} // $select_field->{name_field};
        push @{ $ret{ids} }, $id . "_$select_field->{category}";   # sent to the Topic Store as report data keys
        push @{ $ret{columns} }, { as=>$as, id=>$id, meta_type=>$meta->{$id}{meta_type}, %$select_field, filter=> $filter_type };
    }
    #_debug \%ret;
    return \%ret;
}

sub get_where {
    my ( $self, $p ) = @_;
    my $filters_where  = $p->{filters_where};
    my $name_category  = $p->{name_category};
    my %dynamic_filter = %{ $p->{dynamic_filter} };
    my $where          = $p->{where};

    foreach my $filter_where ( _array($filters_where) ) {
        next unless !exists $filter_where->{category} || $filter_where->{category} eq $name_category;

        my $field = $filter_where;
        my $id    = $field->{meta_where_id} // $where_field_map{ $filter_where->{id_field} } // $field->{id_field};
        my @chi   = _array( $field->{children} );

        for my $val (@chi) {
            my $id_field_category = $id . "_$name_category";
            my $cond;

            if ( exists $dynamic_filter{$id_field_category}
                && $dynamic_filter{$id_field_category}->{category} eq $name_category )
            {
                my $dynamic_filter_type = $dynamic_filter{$id_field_category}->{type};
                if ($dynamic_filter_type eq 'numeric') {
                    for ( my $i = 0 ; $i < scalar @{ $dynamic_filter{$id_field_category}->{oper} } ; $i++ ) {
                        if ( $dynamic_filter{$id_field_category}->{oper}[$i] eq 'eq' ) {
                            $cond = $dynamic_filter{$id_field_category}->{value}[$i];
                        }
                        else {
                            $cond->{ '$' . $dynamic_filter{$id_field_category}->{oper}[$i] } =
                              $dynamic_filter{$id_field_category}->{value}[$i];
                        }
                    }
                }
                elsif ($dynamic_filter_type eq 'list') {
                    my @parse;
                    for my $value ( _array $dynamic_filter{$id_field_category}->{value} ) {
                        if ( $value eq '-1' ) {
                            push @parse, '';
                            push @parse, undef;
                            push @parse, [];
                        }
                        else {
                            push @parse, $value;
                        }
                    }
                    if ( scalar @parse > 1 ) {
                        $cond = { '$in' => \@parse };
                    }
                    else {
                        $cond = $parse[0];
                    }
                }
                elsif ($dynamic_filter_type eq 'string') {
                    if ( $val->{oper} =~ /^(like|not_like)$/ || $val->{value} eq 'default' ) {

                        #filtros join tratamiento mid string
                        if ( $val->{where} eq 'ci' ) {
                            $cond = $dynamic_filter{$id_field_category}->{value};
                        }
                        else {
                            $val->{value} = qr/$dynamic_filter{$id_field_category}->{value}/i;
                            if ( $val->{oper} eq 'not_like' ) {
                                $cond = { '$not' => $val->{value} };
                            }
                            else {
                                $cond = $val->{value};
                            }
                        }
                    }
                    else {
                        $val->{value} = $dynamic_filter{$id_field_category}->{value};
                        if ( $val->{oper} ) {
                            $cond = { $val->{oper} => $val->{value} };
                        }
                        else {
                            $cond = $val->{value};
                        }
                    }
                }
                elsif ($dynamic_filter_type eq 'date') {
                    for ( my $i = 0 ; $i < scalar @{ $dynamic_filter{$id_field_category}->{oper} } ; $i++ ) {
                        if ( $dynamic_filter{$id_field_category}->{oper}[$i] eq 'eq' ) {
                            $cond = $dynamic_filter{$id_field_category}->{value}[$i];
                        }
                        else {
                            $cond->{ '$' . $dynamic_filter{$id_field_category}->{oper}[$i] } =
                              $dynamic_filter{$id_field_category}->{value}[$i];
                        }
                    }
                }

                $where->{$id} = $cond;
            }
            else {
                my $type = $val->{field};

                if ( $type eq 'number' ) {
                    if ( $val->{value} && $val->{value} ne 'default' ) {
                        if ( exists $where->{$id} ) {
                            $where->{$id}->{ $val->{oper} } = $val->{value} + 0;
                        }
                        else {
                            $cond = { $val->{oper} => $val->{value} + 0 };
                            $where->{$id} = $cond;
                        }
                    }
                }
                elsif ( $type eq 'string' ) {
                    if ( $val->{value} && $val->{value} ne 'default' ) {
                        if ( $val->{oper} =~ /^(like|not_like)$/ ) {
                            $val->{value} = qr/$val->{value}/i;
                            if ( $val->{oper} eq 'not_like' ) {
                                $cond = { '$not' => $val->{value} };
                            }
                            else {
                                $cond = $val->{value};
                            }
                        }
                        elsif ( $val->{oper} =~ /^(\$in|\$nin)$/ ) {
                            my @variants = split /\s*,\s*/, $val->{value};

                            $cond = { $val->{oper} => [@variants] };
                        }
                        else {
                            if ( $val->{oper} ) {
                                $cond = { $val->{oper} => $val->{value} };
                            }
                            else {
                                $cond = $val->{value};
                            }
                        }
                        $where->{$id} = $cond;
                    }
                }
                elsif ( $type eq 'date' ) {
                    if ( $val->{value} && $val->{value} ne 'default' ) {
                        if ( exists $where->{$id} ) {
                            $where->{$id}->{ $val->{oper} } = $val->{value};
                        }
                        else {
                            if ( $val->{oper} eq '' ) {
                                $where->{$id} = $val->{value};
                            }
                            else {
                                $cond = { $val->{oper} => $val->{value} };
                                $where->{$id} = $cond;
                            }
                        }
                    }
                }
                elsif ( $type eq 'status' ) {
                    if ( $val->{value} && $val->{value} ne 'default' ) {
                        if ( $val->{oper} =~ /^(\$in|\$nin)$/ ) {
                            my @values = _array_or_commas( $val->{value} );
                            $cond = { $val->{oper} => [@values] };
                        }
                        else {
                            if ( $val->{oper} ) {
                                $cond = { $val->{oper} => $val->{value} };
                            }
                            else {
                                $cond = $val->{value};
                            }
                        }
                        $where->{$id} = $cond;
                    }
                }
                elsif ( $type eq 'ci' ) {
                    if ( !$val->{value} && ( $val->{oper} eq 'EMPTY' || $val->{oper} eq 'NOT EMPTY' ) ) {
                        if ( $val->{oper} eq 'NOT EMPTY' ) {
                            $where->{$id} = {
                                '$exists' => 1,
                                '$nin'    => [ undef, '' ],
                                '$ne'     => [],
                            };
                        }
                        else {
                            push @{ $where->{'$or'} },
                              { $id => { '$exists' => 0 } }, { $id => { '$in' => [ undef, '' ] } },
                              { $id => { '$eq' => [] } };
                        }
                    }
                    elsif ( $val->{value} ne 'default' ) {
                        if ( $field->{meta_type} eq 'user' ) {
                            $cond = { $val->{oper} => $val->{options} };
                        }
                        else {
                            if ( $val->{oper} ) {
                                $cond = { $val->{oper} => $val->{value} };
                            }
                            else {
                                $cond = $val->{value};
                            }
                        }

                        $where->{$id} = $cond;
                    }
                }
                else {
                    if ( $val->{value} && $val->{value} ne 'default' ) {
                        if ( $val->{oper} ) {
                            $cond = { $val->{oper} => $val->{value} };
                        }
                        else {
                            $cond = $val->{value};
                        }

                        $where->{$id} = $cond;
                    }
                }
            }
        }
    }

    return $where;
}

method run( :$id_category_report=undef,:$start=0, :$limit=undef, :$username=undef, :$query=undef, :$filter=undef, :$query_search=undef, :$sort=undef, :$sortdir=undef ) {
    # setup a temporary alternative connection if configured
    my $has_rep_db = exists Clarive->config->{mongo}{reports};
    my $mdb2 = !$has_rep_db
        ? $Clarive::_mdb
        : Baseliner::Mongo->new(
            mongo_client => Baseliner->config->{mongo}{reports}{client} // mdb->connection,
            db_name => Baseliner->config->{mongo}{reports}{db_name} // mdb->db_name );
    # so we can connect to a secondary:
    local $MongoDB::Cursor::slave_okay = 1 if $has_rep_db;

    my $rows = $limit // $self->rows;

    my $rel_query ;
    for my $selected ( _array( $self->selected ) ) {
        if ( exists $selected->{query} ) {
            if ($id_category_report) {
                $rel_query->{$id_category_report} = $selected->{query}{$id_category_report} // {} ;
            }else {
                $rel_query = $selected->{query};
            }
            last;
        }
    }

    return () unless keys %{ $rel_query || {} };

    my %fields = map { $_->{type}=>$_->{children} } _array( $self->selected );
    my %meta = map { $_->{id_field} => $_ } _array( Baseliner::Model::Topic->new->get_meta(undef, undef, $username) );  # XXX should be by category, same id fields may step on each other
    my @selects = map { ( $_->{meta_select_id} // $select_field_map{$_->{id_field}} // $_->{id_field} ) => $_->{category} } _array($fields{select});

    my %selects_ci_columns = map { ( $_->{meta_select_id} // $select_field_map{$_->{id_field}} // $_->{id_field} ) . '_' . $_->{category} => $_->{ci_columns} } grep { exists $_->{ci_columns}} _array($fields{select});
    my %selects_ci_columns_collection_extends = map { ( $_->{meta_select_id} // $select_field_map{$_->{id_field}} // $_->{id_field} ) . '_' . $_->{category} => $_->{collection_extends} } grep { exists $_->{ci_columns}} _array($fields{select});
    my %meta_cfg_report = map { $_->{id_field} => $_->{meta_type} } _array($fields{select});

    #filters
    my %dynamic_filter;

    if( $filter ){
        for my $flt ( _array $filter ){
            if( exists $dynamic_filter{$flt->{field}} ){
                push @{$dynamic_filter{$flt->{field}}->{oper}}, $flt->{comparison};
                push @{$dynamic_filter{$flt->{field}}->{value}}, $flt->{value};
            }else {
                given ($flt->{type}) {
                    when ('numeric') {
                        $dynamic_filter{$flt->{field}} =  { category=> $flt->{category}, type=> $flt->{type}, oper=> $flt->{comparison} ? [$flt->{comparison}] : undef , value => [$flt->{value}]};
                    };
                    when ('date') {
                        $dynamic_filter{$flt->{field}} =  { category=> $flt->{category}, type=> $flt->{type}, oper=> $flt->{comparison} ? [$flt->{comparison}] : undef , value => [$flt->{value}]};
                    };
                    default{
                        $dynamic_filter{$flt->{field}} =  { category=> $flt->{category}, type=> $flt->{type}, oper=> $flt->{comparison} ? $flt->{comparison} : undef , value => $flt->{value}};
                    };
                }
            }

            #Exception
            if ( exists $dynamic_filter{'category_status_name_' . $flt->{category}} ){
                $dynamic_filter{'status_new_' . $flt->{category}} = $dynamic_filter{'category_status_name_' . $flt->{category}};
            }
        };
    }

    my $where;
    my %queries;
    my $categories_queries;

    my @All_Categories;
    my @ids_category;

    foreach my $key (sort { $b <=> $a} keys $rel_query) {
        my $wh = {};
        push @ids_category, _array $rel_query->{$key}->{id_category};
        my @names_category = _array $rel_query->{$key}->{name_category};
        my @relation = _array $rel_query->{$key}->{relation};
        map{
            $where = $self->get_where({filters_where => $fields{where}, name_category => $_, dynamic_filter => \%dynamic_filter, where => $where });
            $where->{id_category} = {'$in' => \@ids_category };
            my @data = $mdb2->topic->find($where)->all;
            if (@data && scalar @relation >= 1) {
                my $rel_name;
                my $name_relation;
                my $length_rel = scalar @relation;
                for (my $i=0;$i<$length_rel;$i++){
                    if($relation[$i]){
                        $rel_name = $relation[$i]->{"relation"}[0];
                        $name_relation = $relation[$i]->{"name_category"}[0];
                        my $rel_where;
                        $rel_where->{name_category} = qr/^$name_relation$/i;
                        $rel_where = $self->get_where({filters_where => $fields{where}, name_category => $name_relation, dynamic_filter => \%dynamic_filter, where => $rel_where });
                        my @data_relation = $mdb2->topic->find($rel_where)->all;
                        my %data_to_compare =  map { $_->{mid} => 1 } @data_relation;
                        my @all_mids;
                        map {
                            if (ref $_->{$rel_name} eq 'ARRAY'){
                                $queries{$rel_name}->{$_->{$rel_name}[0]} = 1 if (($_->{$rel_name}[0]) && ($data_to_compare{$_->{$rel_name}[0]}));
                                push @all_mids, $_->{$rel_name}[0] if (($_->{$rel_name}[0]) &&($data_to_compare{$_->{$rel_name}[0]}));
                                $categories_queries->{$_->{name_category}}->{$_->{mid}} = $_ if (($_->{$rel_name}[0]) && ($data_to_compare{$_->{$rel_name}[0]}));
                            } else {
                                $queries{$rel_name}->{$_->{$rel_name}} = 1 if (($_->{$rel_name}) && ($data_to_compare{$_->{$rel_name}}));
                                push @all_mids, $_->{$rel_name} if (($_->{$rel_name}) &&($data_to_compare{$_->{$rel_name}}));
                                $categories_queries->{$_->{name_category}}->{$_->{mid}} = $_ if (($_->{$rel_name}) && ($data_to_compare{$_->{$rel_name}}));
                            }
                        } @data;
                        map{
                            $categories_queries->{$_->{name_category}}->{$_->{mid}} = $_ if ($queries{$rel_name}->{$_->{mid}});
                        } @data_relation;
                    @all_mids = _unique @all_mids;
                    #if exists mismatch rel_name...
                    if ($where->{$rel_name}) {
                        push @all_mids, _array $where->{$rel_name}->{'$in'};
                    }
                    $where->{$rel_name} = { '$in' => _unique \@all_mids };
                    }
                }
            }
            push @All_Categories, $_;
        } @names_category;
    }


    # filter user projects
    my $is_root = Baseliner::Model::Permissions->new->is_root( $username );
    if( $username && ! $is_root){
      my @categories;
        for my $category (@All_Categories) {
            my $id_category = $mdb2->category->find_one({name=>qr/^$category$/i})->{id};
            push @categories, $id_category;
        }

        Baseliner::Model::Permissions->new->inject_security_filter( $username, $where );

        $where->{'category.id'} = {'$in' => \@categories};
    }

    if( length $query ) {
        $where->{'mid'} = mdb->in($query);
    }

    if( exists $where->{'status_new'} ){
        $where->{'category_status.id'} = delete $where->{'status_new'};
    }

    my @sort;
    my @rs_sort;
    my $rs_sort;
    if ($sort) {
        $rs_sort = $sort;
        my @categories;
        if ($categories_queries){
            for (keys $categories_queries) { push(@categories,$_) };
        } else {
            for (@All_Categories) { push(@categories,$_) };
        }
        for (@categories) { $sort =~ s/_$_//g; };
        $sort = "mid" if ($sort eq 'topic_mid');
        @sort = map { $_ => $sortdir } _array($sort);
        @rs_sort = map { $_ => $sortdir } _array($rs_sort);
    } else{
        @sort = map { $_->{id_field} => 0+($_->{sort_direction} // 1) } _array($fields{sort});
    }

    Baseliner::Model::Topic->new->build_field_query( $query_search, $where, $username ) if length $query_search;

    $where->{id_category} = '' if ( !$where->{id_category} && $id_category_report );

    my $rs = $mdb2->topic->find($where);
    my $cnt = $rs->count;
    $rows = $cnt if ($rows eq '-1') ;
    $rs->sort({ @sort });
    my %select_system = (
        mid            => 1,
        category    => 1,
        modified_on    => 1,
        modified_by    => 1,
        labels        => 1
    );
    my $fields =
      { %select_system, map { $_ => 1 } keys +{@selects}, _id => 0, 'category.color' => 1, 'category.name' => 1 };


    my @data = $rs
      ->fields($fields)
      ->skip( $start )
      ->limit($rows)
      ->all;
    my @parse_data;
    map {
        foreach my $field (keys $fields){
            if (!exists $_->{$field}) {
                next if ($field eq '_id' || $field eq '0');
                next if ($meta_cfg_report{$field} && $meta_cfg_report{$field} eq 'date');
                $_->{$field} = ' ';
            }else{
                if ($_->{$field} && $_->{$field}  eq ''){
                    $_->{$field} = ' ';
                }
            }
        }
        if (%queries){
            use Storable 'dclone';
            my $tmp_data = dclone $_;
            for my $relation ( keys %queries ){
                my @ids_where;
                if ( ref $where->{'$or'} eq 'HASH' ) {
                    @ids_where = $where->{'$or'}->{$relation}->{'$in'};
                }
                else {
                    push @ids_where, _array $where->{$relation}->{'$in'}
                }
                my %ids_where = map { $_ => 1 } @ids_where;
                for my $field (_array $_->{$relation}){
                    next unless $ids_where{$field}; # Only data from request
                    if ( exists $queries{$relation}{$field} ){ #mids
                        my %tmp_row;
                        my $i = 1;
                        my $value;
                        my %alias;
                        $tmp_data->{$relation} = $field;
                        for my $select (@selects){
                            if ($i % 2 == 0){
                                if (exists $categories_queries->{$select}->{$field}){
                                    my @fields = split( /\./, $value);
                                    my $tmp_value = $categories_queries->{$select}->{$field};
                                    for my $inner_field ( @fields ) {
                                        if($tmp_value->{$inner_field}){
                                            $tmp_value = $tmp_value->{$inner_field};
                                        } else {
                                            $tmp_value = $tmp_data->{$inner_field};
                                        }
                                    }
                                    my $tmp_ref = $tmp_data;
                                    for my $inner_field ( @fields ) {
                                        if ( ref $tmp_ref->{$inner_field} eq 'HASH' ){
                                            $tmp_ref = $tmp_ref->{$inner_field};
                                        } else{
                                            $tmp_ref->{$inner_field . "_$select"}= $tmp_value;
                                            $meta_cfg_report{$inner_field . "_$select"} = $meta_cfg_report{$inner_field};
                                            delete $tmp_ref->{$inner_field} if ($inner_field ne $relation && $tmp_ref->{$inner_field . "_$select"});
                                        }
                                    }
                                    $tmp_ref->{'mid' . "_$select"} = $categories_queries->{$select}->{$field}->{mid} // $tmp_data->{mid};
                                    $tmp_ref->{'category_color' . "_$select"} = $categories_queries->{$select}->{$field}->{category}->{color} // $tmp_data->{category}->{color};
                                    $tmp_ref->{'category_name' . "_$select"} = $categories_queries->{$select}->{$field}->{category}->{name} // $tmp_data->{category}->{name};
                                    $tmp_ref->{'modified_on' . "_$select"} = $categories_queries->{$select}->{$field}->{modified_on} // $tmp_data->{modified_on};
                                    $tmp_ref->{'modified_by' . "_$select"} = $categories_queries->{$select}->{$field}->{modified_by} // $tmp_data->{modified_by};
                                    $tmp_ref->{$relation . "_$select"} = $field;
                                }else{
                                    my @fields = split( /\./, $value);
                                    my $tmp_value = $tmp_data;
                                    for my $inner_field ( @fields ) {
                                        if($tmp_value->{$inner_field} || $tmp_data->{$inner_field}){
                                            $tmp_value = $tmp_value->{$inner_field} // $tmp_data->{$inner_field};
                                        } else { $tmp_value = undef };
                                    }
                                    my $tmp_ref = $tmp_data;
                                    for my $inner_field ( @fields ) {
                                        if ( ref $tmp_ref->{$inner_field} eq 'HASH' ){
                                            $tmp_ref = $tmp_ref->{$inner_field};
                                        }
                                        else{
                                            if ( $tmp_value ) {
                                                $tmp_ref->{$inner_field . "_$select"} = $tmp_value;
                                                $meta_cfg_report{$inner_field . "_$select"} = $meta_cfg_report{$inner_field};# if (($meta_cfg_report{$inner_field}) && ($meta_cfg_report{$inner_field} eq 'release' || $meta_cfg_report{$inner_field} eq 'topic' || $meta_cfg_report{$inner_field} eq 'ci'));
                                                delete $tmp_ref->{$inner_field} if ($inner_field ne $relation && $tmp_ref->{$inner_field . "_$select"});
                                            }
                                        }
                                    }
                                }
                                $value = '';
                            }else{
                                $value = $select;
                            }
                            $i++;
                        }
                    }
                }
            }
            push @parse_data, $tmp_data;
        }else{
            my $parse_category = $_->{category}{name};
            foreach my $field (keys $_){
                $_->{$field . "_$parse_category"} = $_->{$field};
            }
        }
    } @data;

    @parse_data = @data if !@parse_data;

    my %scope_topics;
    my %scope_cis;
    my %all_labels = map { $_->{id} => $_ } $mdb2->label->find->all;
    my %ci_columns;

    my $cont=1;
    my @topics = map {
        my %row = %$_;

        for my $k ( keys %row ) {
            my $v = $row{$k};

            $row{$k} = Class::Date->new($v)->string if $k =~ /modified_on|created_on/;

            my $mt = $meta_cfg_report{$k} || $meta{$k}{meta_type} || '';
            if( $mt =~ /revision|ci|project|user|file/ ) {
                $row{ '_' . $k } = $v;
                $row{$k} = $scope_cis{$v} // do {
                    my @objs = $mdb2->master_doc->find({ '$or' => [{name => mdb->in(_array $v) },{ mid => mdb->in( _array($v) )}]},{ _id => 0 } )->all;
                    my @values;
                    if (@objs) {
                        for my $obj (@objs) {
                            my $tmp;
                            if ( $mt =~ /ci|project|user|file/ ) {
                                $tmp = $obj->{name} ? $obj->{name} : $obj->{moniker};
                            }
                            else {
                                $tmp = $obj->{name};
                            }
                            push @values, $tmp;
                        }
                        $scope_cis{$v} = \@values;

                    }
                    \@values;
                };
                for my $category (@All_Categories) {
                    $row{ $k . "_$category" } = $row{$k};
                    $row{ '_' . $k . "_$category" } = $row{ '_' . $k };
                }
            } elsif( $mt =~ /release|topic/ ) {
                $row{$k} = $scope_topics{$v}
                    // do {
                        my $meta = model->Topic->get_meta($_->{mid});
                        my $v_ref = $v;
                        $v_ref = ["$v_ref"] if ref $v_ref ne 'ARRAY';
                        my $field_meta = [ grep { $_->{id_field} eq $k } _array($meta) ]->[0];
                        my $rel_field = $field_meta->{release_field};
                        my $dir_from = "from_mid";
                        my $dir_to = "to_mid";
                        if ($rel_field){
                            $dir_from = "to_mid";
                            $dir_to = "from_mid";
                        } else {
                            $rel_field = $field_meta->{id_field};
                        }
                        my @mid_objs = map { $_->{$dir_to} } mdb->master_rel->find({$dir_from=>$_->{mid},rel_type=>"topic_topic",rel_field=>$rel_field})->all;
                        push $v_ref, $_ for @mid_objs;
                        my @objs = $mdb2->topic->find({ mid=>mdb->in( _array($v_ref) ) })->fields({ title=>1, mid=>1, is_changeset=>1, is_release=>1, category=>1, _id=>0 })->all;
                        $scope_topics{$_->{mid}} = $_ for @objs;
                        \@objs;
                    };
            } elsif( $mt eq 'calendar' && ( my $cal = ref $row{$k} ? $row{$k} : undef ) ) {
                for my $slot ( keys %$cal ) {
                    $cal->{$slot}{$_} //= '' for qw(end_date plan_end_date start_date plan_start_date);
                }
                for my $category (@All_Categories){
                    $row{$k. "_$category"} = $cal;
                }
            }elsif( $mt =~ /history/ ) {
                my @status_changes = Baseliner->model('Topic')->status_changes( $_->{mid} );
                my $html = '<div style="width:250px">';
                for my $ch ( grep { $_->{old_status} ne $_->{status}} @status_changes ) {
                    $html .= '<p style="font: 10px OpenSans, Lato, Calibri, Tahoma; color: #111;"><b>'. $ch->{old_status} .'</b> -> <b>'. $ch->{status} .' </b>  (' . Util->ago( $ch->{when} ) . ') </p>'."\n";
                }
                $html .= '</div>';
                $row{$k} = $html;
                for my $category (@All_Categories){
                    $row{$k. "_$category"} = $html;
                }
            }

            my $parse_key =  $k;

            if ( exists $selects_ci_columns{$parse_key} ) {
                if ( $v ne '' && $v ne ' '){
                    if (ref $v){
                        my @tmp;

                        for my $v_item (_array $row{'_'.$k} // $v){
                            try{
                                if ($v_item ne '' && $v_item ne ' '){
                                    my $ci = ci->new($v_item);
                                    my $ci_extends;
                                    if(exists $selects_ci_columns_collection_extends{$parse_key}){
                                        my @mid_extends = map { $_->{mid} } $ci->related( where => {collection => $selects_ci_columns_collection_extends{$parse_key}});
                                        $ci_extends = ci->new($mid_extends[0]) if @mid_extends;
                                    }

                                    for my $ci_column (_array $selects_ci_columns{$parse_key}){
                                        if ( exists $ci_columns{$parse_key.'_'.$ci_column} ) {
                                            my @tmp = _array $ci_columns{$parse_key.'_'.$ci_column};
                                            if ($ci->{$ci_column}){
                                                push @tmp,  $ci->{$ci_column};
                                             }else{
                                                if (ref ($ci_extends->{$ci_column}) =~ /^BaselinerX::CI::/){
                                                    push @tmp,  $ci_extends->{$ci_column}->{name};
                                                }else{
                                                    push @tmp,  $ci_extends->{$ci_column};
                                                };
                                            }

                                            $ci_columns{$parse_key.'_'.$ci_column} = \@tmp;
                                        }else{
                                            if ($ci->{$ci_column}){
                                                $ci_columns{$parse_key.'_'.$ci_column} = $ci->{$ci_column}
                                            }else{
                                                if (ref ($ci_extends->{$ci_column}) =~ /^BaselinerX::CI::/){
                                                     $ci_columns{$parse_key.'_'.$ci_column} = $ci_extends->{$ci_column}->{name};
                                                }else{
                                                    $ci_columns{$parse_key.'_'.$ci_column} = $ci_extends->{$ci_column}
                                                };
                                            }
                                        }
                                    }
                                }
                            }catch{
                                _log("Key: $k");
                                _log("Error Valor:($v)" );
                            };
                        }

                    }else{
                        my $value = $row{'_'.$k} // $v;
                        if(  $value ne '' && $value ne ' '){
                            my $ci = ci->new($value);
                            my $ci_extends;
                            if(exists $selects_ci_columns_collection_extends{$parse_key}){
                                my @mid_extends = map { $_->{mid} } $ci->related( where => {collection => $selects_ci_columns_collection_extends{$parse_key}});
                                $ci_extends = ci->new($mid_extends[0]) if @mid_extends;
                            }

                            for my $ci_column (_array $selects_ci_columns{$parse_key}){
                                if ($ci->{$ci_column}){
                                    $ci_columns{$parse_key.'_'.$ci_column} = $ci->{$ci_column}
                                }else{
                                    if (ref ($ci_extends->{$ci_column}) =~ /^BaselinerX::CI::/){
                                         $ci_columns{$parse_key.'_'.$ci_column} = $ci_extends->{$ci_column}->{name};
                                    }else{
                                        $ci_columns{$parse_key.'_'.$ci_column} = $ci_extends->{$ci_column}
                                    };
                                }
                            }
                        }
                    }
                }
            }
        }
        $row{topic_mid} = $row{mid};

        # labels
        if($row{labels}){
            my @tmp_labels;
            map {
                my $id=$_;
                my $r = $all_labels{$id};
                if($r->{name} && $r->{color}){
                    push @tmp_labels, $id . ";" . $r->{name} . ";" . $r->{color};
                }else{
                    push @tmp_labels, $id // '';
               }
            } _array( $row{labels} );
            $row{labels} = \@tmp_labels;
        }

        $row{category_color} = $row{category}{color};
        $row{category_name} = $row{category}{name};
        $row{category_id} = $row{category}{id};
        $row{status_new} = $row{category_status}{name};

        if($row{category_status}){
            foreach my $key (keys %{$row{category_status}}){
                $row{'category_status_'.$key} = $row{category_status}{$key};
                for my $category (@All_Categories){
                    $row{'category_status_'.$key.'_'.$category} = $row{category_status}{$key};
                }
            }
        }

        foreach my $key (keys %ci_columns){
            $row{$key} = $ci_columns{$key};
        }

        %ci_columns = ();
        \%row;
    } @parse_data;
    # order data with text not ci-mid.
    if (@sort) {
        if (defined $meta_cfg_report{$rs_sort[0]} && $meta_cfg_report{$rs_sort[0]} =~ /ci|project/){
            @topics = sort { $rs_sort[1] eq '1' ? lc($a->{$rs_sort[0]}[0]) cmp lc($b->{$rs_sort[0]}[0]) : lc($b->{$rs_sort[0]}[0]) cmp lc($a->{$rs_sort[0]}[0]) } @topics;
        } elsif (defined $meta_cfg_report{$rs_sort[0]} && $meta_cfg_report{$rs_sort[0]} !~ /release|topic/){
            @topics = sort { $rs_sort[1] eq '1' ? lc($a->{$rs_sort}) cmp lc($b->{$rs_sort}) : lc($b->{$rs_sort}) cmp lc($a->{$rs_sort}) } @topics;
        }
    }

    return ( 0+$cnt, @topics );
}

1;
