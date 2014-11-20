package BaselinerX::CI::report;
use Baseliner::Moose;
use Baseliner::Utils;
use v5.10;
use Try::Tiny;

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

sub icon { '/static/images/icons/report.png' }

sub rel_type {
    {
    user  => [from_mid => 'report_user'],
    }
}

sub root_reports {
    my ($self,$p) = @_;

    my @usersandroles = map { 'role/'.$_->{id}} Baseliner->model('Permissions')->user_roles( $p->{username} );
    push @usersandroles, 'user/'.ci->user->find_one({name => $p->{username}})->{mid};
    push @usersandroles, undef;

    my @searches = $self->search_cis( sort=>"name" );
    my @public;
    for my $folder ( @searches ){
        push @public,{
            mid     => $folder->mid,
            text    => sprintf( '%s (%s)', $folder->name, $folder->owner ), 
            icon    => '/static/images/icons/topic.png',
            menu    => [ ],
            data    => {
                click   => {
                    icon    => '/static/images/icons/topic.png',
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
                text => _loc('Public Reports'),
                icon => '/static/images/icons/report.png',
                url => '/ci/report/public_searches',
                mid => -1,
                draggable => \0,
                children => $public,
                data => [],
                expanded => \1,
            }
    );
    #root user can view all reports of all users.
    if (Baseliner->model('Permissions')->is_root( $p->{username} )){
        my $root_reports = $self->root_reports({ meta=>\%meta, username=>$p->{username} });
        push @trees, ({
                text => _loc('All') . " (Root)",
                icon => '/static/images/icons/report.png',
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
            icon => '/static/images/icons/table.png',
            mid => -1,
            draggable => \0,
            children => $reports_available,
            url => '/ci/report/reports_available',
            data => [],
            expanded => \1,
        });
        push @trees, ({
            text => _loc('Rule Reports'),
            icon => '/static/images/icons/table.png',
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
                    icon    => '/static/images/icons/topic.png',
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
    my ($self,$p) = @_;
    my $userci = Baseliner->user_ci( $p->{username} );
    my $username = $p->{username};
    my @tree;
    for my $rule ( mdb->rule->find({ rule_type=>'report' })->sort({ id=>1 })->all ) {
        my $n = {
            key => "$$rule{_id}",
            text => $$rule{rule_name},
            icon => '/static/images/icons/rule.png',
            leaf => \1,
            data    => {
                click   => {
                    icon    => '/static/images/icons/topic.png',
                    url     => '/comp/topic/topic_report.js',
                    type    => 'eval',
                    title   => $$rule{rule_name},
                },
                id_report_rule => "$$rule{_id}",
                report_name    => $$rule{rule_name},
                hide_tree      => \1,
                #custom_form    => $reg->form,    
            }
        };
        push @tree, $n;
    }
    return \@tree;
}

sub report_meta {
    my ($self,$p) = @_;
    _debug( $p );
    my $key = $p->{key};
    my $config = $p->{config} // {};
    if( my $id = $p->{id_report_rule} ) {
        my $cr = Baseliner::CompiledRule->new( _id=>$p->{id_report_rule} );
        my $stash = {};
        $cr->compile;
        $cr->run( stash=>$stash ); 
        return $stash->{report_meta} // {};  # grid_params, 
    } elsif( my $key = $p->{id_report} ) {
        my $report = Baseliner->registry->get( $key );
        return $report->meta_handler->( $config );
    } else {
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

    my @usersandroles = map { 'role/'.$_->{id}} model->Permissions->user_roles( $p->{username} );
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
			icon    => '/static/images/icons/topic.png',
			menu    => [ ],
			data    => {
				click   => {
					icon    => '/static/images/icons/topic.png',
					url     => '/comp/lifecycle/report_run.js',
					type    => 'eval',
					title   => $folder->name,
				},
			# 	#store_fields   => $folder->fields,
			# 	#columns        => $folder->fields,
			# 	fields         => $folder->selected_fields({ meta => $p->{meta}, username => $p->{username} }),
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
    
    my $user = Baseliner->user_ci( $username );
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
                if( @cis && $cis[0]->mid != $self->mid ) {
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
    push @tree, _unique grep { defined } map { $$_{id_field} } _array( model->Topic->get_meta );
    return \@tree;
}

sub all_fields {
    my ($self,$p) = @_;
	
	my $username = $p->{username};
	my @cats = Baseliner->model('Topic')->get_categories_permissions( username => $username, type => 'view' );
    my @tree;
	
	# Fields that are common to every topic (system fields)
	my $id_category = $p->{id_category} ? $p->{id_category} : undef;
	my $name_category = $p->{name_category} ? Util->_name_to_id($p->{name_category}) : undef;
	
	
	my %categories;
    $categories{$id_category} = $name_category if($id_category);
	my $user_categories_fields_meta = Baseliner->model('Users')->get_categories_fields_meta_by_user( username => $username );	
	
	
	my @fieldlets = _array( Baseliner->model('Topic')->get_meta(undef, $id_category, $username) );

	if(!$id_category){	
		my @children =	map {
							my $name_id  = Util->_name_to_id($_->{name});
							my @fields = map { [ $_, _loc($user_categories_fields_meta->{$name_id}->{$_}->{name_field})] } 
										 keys $user_categories_fields_meta->{$name_id} ;
				
							$_->{text} 	= $_->{name};
							$_->{icon}	='/static/images/icons/topic_one.png';
							$_->{data}	= {
								'id_category' 	=> $_->{id},
								'name_category' => $_->{name},
								'fields' 		=> \@fields};
							$_->{type}='category'; $_->{leaf}=\0;
							$_
						} 
						sort { defined($a->{name_field})  cmp defined($b->{name_field})  }
						@cats;
		
		push @tree, (
			{ 	text		=> _loc('Categories'),
				leaf		=> \0,
				draggable 	=> \0,
				expanded 	=> \1,
				icon 		=> '/static/images/icons/topic_one.png',
				children 	=> \@children
			}
		);
		
        my $reports_config = Baseliner->model( 'ConfigStore' )->get( 'config.reports' );
        if ($reports_config->{fields_dynamics} ne 'NO'){
            my $has_action = Baseliner->model('Permissions')->user_has_action( username=> $username, action => 'action.reports.dynamics' );
            if($has_action){
                push @tree, {
                    text => _loc('Dynamic'),
                    leaf => \0,
                    icon     => '/static/images/icons/all.png',
                    url  => '/ci/report/dynamic_fields',
                    draggable => \0,
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
            }
        }
	}
	else{
		map { 
			push @tree, { 
				text        => _loc($user_categories_fields_meta->{$name_category}->{$_}->{name_field}),
				id_field	=> $_,
				icon        => '/static/images/icons/field-add.png',
				type        => 'select_field',
				meta_type   => $user_categories_fields_meta->{$name_category}->{$_}->{meta_type},
				collection  => $user_categories_fields_meta->{$name_category}->{$_}->{collection},
                collection_extends  => $user_categories_fields_meta->{$name_category}->{$_}->{collection_extends},
				ci_class	=> $user_categories_fields_meta->{$name_category}->{$_}->{ci_class},
				filter      => $user_categories_fields_meta->{$name_category}->{$_}->{filter},				
				gridlet     => $user_categories_fields_meta->{$name_category}->{$_}->{gridlet},
				category    => $p->{name_category},
				leaf        =>\1
			};
		
		}
		sort { lc $a cmp lc $b }
		keys $user_categories_fields_meta->{$name_category}; 		
		
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
        my %meta_temp = map {  $_->{id_field} => $_ } _array( Baseliner->model('Topic')->get_meta(undef, undef, $p->{username}) );
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
					if($type->{value} eq 'default'){
						my $collection = $filter->{collection} // $filter->{ci_class} ;
						my @cis;
						my (@options, @values);
						
						my @cols_roles = Baseliner->model('Permissions')->user_projects_ids_with_collection( username => $p->{username} );
						my $sw_finded = 0;
						for my $collections ( @cols_roles ) {
							if(exists $collections->{$collection}){
								$sw_finded = 1;
								for my $key (keys $collections->{$collection}){
									push @cis, ci->search_cis( collection => $collection, mid => $key );
								}
							}
						}
						@cis = ci->search_cis( collection => $collection ) if ($sw_finded == 0);						
						
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
    my ($self, $p ) = @_;
	my $filters_where = $p->{filters_where};
	my $name_category = $p->{name_category};
	my %dynamic_filter = %{$p->{dynamic_filter}};
	my $where = $p->{where};
	
	map {
		if (!exists $_->{category} || $_->{category} eq $name_category){
			my $field=$_;
			my $id = $field->{meta_where_id} // $where_field_map{$_->{id_field}} // $field->{id_field};
			my @chi = _array($field->{children});
			
			#_log ">>>>>>>>>>>>>>>>>>>>>>>ID_FIELD: " . $_->{id_field};
			#_log ">>>>>>>>>>>>>>>>>>>>>>>ID XXXXXXX: " . _dump $field;
			
			for my $val ( @chi ) {
				my $id_field_category = $id . "_$name_category";
				my $cond;
				#_log ">>>>>>>>>>>>>>>>>>>>>>>CHILDREN: " . _dump $val;
				if(exists $dynamic_filter{$id_field_category} && $dynamic_filter{$id_field_category}->{category} eq $name_category ) {
					given ($dynamic_filter{$id_field_category}->{type}) {
						when ('numeric') {
							for (my $i = 0; $i < scalar @{$dynamic_filter{$id_field_category}->{oper}}; $i++){
								if ($dynamic_filter{$id_field_category}->{oper}[$i] eq 'eq'){
									$cond = $dynamic_filter{$id_field_category}->{value}[$i];
								}else{
									$cond->{'$'.$dynamic_filter{$id_field_category}->{oper}[$i]} = $dynamic_filter{$id_field_category}->{value}[$i];
								}
							}
						};
						when ('list') {
							my @parse;
							for my $value (_array $dynamic_filter{$id_field_category}->{value}){
								if( $value eq '-1'){
									push @parse, '';
									push @parse, undef;
									push @parse, [];
								}else{
									push @parse, $value;	
								}
							}
							if (scalar @parse > 1){
								$cond = { '$in' => \@parse };	
							}else{
								$cond = $parse[0];	
							}
						};
						when ('string') {
							if( $val->{oper} =~ /^(like|not_like)$/ || $val->{value} eq 'default' ) {
								#filtros join tratamiento mid string
								if ($val->{where} eq 'ci'){
									$cond = $dynamic_filter{$id_field_category}->{value};		
								}
								else{
									$val->{value} = qr/$dynamic_filter{$id_field_category}->{value}/i;
									if ($val->{oper} eq 'not_like'){
										$cond = { '$not' => $val->{value} };	
									}else{
										$cond = $val->{value};	
									}	
								}
							}else{
								$val->{value} = $dynamic_filter{$id_field_category}->{value};
								if ($val->{oper}){
									$cond = { $val->{oper} => $val->{value}  };
								}else{
									$cond = $val->{value};
								}
							}
						};
						when ('date') {
							for (my $i = 0; $i < scalar @{$dynamic_filter{$id_field_category}->{oper}}; $i++){
								if ($dynamic_filter{$id_field_category}->{oper}[$i] eq 'eq'){
									$cond = $dynamic_filter{$id_field_category}->{value}[$i];	
								}else{
									$cond->{'$'.$dynamic_filter{$id_field_category}->{oper}[$i]} = $dynamic_filter{$id_field_category}->{value}[$i];	
								}
							}
						}
					}
					$where->{$id} = $cond;
				}
				else{
					if($val->{value}){
						given ($val->{field}) {
							when ('number') {
								if($val->{value} ne 'default'){
									if (exists $where->{$id}){
										$where->{$id}->{$val->{oper}} = $val->{value} + 0;
									}else{
										$cond = { $val->{oper} => $val->{value} + 0 };
										$where->{$id} = $cond;	
									}
								}
							}
							when ('string') {
								if($val->{value} ne 'default'){
									if( $val->{oper} =~ /^(like|not_like)$/ ) {
										$val->{value} = qr/$val->{value}/i;
										if ($val->{oper} eq 'not_like'){
											$cond = { '$not' => $val->{value} };	
										}else{
											$cond = $val->{value};	
										}								
									}
									else{
										if ($val->{oper}){
											$cond = { $val->{oper} => $val->{value}  };
										}else{
											$cond = $val->{value};
										}
									}
									$where->{$id} = $cond;
								}
							}
							when ('date') {
								if($val->{value} ne 'default'){
									if (exists $where->{$id}){
										$where->{$id}->{$val->{oper}} = $val->{value};	
									}
									else{
                                        if ($val->{oper} eq ''){
                                            $where->{$id} = $val->{value};
                                        }else{
                                            $cond = { $val->{oper} => $val->{value} };
                                            $where->{$id} = $cond;
                                        }
									}
								}
							}
							when ('status') {
								if($val->{value} ne 'default'){
									if (exists $where->{$id}){
										$where->{$id}->{$val->{oper}} = $val->{value};	
									}
									else{
										$cond = { $val->{oper} => $val->{value} };
										$where->{$id} = $cond;
									}
								}
							}						
							default{
								if($val->{value} ne 'default'){
									if ($val->{oper}){
										$cond = { $val->{oper} => $val->{value} };
									}else{
										$cond = $val->{value};
									}
									$where->{$id} = $cond;
								}
							}
						}
					}
				}
			}
		}
	} _array($filters_where);
	#_log ">>>>>>>>>>>>>>>>>>>>>FILTER WHERE: " . _dump $filters_where;
	#_log ">>>>>>>>>>>>>>>>>>>>>WHERE: " . _dump $where;
	return $where;
}


method run( :$start=0, :$limit=undef, :$username=undef, :$query=undef, :$filter=undef, :$query_search=undef ) {
    # setup a temporary alternative connection if configured
    my $has_rep_db = exists Baseliner->config->{mongo}{reports};
    my $db2 =
        Baseliner::Mongo->new( 
            mongo_client => Baseliner->config->{mongo}{reports}{client} // mdb->connection, 
            db_name => Baseliner->config->{mongo}{reports}{db_name} // mdb->db_name )
        if $has_rep_db;
    # so we can connect to a secondary:
    local $MongoDB::Cursor::slave_okay = 1 if $has_rep_db;
    # make mdb point to $db2 for now
    local $Clarive::_mdb = $db2 if $has_rep_db;

    my $rows = $limit // $self->rows;

	my $rel_query;
	for my $selected (_array( $self->selected )){
		if (exists $selected->{query}){
			$rel_query = $selected->{query};
			last;
		}
	};
	#_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>QUERY: " . _dump $rel_query;
    # _log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>QUERY: " . _dump $self->selected;
    
    my %fields = map { $_->{type}=>$_->{children} } _array( $self->selected );
    my %meta = map { $_->{id_field} => $_ } _array( Baseliner->model('Topic')->get_meta(undef, undef, $username) );  # XXX should be by category, same id fields may step on each other
    my @selects = map { ( $_->{meta_select_id} // $select_field_map{$_->{id_field}} // $_->{id_field} ) => $_->{category} } _array($fields{select});
    # _log ">>>>>>>>>>>>>>>>>>>>>>>FIELDS: " . _dump %fields;

    my %selects_ci_columns = map { ( $_->{meta_select_id} // $select_field_map{$_->{id_field}} // $_->{id_field} ) . '_' . $_->{category} => $_->{ci_columns} } grep { exists $_->{ci_columns}} _array($fields{select});
    my %selects_ci_columns_collection_extends = map { ( $_->{meta_select_id} // $select_field_map{$_->{id_field}} // $_->{id_field} ) . '_' . $_->{category} => $_->{collection_extends} } grep { exists $_->{ci_columns}} _array($fields{select});
    my %meta_cfg_report = map { $_->{id_field} => $_->{meta_type} } _array($fields{select});

    # _log ">>>>>>>>>>>>>>>>>>>>>SELECT FIELDS: " . _dump $self->selected ;
    # _log ">>>>>>>>>>>>>>>>>>>>>SELECT FIELDS CI COLUMNS: " . _dump %selects_ci_columns;
    # _log ">>>>>>>>>>>>>>>>>>>>>SELECT FIELDS CI COLUMNS COLLECTION: " . _dump %selects_ci_columns_collection_extends;

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
			
			#_log ">>>>>>>>>>>>>>>>>>>>FILTRO CATEGORIA: " . $flt->{category};
			
			#Excepción
			if ( exists $dynamic_filter{'category_status_name_' . $flt->{category}} ){
				$dynamic_filter{'status_new_' . $flt->{category}} = $dynamic_filter{'category_status_name_' . $flt->{category}};
			}
		};
	}
	
	my $where;
	my %queries;
	my $categories_queries;
	
	my @All_Categories;

    _fail( _loc("Missing 'Categories' in search configuration") ) unless keys %{ $rel_query || {} };	
    
	foreach my $key (sort { $b <=> $a} keys $rel_query) {
        my $wh = {};
		my @ids_category = _array $rel_query->{$key}->{id_category};
		my @names_category = _array $rel_query->{$key}->{name_category};
		my @relation = _array $rel_query->{$key}->{relation};
        my $length = scalar @ids_category;
		map{
            $where = $self->get_where({filters_where => $fields{where}, name_category => $_, dynamic_filter => \%dynamic_filter, where => $where });
            $where->{id_category} = {'$in' => \@ids_category };
            my @data = mdb->topic->find($where)->all;
            if (@data && scalar @relation > 1) {
                my $rel_name;
                my $name_relation;
                my $length_rel = scalar @relation;
                for (my $i=0;$i<$length_rel;$i++){
                    if($relation[$i]){
                        $rel_name = $relation[$i]->{"relation"}[0];
                        $name_relation = $relation[$i]->{"name_category"}[0];
                        my @data_relation = mdb->topic->find({name_category=>qr/^$name_relation$/i})->all;
                        my %data_to_compare = map { $_->{mid} => 1 } @data_relation; 
                        my @all_mids;
                        map {
                            if (ref $_->{$rel_name} eq'ARRAY'){
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
                    #if exists mismatch rel_name...
                    if ($where->{$rel_name}) {
                        push @all_mids, _array $where->{$rel_name}->{'$in'};
                    }
                    $where->{$rel_name} = { '$in' => \@all_mids };
                    }
                }
            }
            push @All_Categories, $_;
        } @names_category;
	}	

	
    # filter user projects
    my $is_root = Baseliner->model('Permissions')->is_root( $username );
    if( $username && ! $is_root){
      my @categories;
        for my $category (@All_Categories) {
            my $id_category = mdb->category->find_one({name=>qr/^$category$/i})->{id};
            push @categories, $id_category;
        }
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @categories );
	}

    if( length $query ) {
		$where->{'mid'} = mdb->in($query);
    }

	if( exists $where->{'status_new'} ){
		$where->{'category_status.id'} = delete $where->{'status_new'};
	}
	
    my @sort = map { $_->{id_field} => 0+($_->{sort_direction} // 1) } _array($fields{sort});

    Baseliner->model('Topic')->build_field_query( $query_search, $where, $username ) if length $query_search;	

    my $rs = mdb->topic->find($where);
    my $cnt = $rs->count;
    $rows = $cnt if ($rows eq '-1') ;
    $rs->sort({ @sort });
    #_debug \%meta;
	
	my %select_system = (
		mid			=> 1,
		category	=> 1,
		modified_on	=> 1,
		modified_by	=> 1,
		labels		=> 1
	);
    my $fields = {  %select_system, map { $_=>1 } keys +{@selects}, _id=>0 };
    # _log "FIELDS==================>" . _dump( $fields );
    #_log "SORT==================>" . _dump( @sort );
    my @data = $rs
      ->fields($fields)
      ->skip( $start )
      ->limit($rows)
      ->all;
    my @parse_data;  
    map {
        foreach my $field (keys $fields){
            if (!exists $_->{$field}) {
                # _log ">>>>>>>>>>>>>>>>>Field: " . $field;
                next if ($field eq '_id' || $field eq '0');
                $_->{$field} = ' ';
                for my $category (@selects){
                    # $_->{$field. "_$category"} = $_->{$field};
                    # $meta_cfg_report{$field . "_$category"} = $meta_cfg_report{$field} if ($meta_cfg_report{$field});
                }                  
            }else{
                if ($_->{$field} && $_->{$field}  eq ''){
                    $_->{$field} = ' ';
                }

            }
        }
        if (%queries){
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
                    next unless $ids_where{$field}; #Para evitar que cuando haya filtros saque todos los correspondientes a la peticion
                    if ( exists $queries{$relation}{$field} ){ #mids
                        my %tmp_row;
                        my $i = 1;
                        my $value;
                        my %alias;
                        use Storable 'dclone';
                        my $tmp_data = dclone $_;
                        $tmp_data->{$relation} = $field;  
                        for my $select (@selects){
                            if ($i % 2 == 0){  
                                if (exists $categories_queries->{$select}){
                                    my @fields = split( /\./, $value);
                                    my $tmp_value = $categories_queries->{$select}->{$field};
                                    for my $inner_field ( @fields ) {
                                        $tmp_value = $tmp_value->{$inner_field};
                                    }
                                    #my $tmp_ref = $_;
                                    my $tmp_ref = $tmp_data;
                                    for my $inner_field ( @fields ) {
                                        if ( ref $tmp_ref->{$inner_field} eq 'HASH' ){
                                            $tmp_ref = $tmp_ref->{$inner_field};
                                        }
                                        else{
                                            $tmp_ref->{$inner_field . "_$select"}= $tmp_value;
                                            $meta_cfg_report{$inner_field . "_$select"} = $meta_cfg_report{$inner_field} if (($meta_cfg_report{$inner_field}) && ($meta_cfg_report{$inner_field} eq 'release' || $meta_cfg_report{$inner_field} eq 'topic'));
                                        }
                                    }
                                    $tmp_ref->{'mid' . "_$select"} = $field;
                                    $tmp_ref->{'category_color' . "_$select"} = $categories_queries->{$select}->{$field}->{category}->{color};
                                    $tmp_ref->{'category_name' . "_$select"} = $categories_queries->{$select}->{$field}->{category}->{name};
                                    $tmp_ref->{'modified_on' . "_$select"} = $categories_queries->{$select}->{$field}->{modified_on};
                                    $tmp_ref->{'modified_by' . "_$select"} = $categories_queries->{$select}->{$field}->{modified_by};
                                    $tmp_ref->{$relation . "_$select"} = $field; 
                                }else{
                                    my @fields = split( /\./, $value);
                                    my $tmp_value = $tmp_data;
                                    for my $inner_field ( @fields ) {
                                        $tmp_value = $tmp_value->{$inner_field};
                                    }
                                    my $tmp_ref = $tmp_data;
                                    for my $inner_field ( @fields ) {
                                        if ( ref $tmp_ref->{$inner_field} eq 'HASH' ){
                                            $tmp_ref = $tmp_ref->{$inner_field};
                                        }
                                        else{
                                            $tmp_ref->{$inner_field . "_$select"} = $tmp_value;
                                            # delete $tmp_ref->{$inner_field} if ($tmp_ref->{$inner_field . "_$select"});
                                            # $meta_cfg_report{$inner_field . "_$select"} = $meta_cfg_report{$inner_field} if ($meta_cfg_report{$inner_field});
                                        }
                                    }   
                                    # $tmp_ref->{$relation . "_$select"} = $field; 
                                }
                                $value = '';
                            }else{
                                $value = $select;
                            }
                            $i++;
                        }
                        push @parse_data, $tmp_data;
                    }
                }
            }
        }else{
            my $parse_category = $_->{category}{name};
            foreach my $field (keys $_){
                $_->{$field . "_$parse_category"} = $_->{$field};
            }
        }
    } @data;
    
    @parse_data = @data if !@parse_data;
    
    #_log ">>>>>>>>>>>>>>>>>>>>>>>DATA: " . _dump @parse_data;
    
    my %scope_topics;
    my %scope_cis;
    my %all_labels = map { $_->{id} => $_ } mdb->label->find->all;
    my %ci_columns;

    my @topics = map { 
        my %row = %$_;

        while( my($k,$v) = each %row ) {
            $row{$k} = Class::Date->new($v)->string if $k =~ /modified_on|created_on/;

            #my $mt = $meta{$k}{meta_type} // '';
            my $mt = $meta_cfg_report{$k} || $meta{$k}{meta_type} || '';
            #  get additional fields ?   
            #  TODO for sorting, do this before and save to report_results collection (capped?) 
            #       with query id and query ts, then sort
            #_error "MT===$mt, K==$k";

            if( $mt =~ /ci|project|revision|user|file/ ) {
                $row{'_'.$k} = $v;
				$row{$k} = $scope_cis{$v} 
					// do{ 
						my @objs = mdb->master_doc->find({ mid=>mdb->in($v) },{ _id=>0 })->all;
                        my @values;
                        if (@objs){
                        for my $obj (@objs){
                            my $tmp;

                            if ( $mt =~ /ci|project|user|file/ ) {
                                $tmp = $obj->{name} ? $obj->{name} : $obj->{moniker}; 
                            } else {
                                $tmp = $obj->{name};
                            }
                            push @values, $tmp;    
                        }
                        $scope_cis{$v} = \@values;

                        }
                        \@values;
				};
				for my $category (@All_Categories){
                    $row{$k. "_$category"} = $row{$k};
                    $row{'_'.$k. "_$category"} = $row{'_'.$k};
				}
            } elsif( $mt =~ /release|topic/ ) {
                $row{$k} = $scope_topics{$v} 
                    // do {
                        my @objs = mdb->topic->find({ mid=>mdb->in($v) },{ title=>1, mid=>1, is_changeset=>1, is_release=>1, category=>1, _id=>0 })->all;
                        $scope_topics{$_->{mid}} = $_ for @objs; 
                        \@objs;   
                    } if ($v);				
            } elsif( $mt eq 'calendar' && ( my $cal = ref $row{$k} ? $row{$k} : undef ) ) { 
                for my $slot ( keys %$cal ) {
                    $cal->{$slot}{$_} //= '' for qw(end_date plan_end_date start_date plan_start_date);
                }
            }elsif( $mt =~ /history/ ) {
                my $data;
                $data->{topic_mid} = $_->{mid};
                my @status_changes = Baseliner->model('Topic')->status_changes( $data );
                my $html = '<div style="width:250px">';
                for my $ch ( grep { $_->{old_status} ne $_->{status}} @status_changes ) {
                    $html .= '<p style="font: 11px OpenSans, Lato, Calibri, Tahoma; color: #111;"><b>'. $ch->{old_status} .'</b> -> <b>'. $ch->{status} .' </b>  (' . Util->ago( $ch->{when} ) . ') </p>'."\n";
                }
                $html .= '</div>';
                for my $category (@All_Categories){
                    $row{$k. "_$category"} = $html;
                }
            }

            #my $parse_key =  Util->_unac($k); 
            my $parse_key =  $k;

            if ( exists $selects_ci_columns{$parse_key} ) {
                #if ( $v ne '' && $v ne ' ' && !ref $v){
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
                                        $ci_extends = ci->new($mid_extends[0]);
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
                                $ci_extends = ci->new($mid_extends[0]);
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
                # for my $category (@All_Categories){
                #     if( !exists $row{'category_status' . "_$category"} ){
                #         $row{'category_status_'.$category."_$key"} = $row{category_status}{$key};
                #     }
                # }
			}
		}
        #$row{category_status_name} = $row{category_status}{name};
		
        #_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" . _dump %ci_columns;

        foreach my $key (keys %ci_columns){
            $row{$key} = $ci_columns{$key};
        }

        %ci_columns = ();
        \%row;
    #} @data;
	} @parse_data;
	
    #_debug @topics;
	#_log ">>>>>>>>>>>>>>>>>>>>>>>DATA: " . _dump @topics;
    return ( 0+$cnt, @topics );
}

1;


