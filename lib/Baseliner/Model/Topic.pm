package Baseliner::Model::Topic;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use Array::Utils qw(:all);
use v5.10;
use utf8;

BEGIN { extends 'Catalyst::Model' }

my $post_filter = sub {
        my ($text, @vars ) = @_;
        $vars[2] =~ s{\n|\r}{ }gs;
        $vars[2] =~ s{<(.+?)>}{}gs;
        $vars[2] = substr( $vars[2], 0, 30 ) . ( length $vars[2] > 30 ? "..." : "" );
        $vars[0] = "<b>$vars[0]</b>";  # bold username
        $vars[2] = "<quote>$vars[2]</quote>";  # quote post
        ($text,@vars);
    };

register 'action.search.topic' => { name => 'Search topics' };

register 'event.post.create' => {
    text => '%1 posted a comment: %3',
    description => 'User posted a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        template => '/email/generic_post.html',
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.post.edit' => {
    text => '%1 edited a comment: %3',
    description => 'User edited a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        template => '/email/generic_post.html',
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.post.delete' => {
    text => '%1 deleted a comment: %3',
    description => 'User deleted a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
    notify => {
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.post.mention' => {
    text => '%1 mentioned you in a comment #%2: %3',
    description => 'User mentioned another user in a comment',
    vars => ['username', 'mid', 'post', 'mentioned','ts'],
    filter => $post_filter,
    notify => {
        template => '/email/generic_post.html',
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.file.create' => {
    text => '%1 posted a file: %3',
    description => 'User uploaded a file',
    vars => ['username', 'ts', 'filename'],
};

register 'event.file.attach' => {
    text => '%1 attached %2',
    description => 'User attached a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.file.remove' => {
    text => '%1 removed %2',
    description => 'User removed a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.topic.file_remove' => {
    text => '%1 removed %2',
    description => 'User removed a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.topic.create' => {
    text => '%1 created a topic of %2',
    description => 'User created a topic',
    use_semaphore => 0,
    vars => ['username', 'category', 'ts', 'scope'],
    notify => {
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.topic.delete' => {
    text => '%1 deleted a topic of %2',
    description => 'User deleted a topic',
    use_semaphore => 0,
    vars => ['username', 'category', 'ts', 'scope'],
    notify => {
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.topic.modify' => {
    text => '%1 modified topic',
    description => 'User modified a topic',
    vars => ['username', 'topic_name', 'ts'],
    level => 1,
    notify => {
        scope => ['project', 'category', 'category_status'],
    },
    #Contemplar scope field y excluir por defecto.
};


register 'event.topic.modify_field' => {
    text => '%1 modified the field %2 from %3 to %4',
    description => 'User modified a topic',
    vars => ['username', 'field', 'old_value', 'new_value', 'text_new', 'ts',],
    filter=>sub{
        my ($txt, @vars)=@_;
       
        # TODO the idea here is to present the user with a diff in the activity log
        #require String::Diff;
        #($vars[2], $vars[3]) = String::Diff::diff(
        #    $brk->($vars[2]), $brk->($vars[3]),
        #    remove_open => '<del>',
        #    remove_close => '</del>',
        #    append_open => '<ins>',
        #    append_close => '</ins>',
        #    #escape       => sub { encode_entities($_[0]) },
        #);

        my $text_new = $vars[4];
        if( $text_new ) {
            $txt = $text_new;
        }
        else {
            #$txt = '';
            require Algorithm::Diff::XS;
            my $brk = sub { my $x = ""; $x=_strip_html(shift); $x//=''; [ $x =~ m{([\w|\.|\-]+)}gs ] };
            my $aa = $brk->($vars[2]);
            my $bb = $brk->($vars[3]);
            my $d =Algorithm::Diff::XS::sdiff( $aa, $bb );
            my @diff;
            my @bef;
            my @aft;
            for my $ix ( 0..$#{ $d } ) {
                my ($st,$bef,$aft) = @{ $d->[$ix] };
                unless( $st eq 'u' ) {
                    push @bef, "$bef" if length $bef;
                    push @aft, "$aft" if length $aft;
                }
            }
            if( @bef || @aft ) {
                my $bef = join( ' ', @bef );
                my $aft = join( ' ', @aft );
                $bef = substr( $bef, 0, 50 ) . '...' if length $bef > 50;
                $aft = substr( $aft, 0, 50 ) . '...' if length $aft > 50;
                $vars[2] = @bef ? '<code>' . $bef . '</code>' : '<code>-</code>';
                $vars[3] = @aft ? '<code>' . $aft . '</code>' : '<code>-</code>';
            } else {
                $txt = '%1 modified the field %2';
            }
        }
        return ($txt, @vars);
    },
    notify => {
        #scope => ['project', 'category', 'category_status', 'baseline'],
        scope => ['project', 'category', 'category_status', 'field'],
    }    
};

register 'event.topic.change_status' => {
    text => '%1 changed topic status from %2 to %3',
    vars => ['username', 'old_status', 'status', 'ts'],
    notify => {
        #scope => ['project', 'category', 'category_status', 'baseline'],
        scope => ['project', 'category', 'category_status'],
    }
};

register 'action.topics.logical_change_status' => {
    name => 'Change topic status logically (no deployment)'
};

register 'registor.action.topic_category' => {
    generator => sub {
        my %type_actions_category = (
            create => 'Can create topic for category `%1`',
            view   => 'Can view topic for category `%1`',
            edit   => 'Can edit topic for category `%1`',
            delete => 'Can delete topic in category `%1`',
            comment => 'Can add/view comments in topics of category `%1`',
        );

        my @categories = mdb->category->find->sort({ name=>1 })->fields({ id=>1, name=>1 })->all;

        my %actions_category;
        foreach my $action ( keys %type_actions_category ) {
            foreach my $category (@categories) {
                my $id_action = 'action.topics.' . _name_to_id( $category->{name} ) . '.' . $action;
                $actions_category{$id_action} = { id => $id_action, name => _loc($type_actions_category{$action},$category->{name}) };
            }
        }
        return \%actions_category;
    }
};

register 'registor.action.topic_category_fields' => {
    generator => sub {
        my @categories = mdb->category->find->sort({ name=>1 })->fields({ id=>1, name=>1 })->all;
        
        my %actions_category_fields;
        my %statuses = ci->status->statuses;
        for ( values %statuses ) {
            $$_{name_id} = _name_to_id($$_{name});
        }
        foreach my $category (@categories){
            my $meta = Baseliner::Model::Topic->get_meta( undef, $category->{id} );    
            my $cat_statuses = mdb->category->find_one({ id=>''.$category->{id} })->{statuses};
            my @statuses2 = @statuses{ _array($cat_statuses) };

            my $msg_view = 'Cannot view the field %1 in category %2';
            my $msg_edit_s = 'Can edit the field %1 in category %2 for the status %3';
            my $msg_view_s = 'Cannot view the field %1 in category %2 for the status %3';
        
            my $cat_to_id = _name_to_id( $category->{name} );
            
            my $id_action;
            my $description;
            
            for my $field (_array $meta){
                my $field_to_id = _name_to_id($field->{name_field});
                if ($field->{fields}) {
                	my @fields_form = _array $field->{fields};
                    
                    for my $field_form (@fields_form){
                        my $field_form_to_id = _name_to_id($field_form->{id_field});
                        $id_action = join '.', 'action.topicsfield', $cat_to_id, $field_to_id, $field_form_to_id, 'read';
                        $description = _loc($msg_view, $field_form->{name_field}, $category->{name} );
                        $actions_category_fields{$id_action} = { id => $id_action, name => $description };
                        for my $status (@statuses2){
                            $id_action = join '.', 'action.topicsfield', $cat_to_id, $field_to_id, $field_form_to_id, $status->{name_id}, 'write';
                            $description = _loc($msg_edit_s, $field_form->{name_field}, $category->{name}, $status->{name});
                            $actions_category_fields{$id_action} = { id => $id_action, name => $description };
                        }                    
                    }
                }
                else{
                    $id_action = 'action.topicsfield.' . $cat_to_id . '.' . $field_to_id . '.read';
                    $description = _loc($msg_view, $field->{name_field}, $category->{name});
                    $actions_category_fields{$id_action} = { id => $id_action, name => $description };
                    for my $status (@statuses2){
                        next unless length($cat_to_id) && length($field_to_id) && length($status->{name_id});
                        $id_action = 'action.topicsfield.' . $cat_to_id . '.' . $field_to_id . '.' . $status->{name_id} . '.write';
                        $description = _loc($msg_edit_s, $field->{name_field}, $category->{name}, $status->{name} );
                        $actions_category_fields{$id_action} = { id => $id_action, name => $description };
                        $id_action = 'action.topicsfield.' . $cat_to_id . '.' . $field_to_id . '.' . $status->{name_id} . '.read';
                        $description = _loc($msg_view_s, $field->{name_field}, $category->{name}, $status->{name} );
                        $actions_category_fields{$id_action} = { id => $id_action, name => $description };
                    }
                }
            }
        }
        return \%actions_category_fields;    
    }
};

sub build_field_query {
    my ($self,$query,$where,$username) = @_;
    my %all_fields = map { $_->{id_field} => undef } _array($self->get_meta(undef,undef,$username));
    mdb->query_build( where=>$where, query=>$query, fields=>['mid', 'category.name', 'category_status.name', '_txt', keys %all_fields] ); 
}

sub build_sort {
    my ($self,$sort,$dir) =@_;
    my $order_by;
    if( $sort eq 'topic_name' ) {
        $order_by = mdb->ixhash( created_on=>$dir, mid=>$dir );  # TODO "m" is the numeric mid, should change eventually
    } elsif( ($sort eq 'category_status_name') || ($sort eq 'modified_on') || 
        ($sort eq 'created_on') || ($sort eq 'modified_by') || ($sort eq 'created_by') || 
        ($sort eq 'category_name') || ($sort eq 'moniker')) {
        $order_by = { $sort => $dir };
    } elsif( $sort eq 'topic_mid' ) {
        $order_by = { _id => $dir };
    } else {
        $order_by = { '_sort.'.$sort => $dir };
    }
    return $order_by;
}

# this is the main topic grid 
# MONGO:
#
sub topics_for_user {
    my ($self, $p) = @_;
    my ($start, $limit, $query, $query_id, $dir, $sort, $cnt) = ( @{$p}{qw/start limit query query_id dir sort/}, 0 );
    $start||= 0;
    $limit ||= 100;
    $dir = !length $dir ? -1 : uc($dir) eq 'DESC' ? -1 : 1;

    my $where = $p->{where} // {};
    my $perm = Baseliner->model('Permissions');
    my $username = $p->{username};
    my $is_root = $perm->is_root( $username );
    my $topic_list = $p->{topic_list};
    my ( @mids_in, @mids_nin, @mids_or );
    if( length($query) ) {
        #$query =~ s{(\w+)\*}{topic "$1"}g;  # apparently "<str>" does a partial, but needs something else, so we put the collection name "job"
        my @mids_query;
        if( $query !~ /\+|\-|\"|\:/ ) {  # special queries handled by query_build later
            @mids_query = map { $_->{obj}{mid} } 
                _array( mdb->topic->search( query=>$query, limit=>1000, project=>{mid=>1})->{results} );
        }
        
        if( @mids_query == 0 ) {
            $self->build_field_query( $query, $where, $username );
        } else {
            push @mids_in, @mids_query > 0 ? @mids_query : -1;
        }
    }
    
    my ($select,$order_by, $as, $group_by);
    if( !$sort ) {
        $order_by = { 'modified_on' => -1 };
    } else {
        $order_by = $self->build_sort($sort,$dir);
    }
    my @categories;
    if($p->{categories}){
        @categories = _array( $p->{categories} );
        my @user_categories = map {
            $_->{id};
        } Baseliner->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

        my @not_in = map { abs $_ } grep { $_ < 0 } @categories;
        my @in = @not_in ? grep { $_ > 0 } @categories : @categories;
        if (@not_in && @in){
            @user_categories = grep{ not $_ ~~ @not_in } @user_categories;
            $where->{'category.id'} = mdb->in(@in);
        }else{
            if (@not_in){
                @in = grep{ not $_ ~~ @not_in } @user_categories;
                $where->{'category.id'} = mdb->in(@in);
            }else{
                $where->{'category.id'} = mdb->in(@in);
            }
        }        
        #$where->{'category.id'} = \@categories;
    }else{
        # all categories, but limited by user permissions
        #   XXX consider removing this check on root and other special permissions
        @categories  = map { $_->{id}} Baseliner::Model::Topic->get_categories_permissions( username => $username, type => 'view' );
        $where->{'category.id'} = mdb->in(@categories);
    }

    # project security - grouped by - into $or 
    Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @categories );
    
    if( $topic_list ) {
        $where->{mid} = mdb->in($topic_list);
    }
    
    #DEFAULT VIEWS***************************************************************************************************************
    if($p->{today}){
        my $now1 = my $now2 = mdb->now;
        $where->{created_on} = { '$lte' => "$now1", '$gte' => ''.($now2-'1D') };
    }
    
    if($p->{modified_today}){
        my $now1 = my $now2 = mdb->now;
        $where->{modified_on} = { '$lte' => "$now1", '$gte' => ''.($now2-'1D') };
    }
    
    if( $p->{is_release} ){
        $where->{'category.is_release'} = '1';
    }
    
    if ( $p->{assigned_to_me} ) {
        my $ci_user = ci->user->find_one({ name=>$username });
        if ($ci_user) {
            my @topic_mids = 
                map { $_->{from_mid} }
                mdb->master_rel->find({ to_mid=>$ci_user->{mid}, rel_type => 'topic_users' })->fields({ from_mid=>1 })->all;
            if (@topic_mids) {
                $where->{'mid'} = mdb->in(@topic_mids);
            } else {
                $where->{'mid'} = -1;
            }
        } else {
            $where->{'mid'} = -1;
        }
    }
    
    if ( $p->{unread} ){
        my @seen = map { $_->{mid} } mdb->master_seen->find({ username=>$username })->fields({ mid=>1, _id=>0 })->all;
        #push @mids_nin, mdb->nin( @seen );
        @mids_nin =  @seen ;
    }
    
    if ( $p->{created_for_me} ) {
        $where->{created_by} = $username;
    }
    #*****************************************************************************************************************************
    
    #FILTERS**********************************************************************************************************************
    if($p->{labels}){
        my @labels = _array $p->{labels};
        my @not_in = map { abs $_ } grep { $_ < 0 } @labels;
        my @in = @not_in ? grep { $_ > 0 } @labels : @labels;
        if (@not_in && @in){
            $where->{'labels'} = { '$nin' => mdb->str(@not_in), '$in' => mdb->str(@in,undef) };
        }else{
            if (@not_in){
                $where->{'labels'} = {'$nin' => mdb->str(@not_in) };
            }elsif (@in) {
                $where->{'labels'} = { '$in' => mdb->str(@in)};
            }
        }            
    }
    
    my $default_filter;
    if($p->{statuses}){
        my @statuses = _array( $p->{statuses} );
        my @not_in = map { abs $_ } grep { $_ < 0 } @statuses;
        my @in = @not_in ? grep { $_ > 0 } @statuses : @statuses;
        if (@not_in && @in){
            $where->{'category_status.id'} = {'$nin' => mdb->str(@not_in), '$in' => mdb->str(@in) };    
        }else{
            if (@not_in){
                $where->{'category_status.id'} = mdb->nin(@not_in);
            }else{
                $where->{'category_status.id'} = mdb->in(@in);
            }
        }
    }else {
        if (!$p->{clear_filter}){  
            my @status_ids;
            if(!$is_root){
                my %p;
                $p{categories} = \@categories;
                my %tmp;
                map { $tmp{ $_->{id_status_from} } = $_->{id_category} if ($_->{id_status_from}); } 
                    $self->user_workflow( $username, %p );
                 my @workflow_revert;
                 map { push @workflow_revert, [$tmp{$_}, $_] } keys %tmp;
                 my %category_hash = map { $_ => '1' } @categories;
                 foreach my $actual (@workflow_revert){
                     push @status_ids, @$actual[1] if $category_hash{@$actual[0]};
                 }
            }else{
                @status_ids = _unique map{_array $_->{statuses}}mdb->category->find({id=>mdb->in(@categories)})->all;
                @status_ids = map{$_->{id_status}}ci->status->find({id_status=>mdb->in(@status_ids), type=>mdb->nin(['F','FC'])})->all;
            }
            
            $where->{'category_status.id'} = mdb->in(@status_ids) if @status_ids > 0;
            # map { $tmp{$_->{id_status_from}} = $_->{id_category} && $tmp{$_->{id_status_to} = $_->{id_category}} } 
            # my @workflow_filter;
            # for my $status (keys %tmp){
            #     push @workflow_filter, {'category.id' => $tmp{$status},'category_status.id' => $status};
            # }
            # $where->{'$or'} = \@workflow_filter if @workflow_filter;
            $where->{'category_status.type'} = { '$nin' =>['F','FC'] };
            
        }
    }
      
    if( $p->{from_mid} || $p->{to_mid} ){
        my $rel_where = {};
        my $dir = length $$p{from_mid} ? ['from_mid','to_mid'] : ['to_mid','from_mid'];
        $$rel_where{ $$dir[0] } = $$p{ $$dir[0] };
        push @mids_in, 
            grep { length } map { $$_{ $$dir[1] } } 
            mdb->master_rel->find( $rel_where )->fields({ $dir->[1] => 1 })->all;
    }

    #*****************************************************************************************************************************
    
    #Filtro cuando viene por la parte del Dashboard.
    if($p->{query_id}){
        push @mids_in, grep { length } _array($p->{query_id});
    }
    
    #Filtro cuando viene por la parte del lifecycle.
    if($p->{id_project}){
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{id_project}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        push @mids_in, 'xxx' if !@topics_project;
    }
    
    if( @mids_in || @mids_nin ) {
        my $w = {};
        $w->{'$in'} = \@mids_in if @mids_in;
        $w->{'$nin'} = \@mids_nin if @mids_nin;
        if( ref $where->{mid} ) {
            # there's also a topic_list mid
            $where->{'$nor'} = [ {mid=>{'$not'=>delete($where->{mid})}}, {mid=>{'$not'=>$w}} ];
        } else {
            $where->{mid} = $w;
        }
    }
    
    if( @mids_or ) {
        # if ( exists $where->{'$or'} ){
        #     my @or = _array $where->{'$or'};
        #     push @or,  @mids_or; 
        #     $where->{'$or'} = \@or; 
        # }else{
        #     $where->{'$or'} = \@mids_or;  
        # }
        $where->{'$or'} = \@mids_or;  
    }
    #_debug( $order_by );
    
    # _debug( $where );
    my $rs = mdb->topic->find( $where ); 
    #_debug( $rs->explain );
    $rs->fields({ mid=>1, labels=>1 }); 
    # $cnt = $rs->count;
    # $start = 0 if length $start && $start>=$cnt; # reset paging if offset
    $rs->sort( $order_by );
    $rs->skip( $start ) if $start >= 0 ;
    $rs->limit( $limit ) if $limit >= 0 ;
    my @topics = $rs->all;
    my %mid_docs = map { $_->{mid}=>$_ } @topics; 
    my @mids = map { $$_{mid} } @topics;  # keep order
    $cnt ||= $p->{last_count} // scalar(@topics);
    
    # get mid data from cache
    my %mid_data = map { $$_{mid} => $_ } grep { $_ } map { cache->get({ d=>'topic:view', mid=>"$_" }) } @mids; 
    # now search thru 
    if( my @db_mids = grep { !exists $mid_data{$_} } @mids ) {
        # mongo - get additional data
        $self->update_mid_data( \@db_mids, \%mid_data, $username );
    
        for my $db_mid ( @db_mids ) {
            cache->set({ d=>'topic:view', mid=>"$db_mid" }, $mid_data{$db_mid} );
        }
    } else {
        _debug "CACHE =========> ALL TopicView data MIDS in CACHE";
    }

    # get user seen 
    my @mid_prefs = mdb->master_seen->find({ mid=>mdb->in(@mids), username=>$username })->fields({ _id=>0, mid=>1 })->all;
    for( @mid_prefs ) {
        my $d = $mid_data{$_->{mid}};
        $d->{user_seen} = \1; 
    }
    
    # get active jobs
    my %mid_jobs;
    my @jobs =  ci->job->find({ 'changesets.mid'=>mdb->in(@mids), status=>mdb->in('RUNNING') })->fields({ 'changesets.mid'=>1, name=>1 })->all ;
    for my $job ( @jobs ){ 
        for my $cs ( _array($job->{changesets}) ) {
            $mid_jobs{ $cs->{mid} } = $job;
        }
    }

    my @rows;
    my %seen;
    for my $mid (@mids) {
        #This is to avoid duplicates in grid ... unsolved mistery: duplicates in @mids
        next if $seen{$mid};
        $seen{$mid}=1;
        #next if !$mid_data{$mid};
        my $data = $mid_data{$mid} // do { _error("MISSING mid_data for MID=$mid"); +{ mid=>$mid } };
        $data->{calevent} = {
            mid    => $mid,
            color  => $data->{category_color},
            title  => sprintf("%s #%d - %s", $data->{category_name}, $mid, $data->{title}),
            allDay => \1
        };
        $data->{category_status_name} = _loc($data->{category_status}{name});
        $data->{category_name} = _loc($data->{category_name});
        my @projects_report = keys %{ delete $data->{projects_report} || {} };
        push @rows, {
            %$data,
            topic_mid => $mid, 
            topic_name => sprintf("%s #%d", $data->{category_name}, $mid),
            current_job => $mid_jobs{ $mid }{name},
            report_data => {
                projects => join( ', ', @projects_report )
            }
        };
    }
    return { count=>$cnt, last_query=>$where, sort=>$order_by }, @rows ;
}


# TODO this doesn't actually update yet, but it could
sub update_mid_data {
    my ( $self, $mids, $mid_data, $username ) = @_;
    my @mids = _array( $mids ); 
    $mid_data //= {};  
    
    my (%topics_out,%topics_in,%cis_in,%cis_out,%topic_project,%topic_file,%topic_post,%assignee,%folders);
    
    my @rel_from = mdb->master_rel->find({ from_mid=>mdb->in(@mids) })->all;
    my @rel_to   = mdb->master_rel->find({ to_mid=>mdb->in(@mids) })->all;
    
    map { $topics_out{ $_->{from_mid} }{ $_->{to_mid} }=1 } grep { $$_{rel_type} eq 'topic_topic' } @rel_from;
    map { $topics_in{ $_->{to_mid} }{ $_->{from_mid} }=1 } grep { $$_{rel_type} eq 'topic_topic' } @rel_to;
    map { $cis_out{ $_->{from_mid} }{ $_->{to_mid} }=1 } grep { $$_{rel_type} !~ /topic_topic/ } @rel_from;
    map { $cis_in{ $_->{to_mid} }{ $_->{from_mid} }=1 } grep { $$_{rel_type} !~ /topic_topic/ } @rel_to;
    map { $topic_project{$_->{from_mid}}{$_->{to_mid}}=1 } grep { $$_{rel_type} eq 'topic_project' } @rel_from;
    map { $topic_file{$_->{from_mid}}{$_->{to_mid}}=1 } grep { $$_{rel_type} eq 'topic_asset' } @rel_from;
    map { $topic_post{$_->{from_mid}}{$_->{to_mid}}=1 } grep { $$_{rel_type} eq 'topic_post' } @rel_from;
    map { $assignee{$_->{from_mid}}{$_->{to_mid}}=1 } grep { $$_{rel_type} eq 'topic_users' } @rel_from;
    map { $folders{$_->{to_mid}}{$_->{from_mid}}=1 } grep { $$_{rel_type} eq 'folder_ci' } @rel_to;
        
    my %labels = map { $_->{id} => $_ } mdb->label->find->all;
    
    my @ci_mids = keys +{ map { $_=>1 } map { keys $_ } (values %cis_out, values %cis_in, values %topic_project) };
    my %all_cis = map { $_->{mid} => $_ } mdb->master_doc->find({ mid=>mdb->in(@ci_mids) })->fields({ _id=>0,name=>1,mid=>1,collection=>1 })->all ;

    my @rel_mids = keys +{ map{ $_=>1 } map { keys %$_ } (values %topics_out, values %topics_in) };
    my %all_rels = map { $_->{mid} => $_->{title} } mdb->topic->find({ mid=>mdb->in(@rel_mids) })->fields({ _id=>0,title=>1,mid=>1 })->all ;
    
    my $user_security = Baseliner->model('Permissions')->user_projects_ids_with_collection(username => $username, with_role => 1);
    
    my %datas = map { $$_{mid}=>$_ } mdb->topic->find({ mid=>mdb->in(@mids) })->fields({ _txt=>0 })->all;

    for my $mid ( @mids ) {
        my $data = $datas{$mid}  // do{ _error(_loc("Topic mid not found: %1",$mid)); next };
        $$data{topic_mid} //= $mid;
        
        my @mids_cis_in  = keys %{ $cis_in{$mid} || {} };
        my @mids_cis_out = keys %{ $cis_out{$mid} || {} };
        $$data{cis_in}  = [ map { $_->{name} } @all_cis{@mids_cis_in} ];
        $$data{cis_out} = [ map { $_->{name} } @all_cis{@mids_cis_out} ];
        $$data{referenced_in} = [ @all_rels{ keys %{ $topics_in{$mid} || {} } } ];
        $$data{references_out} = [ @all_rels{ keys %{ $topics_out{$mid} || {} } } ];
        $$data{directory} = [ _unique( map { $_->{name} } @all_cis{ keys %{ $folders{$mid} || {} } } ) ];
        $$data{assignee} = [ _unique( map { $_->{name} } @all_cis{ keys %{ $assignee{$mid} || {} } } ) ];   # TODO only rel_field for category meta field type 'assignee'
        
        my @files = ( map { $_->{name} } @all_cis{ keys %{$topic_file{$mid} || {}} } );
        $$data{num_file} = scalar @files;
        $$data{file_name} = \@files;
    
        my @posts = ( map { $_->{name} } @all_cis{ keys %{$topic_post{$mid} || {}} } );
        $$data{numcomment} = scalar @posts;
        $$data{text} = '';
        
        $$data{is_closed} = defined $$data{category_status} && $$data{category_status} eq 'F' ? \1 : \0;
        
        # for all projects that are not areas, etc
        $$data{projects} = [];  # does not use what is in the topic doc
        for my $prj ( grep { $_->{collection} eq 'project' } @all_cis{ _unique keys %{ $topic_project{$mid} || {} } } ) {
            push @{ $$data{projects} }, $prj->{mid}.';'.$prj->{name};
            push @{ $$data{project_report} }, $prj->{name};
            # Structure to check user has access to at least one project in all collections
            $$data{sec_projects}{ $prj->{collection} }{ $prj->{mid} } = 1;
        }
        $$data{labels} = [ 
            map { 
                my $id=$_; 
                my $r = $labels{$id};
                $id . ";" . $r->{name} . ";" . $r->{color};
            } _array( $$data{labels} )
        ];
        $$mid_data{$mid} = $data;
    }
    return $mid_data;
}
        
sub update {
    my ( $self, $p ) = @_;
    my $action = delete $p->{action};
    my $return;
    my $topic_mid;
    my $status;
    my $category;
    my $modified_on;
    my $return_options = {};
    
    given ( $action ) {
        #Casos especiales, por ejemplo la aplicacion GDI
        my $form = $p->{form};
        $p->{_cis} = _decode_json( $p->{_cis} ) if $p->{_cis};

        when ( 'add' ) {
            my $stash = { topic_data=>$p, username=>$p->{username}, return_options=>$return_options };

            $p->{cancelEvent} = 1;

            event_new 'event.topic.create' => $stash => sub {
                mdb->txn(sub{
                    my $meta = $self->get_meta ($topic_mid , $p->{category});
                    $stash->{topic_meta} = $meta; 
                    my @meta_filter;
                    push @meta_filter, $_
                       for grep { exists $p->{$_->{id_field}}} _array($meta);
                    $meta = \@meta_filter;
                    $p->{title} =~ s/-->/->/ if ($p->{title} =~ /-->/); #fix close comments in html templates
                    my ($topic) = $self->save_data($meta, undef, $p);

                    # my $status_changes = {};
                    # my $now = Class::Date->now();
                    # my $status_name = ci->status->find_one({ id_status => $topic->id_category_status })->{name};
                    # $status_changes->{_name_to_id($status_name)}->{count} = 1;
                    # $status_changes->{_name_to_id($status_name)}->{total_time} = 0;
                    # $status_changes->{_name_to_id($status_name)}->{transitions} = [{ ts => ''.Class::Date->now() }];
                    # $status_changes->{_name_to_id($status_name)}->{last_transition} = { ts => ''.Class::Date->now() };
                    # mdb->topic->update({ mid => "$topic->mid"},{'$set' => {_status_changes => $status_changes} });

                    $topic_mid    = $topic->mid;
                    $status = $topic->id_category_status;
                    $return = 'Topic added';
                    $category = $topic->get_category;
                    $modified_on = $topic->ts;
                    my $id_category = $topic->id_category;
                    my $id_category_status = $topic->id_category_status;
                    
                    my @users = $self->get_users_friend(mid => $topic_mid, id_category => $id_category, id_status => $id_category_status);
                    
                    my $notify = {
                        category        => $id_category,
                        category_status => $id_category_status,
                        project         => [map { $_->{mid} } $topic->projects]
                    };
                    
                    my $subject = _loc("New topic: %1 #%2 %3", $category->{name}, $topic->mid, $topic->title);
                    { mid => $topic->mid, title => $topic->title, 
                        topic=>$topic->title, 
                        name_category=>$category->{name}, 
                        category=>$category->{name}, 
                        category_name=>$category->{name}, 
                        notify_default=>\@users, subject=>$subject, notify=>$notify }   # to the event
                });  
                #$return_options->{reload} = 1;                 
            } 
            => sub { # catch
                mdb->topic->remove({ mid=>"$topic_mid" },{ multiple=>1 });
                mdb->master->remove({ mid=>"$topic_mid" },{ multiple=>1 });
                mdb->master_doc->remove({ mid=>"$topic_mid" },{ multiple=>1 });
                mdb->master_rel->remove({ '$or'=>[{from_mid=>"$topic_mid"},{to_mid=>"$topic_mid"}] },{ multiple=>1 });
                _throw _loc( 'Error adding Topic %1: %2', $topic_mid, shift() );
            }; # event_new
        } ## end when ( 'add' )
        when ( 'update' ) {
            my $rollback = 1;
            my $stash = { topic_data=>$p, username=>$p->{username}, return_options=>$return_options };
            event_new 'event.topic.modify' => $stash => sub {
                my @field;
                $topic_mid = $p->{topic_mid};
                $self->cache_topic_remove( $topic_mid );
                my $meta = $self->get_meta ($topic_mid, $p->{category});
                $stash->{topic_meta} = $meta; 
                
                my @meta_filter;
                push @meta_filter, $_
                   for grep { exists $p->{$_->{id_field}}} _array($meta);
                $meta = \@meta_filter;
                $p->{title} =~ s/-->/->/ if ($p->{title} =~ /-->/); #fix close comments in html templates
                my ($topic, %change_status) = $self->save_data($meta, $topic_mid, $p);
                
                $topic_mid    = $topic->mid;
                $status = $topic->id_category_status;
                my $id_category = $topic->id_category;
                $modified_on = $topic->ts;
                $category = $topic->get_category;
                
                my @users = $self->get_users_friend(mid => $topic_mid, id_category => $topic->id_category, id_status => $topic->id_category_status);
                
                $return = 'Topic modified';
                my $subject = _loc("Topic updated: %1 #%2 %3", $category->{name}, $topic->mid, $topic->title);
                $rollback = 0;
                if ( %change_status ) {
                    $self->change_status( %change_status );
                    $return_options->{reload} = 1;
                }

                my $notify = {
                    category => $id_category,
                    category_status => $status,
                };
                    
               { mid => $topic->mid, topic => $topic->title, subject => $subject, notify_default=>\@users, notify=>$notify }   # to the event

            } => sub {
                my $e = shift;
                _throw $e;
            };
        } 
        $self->cache_topic_remove( $topic_mid );
        when ( 'delete' ) {
            my $stash = { topic_data=>$p, username=>$p->{username}, return_options=>$return_options };
                $topic_mid = $p->{topic_mid};
                for my $mid ( _array( $topic_mid ) ) {
                    event_new 'event.topic.delete' => $stash => sub {
                        # delete master row and bali_topic row
                        #      -- delete cascade does not clear up the cache

                        try { $self->cache_topic_remove( $mid ) } catch { };  # dont care about these errors, usually due to related
                        ci->delete( $mid );
                        my $topic = mdb->topic->find_one({ mid=>"$mid" });
                        mdb->topic->remove({ mid=>"$mid" });
                        mdb->master_seen->remove({ mid=>"$mid" });
                        
                        my @users = $self->get_users_friend(mid => $mid, id_category => $topic->{id_category}, id_status => $topic->{id_category_status});
                        
                        $return = 'Topic deleted';
                        my $subject = _loc("Topic deleted: %1 #%2 %3", $topic->{category_name}, $topic->{mid}, $topic->{title});

                        my $notify = {
                            category => $topic->{id_category}
                        };
                            
                       { mid => $topic->{mid}, topic => $topic->{title}, subject => $subject, notify_default=>\@users, notify=>$notify }   # to the event

                        #we must delete activity for this topic
                        #mdb->activity->remove({mid=>$mid});
                    } => sub {
                        _throw _loc( 'Error deleting Topic %1: %2', $topic_mid, shift() );
                    };
                }

        } 
        when ( 'close' ) {
            try {
                my $topic_mid = $p->{topic_mid};
                $modified_on = mdb->ts;
                mdb->topic->update({ mid=>"$topic_mid" },{ '$set'=>{ status=>'C', modified_on=>$modified_on } });
                $return = 'Topic closed'
            } catch {
                _throw _loc( 'Error closing Topic: %1', shift() );
            };
        } 
    } 
    return ( $return, $topic_mid, $status, $p->{title}, $category, $modified_on, $return_options);
} 


sub append_category {
    my ($self, @topics ) =@_;
    return map {
        $_->{name} = $_->{category}{name} 
            ? _loc($_->{category}{name}) . ' #' . $_->{mid} 
            : _loc($_->{name}) . ' #' . $_->{mid} ;
        $_->{color} = $_->{category}{color} 
            ? $_->{category}{color} 
            : $_->{color};
        $_
    } @topics;
}

# used by field_include_into.html fieldlet
sub field_parent_topics {
    my ($self,$data)=@_;
    my $is_release = 0;
    my @parent_topics;

    my $category = $data->{category};
    my $release = $category->{is_release};
    my $id_category = $category->{id};
    my $cat_doc = mdb->category->find_one({id=>"$id_category" }) // _fail _loc 'Category not found: %1', $id_category;

    my @fieldlets =
        map {
            $_->{id_field}
        }
        grep {
            my $params = $_->{params};
            $params->{origin} ne "system"
        } _array( $cat_doc->{fieldlets} );

    push @fieldlets, map {
            my $params = $_->{params};
            $params->{parent_field};
        }
        grep {
            my $params = $_->{params};
            $params->{parent_field};
        } _array( $cat_doc->{fieldlets} );

    if ($release) {
        $is_release     = 1;
        @parent_topics = mdb->joins(
            master_rel => {
                rel_type => 'topic_topic',
                from_mid => $data->{topic_mid},
                '$or'    => [ { rel_field => { '$nin' => \@fieldlets } }, { rel_field => undef } ]
            },
            to_mid => mid => topic => { '$or' => [ { is_changeset => '1' }, { is_release => '1' } ] }
        )->fields( { mid => 1, title => 1, progress => 1, category => 1 } )->all;
        @parent_topics = $self->append_category(@parent_topics);

    } else {
        @parent_topics = mdb->joins(
            master_rel => {
                rel_type => 'topic_topic',
                to_mid   => $data->{topic_mid},
                '$or'    => [ { rel_field => { '$nin' => \@fieldlets } }, { rel_field => undef } ],
                #'$or'    => [ { rel_field => { '$nin' => \@fieldlets } }, { rel_field => undef } ]
            },
            from_mid => mid => topic => { '$or' => [ { is_release => { '$ne' => '1' } } ] }
        )->fields( { mid => 1, title => 1, progress => 1, category => 1 } )->all;
        @parent_topics = $self->append_category(@parent_topics);
    }
    #- categories: {}
    #  color: '#ff9900'
    #  mid: '69'
    #  name: 'Requerimiento #69'
    #  progress: '0'
    #  title: Requerimientos WebApp
    
    return ($is_release, @parent_topics );
}

sub next_status_for_user {
    my ($self, %p ) = @_;
    my @user_roles;
    my $username = $p{username};
    my $topic_mid = $p{topic_mid};
    my $id_category = ''.$p{id_category};
    my $where = { id =>$id_category };
    $where->{'workflow.id_status_from'} = mdb->in($p{id_status_from}) if defined $p{id_status_from};
    my $is_root = Baseliner->model('Permissions')->is_root( $username );
    my @to_status;
    
    if ( !$is_root ) {
        @user_roles = Baseliner->model('Permissions')->user_roles_for_topic( username => $username, mid => $topic_mid  );
        $where->{'workflow.id_role'} = mdb->in(@user_roles);
        my %my_roles = map { $_=>1 } @user_roles;
        my $_tos;
        # check if custom workflow for topic
        if( length $p{id_status_from} ) {
            my $doc = mdb->topic->find_one({ mid=>"$topic_mid" },{ mid=>1, _workflow=>1, category_status=>1 });
            if( $doc->{_workflow} && ( $_tos = $doc->{_workflow}{ $p{id_status_from} } ) ) {
                $where->{"workflow.id_status_to"} = mdb->in($_tos); 
            }
        }
                
        my %statuses = ci->status->statuses;
        
        if( !( my $cat = mdb->category->find_one($where) ) ) {
            my $catname = mdb->category->find_one({ id=>$id_category });
            $catname ? _warn(_loc( 'User does not have a workflow for category `%1`', $catname->{name} ))
                    : _fail(_loc('Category id `%1 `not found', $id_category));
        } else {
            my %uniq;
            my @all_to_status =
                sort { $$a{seq} <=> $$b{seq} }
                grep { $uniq{$$_{id_status}} // ($uniq{$$_{id_status}}=0)+1 }  # make unique by status_to
                map {
                    my $sfrom = $statuses{ $$_{id_status_from} };
                    my $sto   = $statuses{ $$_{id_status_to} };
                    +{
                        id_status_from     => $$_{id_status_from},
                        id_status_to       => $$_{id_status_to},
                        statuses_name_from => $$sfrom{name},
                        status_bl_from     => $$sfrom{bl},
                        id_status          => $$_{id_status_to},
                        status_name        => $$sto{name},
                        status_type        => $$sto{type},
                        status_bl          => $$sto{bl},
                        status_description => $$sto{description},
                        id_category        => $$_{id_category},
                        job_type           => $$_{job_type},
                        seq                => ($$sto{seq} // 0)
                    };
                } 
                grep { $my_roles{$$_{id_role}} && $$_{id_status_from} eq $p{id_status_from}}
                grep { defined } _array( $cat->{workflow} );

                if($_tos){
                    my %tos = map { $_ => $_ } _array $_tos;
                    @all_to_status = grep { $tos{$_->{id_status_to}}  } @all_to_status;
                }
            
            my @no_deployable_status = grep {$_->{status_type} ne 'D'} @all_to_status;
            my @deployable_status = grep {$_->{status_type} eq 'D'} @all_to_status; 
            
            push @to_status, @no_deployable_status;
            
            foreach my $status (@deployable_status){
                if ( $status->{job_type} eq 'promote' ) {
                    if(Baseliner->model('Permissions')->user_has_action( username=> $username, action => 'action.topics.logical_change_status', bl=> $status->{status_bl}, mid => $topic_mid )){
                        push @to_status, $status;
                    }
                }elsif ( $status->{job_type} eq 'demote' ) {
                    if(Baseliner->model('Permissions')->user_has_action( username=> $username, action => 'action.topics.logical_change_status', bl=> $status->{status_bl_from}, mid => $topic_mid )){
                        push @to_status, $status;
                    }               
                }else {
                    push @to_status, $status;
                }
            }    
        }
    } else {
        my @user_wf = $self->user_workflow( $username );
        @to_status = sort { ($a->{seq} // 0 ) <=> ( $b->{seq} // 0 ) } grep {
            $_->{id_category} eq $p{id_category}
                && (( defined $_->{id_status_from} && defined $p{id_status_from} && $_->{id_status_from} eq $p{id_status_from} ) || ( ! defined $_->{id_status_from} && ! defined $p{id_status_from} ))
                && (( defined $_->{id_status_to}   && defined $p{id_status_from} && $_->{id_status_to}   ne $p{id_status_from} ) || ( !( defined $_->{id_status_to} && defined $p{id_status_from})))
        } @user_wf;
    }

    return @to_status;
}

sub get_system_fields {
    my ($self);
    my $pathHTML = '/fields/system/html/';
    my $pathJS = '/fields/system/js/';
    my @system_fields = (
        {
            id_field => 'title',
            params   => {
                name_field       => 'Title',
                bd_field         => 'title',
                origin           => 'system',
                html             => $pathHTML . 'field_title.html',
                js               => '/fields/templates/js/textfield.js',
                field_order      => -1,
                font_weigth      => 'bold',
                section          => 'head',
                meta_type        => 'title',
                field_order_html => 1,
                allowBlank       => \0,
                system_force     => \1
            }
        },
        {
            id_field => 'moniker',
            params   => {
                name_field       => 'Moniker',
                bd_field         => 'moniker',
                origin           => 'system',
                js               => '/fields/templates/js/textfield.js',
                html          => '/fields/templates/html/row_body.html',
                field_order      => -8,
                section          => 'body',
                allowBlank       => \1
            }
        },
        {
            id_field => 'category',
            params   => {
                name_field  => 'Category',
                bd_field    => 'id_category',
                origin      => 'system',
                js          => $pathJS . 'field_category.js',
                field_order => -2,
                section     => 'body',
                relation    => 'categories',
                allowBlank       => \0,
                system_force     => \1
            }
        },
        {
            id_field => 'status_new',
            params   => {
                name_field    => 'Status',
                bd_field      => 'id_category_status',
                display_field => 'name_status',
                origin        => 'system',
                html          => '/fields/templates/html/row_body.html',
                js            => $pathJS . 'field_status.js',
                field_order   => -3,
                section       => 'body',
                relation      => 'status',
                framed        => 1,
                allowBlank    => \0,
                system_force  => \1,
                meta_type     => 'status',
            }
        },
        {
            id_field => 'created_by',
            params   => { name_field => 'Created By', bd_field => 'created_by', origin => 'default' }
        },
        {
            id_field => 'created_on',
            params   => { name_field => 'Created On', bd_field => 'created_on', origin => 'default', meta_type => 'date' }
        },
        {
            id_field => 'modified_by',
            params   => { name_field => 'Modified By', bd_field => 'modified_by', origin => 'default' }
        },
        {
            id_field => 'modified_on',
            params   => { name_field => 'Modified On', bd_field => 'modified_on', origin => 'default', meta_type => 'date' }
        },        
        {
            id_field => 'labels',
            params   => {
                name_field       => 'Labels',
                bd_field         => 'labels',
                origin           => 'default',
                relation         => 'system',
                get_method       => 'get_labels',
                field_order_html => 1
            }
        },
        {
            id_field => 'description',
            params   => {
                name_field       => 'Description',
                bd_field         => 'description',
                origin           => 'system',
                html             => '/fields/templates/html/dbl_row_body.html',
                js               => '/fields/templates/js/html_editor.js',
                field_order      => -7,
                section          => 'head',
                field_order_html => 2
            }
        },
        {
            id_field => 'progress',
            params   => {
                name_field  => 'Progress',
                bd_field    => 'progress',
                origin      => 'system',
                html        => '/fields/templates/html/progress_bar.html',
                js          => '/fields/templates/js/progress_bar.js',
                field_order => -8,
                section     => 'body'
            }
        },
        {
            id_field => 'include_into',
            params   => {
                name_field  => 'Included in',
                bd_field    => 'include_into',
                origin      => 'default',
                html        => $pathHTML . 'field_include_into.html',
                field_order => 0,
                section     => 'details'
            }
        },
    );
    return \@system_fields
}

sub tratar{
    my $field = shift;
    my $params = $field->{params};
    if ($params->{origin} eq 'custom'){ 
        $_->{type} = $params->{type};
        $_->{js} = $params->{js};
        return 1;
    }
    else {
        return 0;
    }
}
    
sub get_update_system_fields {
    my ($self, $id_category) = @_;
    
    my $system_fields = $self->get_system_fields();
    my $cat = mdb->category->find_one({id=>"$id_category" }) // _fail _loc 'Category not found: %1', $id_category;
    my @rs_categories_fields = _array( $cat->{fieldlets} );
    my %fields = map { $$_{id_field} => $_ } @rs_categories_fields;
    for my $category ( @rs_categories_fields ){
        my $id_category = $category->{id_category};
        for (_array $system_fields){
            if (my $field = $fields{$$_{id_field}} ){
                my $tmp_params = $field->{params};
                for my $attr (keys %{ $_->{params} || {} }){
                    next unless $attr ne 'field_order';
                    $tmp_params->{$attr} = $_->{params}->{$attr};
                    mdb->category->update({ id=>"$id_category", 'fieldlets.id_field'=>$$field{id_field} },
                            { '$set'=>{ 'fieldlets.$.params'=>$tmp_params } }) 
                }
            }
        }
    }
    
    my @template_dirs;
    push @template_dirs, Baseliner->path_to( 'root/fields/templates/js' ) . "/*.js";
    push @template_dirs, Baseliner->path_to( 'root/fields/system/js' ) . "/list*.js";
    #@template_dirs = grep { -d } @template_dirs;
    
    my @tmp_templates = map {
        my @ret;
        for my $f ( map { _file($_) } grep { -f } glob "$_" ) { 
            my $d = $f->slurp;
            my $yaml = Util->_load_yaml_from_comment( $d );
           
            my $metadata;
            if(length $yaml ) {
                $metadata =  _load( $yaml );    
            } else {
                $metadata = {};
            }
            my @rows = map {
                +{  field=>$_, value => $metadata->{$_} } 
            } keys %{ $metadata || {} };
            
            push @ret, {
                file => "$f",
                yaml => $yaml,
                metadata => $metadata,
                rows => \@rows,
            };
        }
       @ret;
    } @template_dirs;
    
    my @fields =  grep { tratar $_ } map { _array($_->{fieldlets}) } mdb->category->find->fields({ fieldlets=>1 })->all;    
    
    for my $template (  grep {$_->{metadata}->{params}->{origin} eq 'template'} @tmp_templates ) {
        if( $template->{metadata}->{name} ){
    	    my @select_fields = grep { $_->{type} eq $template->{metadata}->{params}->{type}} @fields;
            for my $select_field (@select_fields){
                my ($update_field) = 
                    grep { $$_{id_field} eq $select_field->{id_field} } 
                    _array( mdb->category->find_one({ id=>''.$select_field->{id_category}, })->{fieldlets} );
                if ($update_field){
                    my $tmp_params = $update_field->{params};
                    for my $attr (keys %{ $template->{metadata}->{params} || {} } ){
                        next unless $attr ne 'field_order' && $attr ne 'bd_field' && $attr ne 'id_field' && $attr ne 'name_field' && $attr ne 'origin';
                        $tmp_params->{$attr} = $template->{metadata}->{params}->{$attr};

                    }   
                    $update_field->{params} = $tmp_params;
                    $update_field->update();                    
                }
            }
        }
    }
    
    for my $system_listbox ( grep {!$_->{metadata}->{params}->{origin}} @tmp_templates ) {
        if( $system_listbox->{metadata}->{name} ){
    		my @select_fields = grep { $_->{js} eq $system_listbox->{metadata}->{params}->{js}} @fields;
            for my $select_field (@select_fields){
                my ($update_field) = 
                    grep { $$_{id_field} eq $select_field->{id_field} } 
                    _array( mdb->category->find_one({ id=>''.$select_field->{id_category}, })->{fieldlets} );
                if ($update_field){
                    my $tmp_params = $update_field->{params};
                    for my $attr (keys %{ $system_listbox->{metadata}->{params} || {} } ){
                        next unless $attr ne 'field_order' && $attr ne 'bd_field' && $attr ne 'id_field' 
                        && $attr ne 'name_field' && $attr ne 'origin' && $attr ne 'singleMode' && $attr ne 'filter' ;
                        $tmp_params->{$attr} = $system_listbox->{metadata}->{params}->{$attr};
                    }
                    $update_field->{params} = $tmp_params;
                    $update_field->update();
                }
            }
        }
    }
}

our %meta_types = (
    set_projects   => 'project',
    set_topics     => 'topic',
    set_release    => 'release',
    set_revisions  => 'revision',
    set_cal        => 'calendar',
    set_cis        => 'ci',
    set_users      => 'user',
    set_labels     => 'label',
    get_files      => 'file',
);

sub get_meta {
    my ($self, $topic_mid, $id_category, $username) = @_;

    my $cached = cache->get({ mid=>"$topic_mid", d=>"topic:meta" }) if $topic_mid;
    return $cached if $cached;

    my $id_cat =  $id_category
        // ( $topic_mid ? mdb->topic->find_one_value( id_category => { mid=>"$topic_mid" }) : undef );
    
    my @cat_fields;
    
    if ($id_cat){
        my $catdoc = mdb->category->find_one({ id=>mdb->in($id_cat) });
        @cat_fields = _array( $catdoc->{fieldlets} );
    }else{
        if($username){
            my @user_categories =  map { $_->{id} } $self->get_categories_permissions( username => $username, type => 'view',  );
            #@cat_fields = _array( mdb->category->find({ id=>mdb->in(@user_categories) })->{fieldlets} );
            @cat_fields = _array( map{ _array($$_{fieldlets}) } mdb->category->find({ id=>mdb->in(@user_categories) })->all);
        }else{
            @cat_fields = _array( map{ _array($$_{fieldlets}) } mdb->category->find->all );
        }
    }
    
    my @meta =
        sort { $a->{field_order} <=> $b->{field_order} }
        map  { 
            my $d = $_->{params};
            $d->{id_category} = $_->{id_category};
            if( length $d->{default_value} && $d->{default_value}=~/^#!perl:(.*)$/ ) {
                $d->{default_value} = eval $1;
            }
            $d->{field_order} //= 1;
            $d->{editable} //= length $d->{js} ? 1 : 0;
            $d->{meta_type} = 'history' if $d->{js} && $d->{js} eq '/fields/templates/js/status_changes.js';  # for legacy only
            $d->{meta_type} ||= $d->{set_method} 
                ? ($meta_types{ $d->{set_method} } // _fail("Unknown set_method $d->{set_method} for field $d->{name_field}") ) 
                : $d->{get_method} ? $meta_types{ $d->{get_method} } : '';
            $d
        } @cat_fields;
    
    cache->set({ d=>'topic:meta', mid=>"$topic_mid" }, \@meta ) if length $topic_mid;
    
    return \@meta;
}

sub get_meta_hash {
    my $self = shift;
    my $meta = $self->get_meta( @_ );
    my %meta = map { $_->{id_field} => $_ } @{ $meta || [] };
    return \%meta;
}

sub get_data {
    my ($self, $meta, $topic_mid, %opts ) = @_;
    
    # normalize to improve cache_hits:
    my $no_cache = delete( $opts{no_cache} ) || 0;
    my $with_meta = delete $opts{with_meta};
    $opts{topic_child_data} = !! $opts{topic_child_data};
    $opts{has_meta} = !!( $meta || $with_meta ); # normalize the cache only

    my $data;
    if ($topic_mid){
        if( !$meta && $with_meta ) {
            $meta = $self->get_meta( $topic_mid );  
        }
        my $cache_key = { d=>'topic:data', mid=>"$topic_mid", opts=>\%opts }; # ["topic:data:$topic_mid:", \%opts];
        my $cached = cache->get( $cache_key ) unless $no_cache; 
        if( defined $cached ) {
            _debug( "CACHE HIT get_data: topic_mid = $topic_mid" );
            return $cached;
        }
        
        ##************************************************************************************************************************
        ##CAMPOS DE SISTEMA ******************************************************************************************************
        ##************************************************************************************************************************
        
        $data = mdb->topic->find_one({ mid=>"$topic_mid" },{ _txt=>0 }) 
                or _error( "topic mid $topic_mid document not found" );
        my @labels = _array( $data->{labels} );
        $data->{topic_mid} = "$topic_mid";
        $data->{action_status} = $self->getAction($data->{type_status});
        $data->{created_on_epoch} = Class::Date->new( $data->{created_on} )->epoch;
        $data->{modified_on_epoch} = Class::Date->new( $data->{modified_on} )->epoch;
        $data->{deadline} = _loc('unassigned');
        
        ##*************************************************************************************************************************
        ###************************************************************************************************************************
        
        my %rel_fields = map { $_->{id_field} => 1  } grep { defined $_->{relation} && $_->{relation} eq 'system' } _array( $meta );
        my %method_fields = map { $_->{id_field} => $_->{get_method}  } grep { $_->{get_method} } _array( $meta );
        my %metadata = map { $_->{id_field} => $_  } _array( $meta );

        # build rel fields from master_rel
        # my @rels = mdb->master_rel->find({ from_mid=>"$topic_mid" })->all;
        # for my $rel ( @rels ) {
        # next unless $rel->{rel_field};
        # next unless exists $rel_fields{ $rel->{rel_field} };
        # push @{ $data->{ $rel->{rel_field} } },  $rel->{to_mid};
        # }
        
        foreach my $key  (keys %method_fields){
            my $method_get = $method_fields{ $key };
            $data->{ $key } =  $self->$method_get( $topic_mid, $key, $meta, $data, %opts );
        }
        
        # if a custom field, get it from the document
        # my %custom_fields = map { $_->{id_field} => 1 } grep { $_->{origin} eq 'custom' && !$_->{relation} } _array( $meta  );
        # for my $f ( grep { exists $custom_fields{$_} } keys %{ $doc || {} } ) {
        #    $data->{ $f } = $doc->{$f}; 
        # }
        if( @labels > 0 ) {
            my %all_labels = map { $_->{id} => $_ } mdb->label->find({ id=>mdb->in(@labels) })->all;
            $data->{labels} = [ map { $all_labels{$_} } @labels ]; 
        }
        cache->set( $cache_key, $data );
    }
    
    return $data;
}

sub rel_signature {
    my ($self,$mid) = @_;
    join ',', sort { $a <=> $b } _unique 
        map { ($_->{from_mid}, $_->{to_mid}) } 
        mdb->master_rel->find({ rel_type=>'topic_topic', '$or'=>[{ from_mid=>"$mid" },{ to_mid=>"$mid" }] })->all;
}

sub get_release {
    my ($self, $topic_mid, $key, $meta ) = @_;

    my @meta_local = _array($meta);
    my ($field_meta) = grep { $_->{id_field} eq $key } @meta_local;
    my $rel_type = $field_meta->{rel_type} // "topic_topic";
    my $where = { is_release => 1, rel_type=>$rel_type, to_mid=>$topic_mid };
    $where->{rel_field} = $field_meta->{release_field} if $field_meta->{release_field};
    
    my ($release_row) = mdb->joins( master_rel => { rel_type=>'topic_topic', to_mid=>"$topic_mid", rel_field=>$field_meta->{release_field} },
                         from_mid => mid => topic => { is_release=>'1' });
    return {
        color => $release_row->{category}{color},
        name  => $release_row->{category}{name},
        title => $release_row->{title},
        mid   => $release_row->{mid},
    };
}

sub get_projects {
    my ($self, $topic_mid, $id_field, $meta, $data ) = @_;

    # for safety with legacy, reassign previous unassigned projects (normally from drag-drop
    
    my @projects = mdb->joins( 
        master_rel =>{ from_mid=>"$topic_mid", rel_field=>$id_field, rel_type=>'topic_project' },
        to_mid => mid => 
        master_doc =>[{},{ fields=>{ mid=>1, name=>1 }, sort=>{ _id=>1 } }] );
    $data->{"$id_field._project_name_list"} = join ', ', sort map { $_->{name} } @projects;
    return @projects ? \@projects : [];
}

sub get_users {
    my ($self, $topic_mid, $id_field ) = @_;
    my @users = mdb->joins( 
            master_rel=>{ rel_field=>$id_field, from_mid=>"$topic_mid", rel_type=>'topic_users' },
            to_mid=>mid => 
            master_doc =>[{},{ fields=>{ mid=>1, username=>1, realname=>1 } }] );

    return @users ? \@users : [];
}

# deprecated : this is now embedded into the topic doc, $doc->{labels}
sub get_labels {
    my ($self, $topic_mid ) = @_;
    return [];   
}

sub get_revisions {
    my ($self, $topic_mid ) = @_;
    my @revisions = mdb->master_rel->find({ rel_type=>'topic_revision', from_mid=>$topic_mid })->all;
    @revisions = map {  
        my $r = mdb->master_doc->find_one({ mid=>"$_->{to_mid}" },{ name=>1, mid=>1, _id=>0, repo=>1 });
        my $repo = mdb->master_doc->find_one({ mid=>mdb->in(delete $r->{repo}) },{ name=>1 });
        +{ %$r, reponame=>$repo->{name} };
    } @revisions; 
    return @revisions ? \@revisions : [];    
}

sub get_cis {
    my ($self, $topic_mid, $id_field, $meta, $data ) = @_;
    my $field_meta = [ grep { $_->{id_field} eq $id_field } _array( $meta ) ]->[0];
    my $where = { from_mid => "$topic_mid" };
    $where->{rel_type} = $field_meta->{rel_type} if ref $field_meta eq 'HASH' && defined $field_meta->{rel_type};
    $where->{rel_field} = $id_field;
    my @cis = map { $_->{to_mid} } mdb->master_rel->find($where)->fields({ to_mid=>1 })->all;

    $data->{"$id_field._ci_name_list"} = join ', ', map { $_->{name} } mdb->master->find({mid=>mdb->in(@cis)})->all if @cis;
    return @cis ? \@cis : [];    
}

sub get_dates {
    my ($self, $topic_mid ) = @_;
    my @dates = mdb->master_cal->find({ mid=>"$topic_mid" })->all;
    return @dates ?  \@dates : [];
}

sub get_topics {
    my ($self, $topic_mid, $id_field, $meta, $data, %opts) = @_;

    my @topics;
    my $field_meta = [ grep { $_->{id_field} eq $id_field } _array($meta) ]->[0];
    
    my $rel_type = $field_meta->{rel_type} // 'topic_topic';
    # Am I parent or child?
    my @rel_topics = $field_meta->{parent_field} 
        ? mdb->master_rel->find_values(from_mid => { to_mid=>"$topic_mid", rel_type=>$rel_type, rel_field=>$field_meta->{parent_field}  })
        #? mdb->master_rel->find_values(from_mid => { to_mid=>"$topic_mid", rel_type=>$rel_type, rel_field=>$id_field })
        : mdb->master_rel->find_values(to_mid => { from_mid=>"$topic_mid", rel_type=>$rel_type, rel_field=>$id_field  });
        # : _array($$data{$id_field});

    my @rs_ord = mdb->topic->find({ mid=>mdb->in(@rel_topics) })->fields({ _id=>0 })->sort({rel_seq=>1})->all if @rel_topics;
    @topics = map { $_->{categories} = $_->{category}; $_ } @rs_ord;
    @topics = $self->append_category( @topics );
    
    if( $opts{topic_child_data} ) {
        @topics = map {
            my $meta = $self->get_meta($_->{mid}, $_->{id_category});
            my $data = $self->get_data( undef, $_->{mid}, with_meta=>1 ) ;
            $_->{description} //= $data->{description};
            $_->{name_status} //= $data->{name_status};
            $_->{data} //= $data;
            # _warn $meta;
            my @topic_fields = map { $_->{id_field} } grep { $_->{get_method} eq 'get_topics' } _array($meta);

            for my $topic_field ( @topic_fields ) {
                _warn "Adding ". '_title_list_'.$topic_field;
                $_->{$topic_field.'._title_list'} = '<li>'.join('</li><li>', map { $_->{title} } _array($data->{$topic_field})).'</li>' if _array($data->{$topic_field});
            };
            $_
        } @topics;
    }
    return @topics ? \@topics : [];    
}

sub get_cal {
    my ($self, $topic_mid, $id_field, $meta, $data, %opts) = @_;
    my @cal = mdb->master_cal->find({ mid=>"$topic_mid", rel_field=>$id_field })->all;
    return \@cal; 
}

sub get_files {
    my ($self, $topic_mid, $id_field) = @_;
    my @ass_mids = mdb->master_rel->find_values( to_mid => { from_mid => "$topic_mid", rel_field => $id_field } );
    my @assets = ci->asset->search_cis( mid=>mdb->in(@ass_mids) );
    my @files = map {
        +{
            mid        => $_->mid,
            filename   => $_->name,
            filesize   => $_->filesize,
            versionid  => $_->versionid,
            created_by => $_->created_by,
            created_on => $_->ts,
        };
    } @assets;
    return \@files;
}

sub save_data {
    my ( $self, $meta, $topic_mid, $data, %opts ) = @_;

    my $topic_mid_new;   # TODO replace this with mongo txn

    try {
        if ( length $topic_mid ) {
            #_debug "Removing *$topic_mid* from cache";
            cache->remove({ mid=>"$topic_mid" }); # qr/:$topic_mid:/ );
        }

        my @std_fields =
            map {
            +{
                name     => $_->{id_field},
                column   => $_->{bd_field},
                method   => $_->{set_method},
                relation => $_->{relation}
                }
            }
            grep {
            $_->{origin} eq 'system'
            } _array( $meta );

        my %row;
        my %description;
        my %old_values;
        my %old_text;
        my %relation;

        my @imgs;
        
        # XXX this should be a custom field someday (look in save_doc)
        $data->{description} =
            $self->deal_with_images( {topic_mid => $topic_mid, field => $data->{description}} )
               if exists $data->{description}; # otherwise updates without description will overwrite this

        for ( @std_fields ) {
            if ( exists $data->{$_->{name}} ) {
                $row{$_->{column}} = $data->{$_->{name}};
                $description{$_->{column}} = $_->{name};     ##Contemplar otro parametro mas descriptivo
                $relation{$_->{column}}    = $_->{relation};
                if ( $_->{method} ) {
                    my $method_set = $_->{method};
                    my $extra_fields = $self->$method_set( $data->{$_->{name}}, $data, $meta, %opts );
                    foreach my $column ( keys %{$extra_fields || {}} ) {
                        $row{$column} = $extra_fields->{$column};
                    }
                } 
            } 
        } 

        my @custom_fields =
            map { +{name => $_->{id_field}, column => $_->{id_field}, data => $_->{data}} }
            grep { $_->{origin} eq 'custom' && !$_->{relation} } _array( $meta );

        push @custom_fields, map {
            my $cf = $_;
            map { +{name => $_->{id_field}, column => $_->{id_field}, data => $_->{data}} }
                _array $_->{fieldlets};
            } grep {
            $_->{type} && $_->{type} eq 'form'
            } _array( $meta );

        my $topic;
        my $moniker = delete $row{moniker};
        my %change_status;

        if ( !$topic_mid ) {
            # NEW TOPIC
            $row{created_by}         = $data->{username};
            $row{modified_by}        = $data->{username};
            $row{id_category_status} = $data->{id_category_status} if $data->{id_category_status};
            
            # TODO force mid from field here
            $topic = ci->topic->new( name=>$row{title}, moniker=>$moniker, %row );
            $topic_mid = $topic->save;   
            $topic_mid_new = $topic_mid; 
            $row{mid} = $topic_mid;
            $row{modified_on} = $topic->ts;
            $row{created_on} = $topic->ts;

            # update images
            for ( @imgs ) {
                $_->update( {topic_mid => $topic_mid} );
            }
        } else {
            # UPDATE TOPIC
            $topic = ci->new( $topic_mid );

            for my $field ( keys %row ) {
                $old_values{$field} = $topic->{$field}, my $method = $relation{$field};
                $old_text{$field} = $method ? try { $topic->$method->name } : $topic->{$field};
            };
            
            my %update_row = %row;
            delete $update_row{id_category_status};
            #update last modified on ci!
            $topic->{ts} = mdb->now->string;

            $topic->update( name=>$row{title}, moniker=>$moniker, modified_by=>$data->{username}, %update_row );
            
            for my $field ( keys %row ) {
                next if $field eq 'response_time_min' || $field eq 'expr_response_time';
                next if $field eq 'deadline_min'      || $field eq 'expr_deadline';

                my $method    = $relation{$field};
                my $new_value = $row{$field};
                my $old_value = $old_values{$field} // '' ;
                

                if ( !defined $old_value && $new_value ne '' || $new_value ne $old_value ) {

                    if ( $field eq 'id_category_status' ) {
                        # change status
                        my $id_status    = $new_value;
                        my $cb_ci_update = sub {

                            # check if it's a CI update
                            my $status_new = ci->status->find_one({ id_status=>$id_status });
                            my $ci_update  = $status_new->{ci_update};
                            if ( $ci_update && ( my $cis = $data->{_cis} ) ) {
                                for my $ci ( _array $cis ) {
                                    my $ci_data = $ci->{ci_data} // {map { $_ => $data->{$_} }
                                            grep { length }
                                            _array( $ci->{ci_fields} // @custom_fields )};
                                    my $ci_master = $ci->{ci_master} // $ci_data;
                                    given ( $ci->{ci_action} ) {
                                        when ( 'create' ) {
                                            my $ci_class = $ci->{ci_class};
                                            $ci_class = 'BaselinerX::CI::' . $ci_class
                                                unless $ci_class =~ /^Baseliner/;
                                            my $obj = $ci_class->new( %$ci_master, %$ci_data );
                                            $ci->{ci_mid}      = $obj->save;
                                            $ci->{_ci_updated} = 1;
                                        } 
                                        when ( 'update' ) {
                                            _debug "ci update $ci->{ci_mid}";
                                            my $ci_mid = $ci->{ci_mid} // $ci_data->{ci_mid};
                                            my $obj = _ci( $ci_mid );
                                            $obj->update( %$ci_master, %$ci_data );
                                            $obj->save;
                                            $ci->{_ci_updated} = 1;
                                        } 
                                        when ( 'delete' ) {
                                            my $ci_mid = $ci->{ci_mid} // $ci_data->{ci_mid};
                                            my $obj = _ci( $ci_mid );
                                            $obj->update( %$ci_master, %$ci_data );
                                            $obj->save;
                                            $obj->delete;
                                            $ci->{_ci_updated} = 1;
                                        } 
                                        default {
                                            _throw _loc "Invalid ci action '%1' for mid '%2'",
                                                $ci->{ci_action}, $ci->{ci_mid};
                                        }
                                    } 
                                } 
                            } 
                        };
                        %change_status = (
                            mid           => $topic_mid,
                            title         => $topic->{title},
                            username      => $data->{username},
                            old_status    => $old_text{$field},
                            id_old_status => $old_value,
                            id_status     => $id_status,
                            change => 1
                        );
                    } else {
                        # report event
                        my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>$topic_mid, rel_type=>'topic_project' });
                        my $notify = {
                            category        => $topic->id_category,
                            category_status => $topic->id_category_status,
                            field           => $field
                        };
                        $notify->{project} = \@projects if @projects;

                        event_new 'event.topic.modify_field' => {
                            username  => $data->{username},
                            field     => _loc( $description{$field} ),
                            old_value => $old_text{$field},
                            new_value => $method
                                && $topic->$method ? $topic->$method->name : $topic->{$field},
                            mid => $topic->mid,
                        } => sub {
                            my $subject = _loc( "#%1 %2: Field '%3' updated",
                                $topic->mid, $topic->title, $description{$field} );
                            {
                                mid     => $topic->mid,
                                topic   => $topic->title,
                                subject => $subject,
                                notify  => $notify
                            }    # to the event
                        } => sub {

                            #_throw _loc( 'Error modifying Topic: %1', shift() );
                            _throw shift;
                        };

                    } 
                } 
            } 
        } # update

        if ( my $cis = $data->{_cis} ) {
            for my $ci ( _array $cis ) {
                if ( length $ci->{ci_mid} && $ci->{ci_action} eq 'update' ) {
                    my $rdoc = {rel_type => 'ci_request', from_mid => ''.$ci->{ci_mid}, to_mid => ''.$topic->mid};
                    mdb->master_rel->update_or_create($rdoc);
                }
            } 
        } 

        # save relationship fields
        my %rel_fields =
            map { $_->{id_field} => $_->{set_method} }
            grep { $_->{relation} && $_->{relation} eq 'system' } _array( $meta );

        my $cancelEvent = exists $data->{cancelEvent} ? $data->{cancelEvent} : 0;

        # SETS
        foreach my $id_field ( keys %rel_fields ) {
            if ( $rel_fields{$id_field} ) {
                my $meth = $rel_fields{$id_field};
                $self->$meth( $topic, $data->{$id_field}, $data->{username}, $id_field, $meta, $cancelEvent );
            }
        } 
        
        # save to mongo
        $self->save_doc(
            $meta, +{ %$topic }, $data,
            username      => $data->{username},
            mid           => $topic_mid,
            custom_fields => \@custom_fields
        );

        # cleanup deleted images
        $self->cleanup_images( $topic_mid, $data );

        # user seen
        mdb->master_seen->update({ username => $data->{username}, mid => $topic_mid }, 
                {username => $data->{username}, mid => $topic_mid, last_seen => mdb->ts, type=>'topic' }, { upsert=>1 });
        # cache clear
        $self->cache_topic_remove( $topic_mid );

        return ($topic, %change_status);
    } catch {
        my $e = shift;
        ci->delete( $topic_mid_new ) if defined $topic_mid_new;
        _throw $e;
    };

} ## save_data

sub update_project_security {
    my ($self, $doc )=@_;

    my $meta = Baseliner->model('Topic')->get_meta ($doc->{mid}, $doc->{id_category});
    my %project_collections; 
    for my $field ( grep { $_->{meta_type} && $_->{meta_type} eq 'project' && length $_->{collection} } @$meta ) {
        my @secs = _array($doc->{ $field->{id_field} });
        push @{ $project_collections{ $field->{collection} } }, @secs if @secs;
    }
    if( keys %project_collections ) {
        return $doc->{_project_security} = \%project_collections;
    } else {
        delete $doc->{_project_security};
        return undef;
    }
}

sub save_doc {
    my ($self,$meta,$ci_topic, $doc, %p) = @_;
    #$ci_topic->{created_on} = mdb->ts if !exists $ci_topic->{created_on};
    $ci_topic->{modified_on} = mdb->ts if !exists $ci_topic->{modified_on};
    # not necessary, noboody cares about the original? $doc = Util->_clone($doc); # so that we don't change the original
    Util->_unbless( $doc );
    my $mid = ''. $p{mid};
    _fail _loc 'save_doc failed: no mid' unless length $mid; 
    $doc->{mid} = $mid;
    my @custom_fields = @{ $p{custom_fields} };
    my %meta = map { $_->{id_field} => $_ } @$meta;
    my $old_doc = mdb->topic->find_one({ mid=>"$mid" }) // {};
    $ci_topic->{created_on} = mdb->ts if !exists $old_doc->{created_on};
    # clear master_seen for everyone else
    mdb->master_seen->remove({ mid=>"$mid", username=>{ '$ne' => $p{username} } });
 
    # take images out
    for( @custom_fields ) {
        $doc->{ $_->{name} } = $self->deal_with_images({ topic_mid=>$mid, field=>$doc->{ $_->{name} } });
    }
    
    # treat fields based on their meta_type
    for my $field ( keys %meta ) {
        my $mt = $meta{$field}{meta_type};
        if( $mt eq 'calendar' ) {
            # calendar info
            my $arr = $doc->{$field} or next;
            $doc->{$field} = {};
            for my $cal ( _array($arr) ) {
                _fail "field $field is not a calendar?" unless ref $cal;
                my $slot = Util->_name_to_id( $cal->{slotname} );
                $doc->{$field}{$slot} = $cal;
            }
        }
        elsif( $mt eq 'number' ) {
            # numify
            $doc->{$field} = 0+$doc->{$field};
        }
        elsif( $mt eq 'string' ) {
            # stringify
            $doc->{$field} = ''.$doc->{$field};
        }
    }
    
    # expanded data
    $self->update_category( $doc, $ci_topic->{id_category} // ( ref $doc->{category} ? $doc->{category}{id} : $doc->{category} ) );
    $self->update_category_status( $doc, $ci_topic->{id_category_status} // $doc->{id_category_status} // $doc->{status_new}, $p{username}, $ci_topic->{modified_on} );

    # detect modified fields
    require Hash::Diff;
    my $diff = Hash::Diff::left_diff( $old_doc, $doc ); # hash has only changed and deleted fields
    my $projects = [ map { $_->{mid} } () ] if %$diff; # data from doc in meta_type=project fields 
    for my $changed ( grep { exists $diff->{$_} } map { $_->{column} } @custom_fields ){
        next if ref $doc->{$changed} || ref $old_doc->{$changed};
        next if $doc->{$changed} eq $old_doc->{$changed};
        my $md = $meta{ $changed };
        my $notify = {
            category        => $doc->{id_category},
            category_status => $doc->{id_category_status},
            field           => $md->{name_field},
        };
        $notify->{project} = $projects if @$projects;
        
        event_new 'event.topic.modify_field' => { 
            username   => $doc->{username},
            field      => $md->{id_field},
            name_field => _loc( $md->{name_field} ),
            old_value  => $old_doc->{$changed},
            new_value  => $doc->{$changed},
            mid => $mid,
        }, 
        sub {
            my $subject = _loc("#%1 %2: Field '%3' updated", $mid, $doc->{title}, $md->{name_field} );
            { mid => $mid, topic => $doc->{title}, subject=>$subject, notify=>$notify }   # to the event
        }, 
        sub {
            _throw _loc( 'Error modifying Topic: %1', shift() );
        };
    }
    
    # create/update mongo doc
    my $m = $doc->{mid};
    $m = 0+$m;
    my $ci_unblessed = Util->_unbless(Util->_clone($ci_topic));
    my $write_doc = { %$old_doc, %$ci_unblessed, %$doc, m=>$m };
    
    # save project collection security
    $self->update_project_security($write_doc);   # we need to send old data merged, in case the user has sent an incomplete topic (due to field security)

    mdb->topic->update({ mid=>"$doc->{mid}" }, $write_doc, { upsert=>1 });

    $self->update_rels(($doc->{mid}));
}

sub update_txt {
    my ($self,@rels ) = @_;
    return '' unless @rels;
    my $txt = join ';', grep { defined && length($_) && ref $_ ne 'HASH' } 
        map { values %$_ } 
        mdb->master_doc->find({ mid=>mdb->in(@rels) })->fields({ mid=>1, name=>1, title=>1 })->all;
    return $txt;
}

sub update_rels {
    my ($self,@mids_or_docs ) = @_;
    my @mids = map { ref $_ eq 'HASH' ? $_->{mid} : $_ } grep { length } _unique( @mids_or_docs );
    my %rels_from = mdb->master_rel->find_hashed(to_mid => { from_mid=>mdb->in(@mids) });
    my %rels_to = mdb->master_rel->find_hashed(from_mid=> { to_mid=>mdb->in(@mids) });

    my %rels_out; 
    map { push @{ $rels_out{ $$_{from_mid} } }, $$_{to_mid} } 
        mdb->master_rel->find({ from_mid=>mdb->in(@mids) })->fields({ to_mid=>1, from_mid=>1 })->all;
    my %rels_in; 
    map { push @{ $rels_in{ $$_{to_mid} } }, $$_{from_mid} } 
        mdb->master_rel->find({ to_mid=>mdb->in(@mids) })->fields({ to_mid=>1, from_mid=>1 })->all;

    my %project_names = map { $$_{mid} => $$_{name} } ci->project->find->fields({ mid=>1, name=>1 })->all;

    my %topic_titles = map{$$_{mid} => $$_{title}} mdb->topic->find({mid=> mdb->in(@mids)})->fields({mid=>1,title=>1,_id=>0})->all;

    # my %rels; map { push @{ $rels{$_->{from_mid}} },$_ } mdb->master_rel->find({ from_mid=>mdb->in(@mids) })->all;
    for my $mid_or_doc ( _unique( @mids_or_docs  ) ) {
        my $is_doc = ref $mid_or_doc eq 'HASH';
        my $mid = $is_doc ? $mid_or_doc->{mid} : $mid_or_doc;
        next unless length $mid;
        my %d;
       
        # resolve to_mids (parent_field)
        my %parent_mapping = 
            map { $_->{parent_field} => $_->{id_field} } 
            grep { $_->{parent_field} } _array( $self->get_meta( $mid ) );
        $d{ $parent_mapping{$_->{rel_field}} }{ $_->{from_mid} }=() 
            for grep { exists $parent_mapping{$_->{rel_field}} } _array( $rels_to{$mid} );
        
        # resolve from_mids
        $d{ $_->{rel_field} }{ $_->{to_mid} }=() for _array( $rels_from{$mid} );
        
        # now uniquify mids in each rel array
        %d = map { $_ => [ sort keys $d{$_} ] } keys %d; 
        
        # and put aggregate text in it, for searching purposes
        my @all_rel_mids = ( 
            (_array($rels_out{$mid}) ), 
            (_array($rels_in{$mid}) )
        );
        $d{_txt} = $self->update_txt(@all_rel_mids);
        
        my @pnames;
        for my $rel ( _array(values %rels_from) ) {
            push @pnames, $project_names{$rel->{to_mid}} if $rel->{rel_type} eq 'topic_project' and $project_names{ $$rel{to_mid} } and $rel->{from_mid} eq $mid_or_doc;
        }
        $d{_sort}{projects} = join '|', sort map { lc( $_ ) } @pnames;  
        
        #adding title to sorting
        my $title = lc $topic_titles{$mid};
        $title =~ s/^\s+//;
        $d{_sort}{title} = $title;


        # cleanup data empty keys (rel_fields empty)
        delete $d{''};
        delete $d{undef};
        
        # single value, no array: %d = map { my @to_mids = keys $d{$_}; $_ => @to_mids>1 ? [ sort @to_mids ] : @to_mids } keys %d; 
        if( $is_doc ) {
            $mid_or_doc->{$_} = $d{$_} for keys %d;  # merge into doc
        } else {
            mdb->topic->update({ mid=>"$mid" }, { '$set'=>\%d });
        }
    }
}

# update categories in mongo
sub update_category {
    my ($self,$mid_or_doc, $id_cat ) = @_; 
    my $doc = ref $mid_or_doc ? $mid_or_doc : mdb->topic->find_mid( $mid_or_doc );
    _fail _loc "Cannot update topic category, topic not found: %1", $mid_or_doc unless ref $doc;
    
    $id_cat //= $doc->{id_category};
       
    my $category = mdb->category->find_one({ id=>"$id_cat" },{ workflow=>0, fieldlets=>0 })
        or _fail _loc 'Category %1 not found', $id_cat;
    my $d = {
        category             => $category,
        color_category       => $$category{color},
        category_color       => $$category{color},
        category_id          => $$category{id},
        id_category          => $$category{id},
        category_name        => $$category{name},
        name_category        => $$category{name},
        is_changeset         => $$category{is_changeset},
        is_release           => $$category{is_release},
    };
    
    if( !ref $mid_or_doc ) {
        # save back to mongo
        mdb->topic->update({ mid=>"$mid_or_doc" },{ '$set'=>$d });
    }
    
    $$doc{$_} = $$d{$_} for keys $d;   # merge hashes while maintaining original hash integrity
    return $doc;
}

# update status in mongo
sub update_category_status {
    my ($self, $mid_or_doc, $id_category_status, $username, $modified_on ) = @_; 
    my $doc =
        ref $mid_or_doc
        ? $mid_or_doc
        : mdb->topic->find_one( { mid => "$mid_or_doc" }, { _status_changes => 1, id_category_status => 1, 'category_status.name' => 1, 'category_status.id' => 1 } );
    _fail _loc "Cannot update topic category status, topic not found: %1", $mid_or_doc unless ref $doc;

    $id_category_status //= $$doc{category_status}{id} // $$doc{id_category_status};
    _fail _loc "Topic %1 does not have a status id", $$doc{mid} unless $id_category_status;
    
    my $category_status = ci->status->find_one({ id_status=>''.$id_category_status },{ yaml=>0, _id=>0 })
        || _fail _loc 'Status `%1` not found', $id_category_status;

    $$category_status{seq} += 0 if defined $$category_status{seq};
    $$category_status{id} = $$category_status{id_status};

    my $d = {
        category_status      => $category_status,
        id_category_status   => $$category_status{id_status},
        category_status_id   => $$category_status{id_status},
        status_new           => $$category_status{id_status},
        category_status_seq  => $$category_status{seq},
        category_status_type => $$category_status{type},
        category_status_name => $$category_status{name},
        name_status          => $$category_status{name},
        modified_by          => $username,
        modified_on          => $modified_on,
    };
    $d->{closed_on} = $modified_on if ( $category_status->{type} =~ /^F/ );

    ### Update topic change status statistics
    my $status_changes = $doc->{_status_changes};
    my $now = Class::Date->now();

    if ( $status_changes->{_name_to_id($doc->{category_status}->{name})} ) {
        my $last = Class::Date->new($status_changes->{last_transition}->{ts});
        my $rel = $now - $last;
        $status_changes->{_name_to_id($doc->{category_status}->{name})}->{total_time} = $status_changes->{_name_to_id($doc->{category_status}->{name})}->{total_time} + $rel->second;
    }

    if ( $status_changes->{_name_to_id($$category_status{name})} ) {
        $status_changes->{_name_to_id($$category_status{name})}->{count} = $status_changes->{_name_to_id($$category_status{name})}->{count} + 1;
    } else {
        $status_changes->{_name_to_id($$category_status{name})}->{count} = 1;
        $status_changes->{_name_to_id($$category_status{name})}->{total_time} = 0;
    }
    my @transitions = _array($status_changes->{transitions});
    push @transitions, { to=> _name_to_id($$category_status{name}), from => _name_to_id($doc->{category_status}->{name}), ts => ''.Class::Date->now() };
    $status_changes->{transitions} = \@transitions;
    $status_changes->{last_transition} = { to=> _name_to_id($$category_status{name}), from => _name_to_id($doc->{category_status}->{name}), ts => ''.Class::Date->now() };

    $d->{_status_changes} = $status_changes;
    if( !ref $mid_or_doc ) {
        # save back to mongo
        mdb->topic->update({ mid=>"$mid_or_doc" },{ '$set'=>$d });
    }
    
    $$doc{$_} = $$d{$_} for keys $d;   # merge hashes while maintaining original hash integrity
    return $doc;
}
    
sub update_projects {
    my ($self,$mid) = @_; 
    my @rels = mdb->master_rel->find({ rel_type=>'topic_project', from_mid=>"$mid" })->all;
    my %prjs;
    for my $d ( @rels ) {
       push @{ $prjs{ $d->{rel_field} } }, $d->{to_mid}; 
    }
    my $doc = mdb->topic->find_one({ mid=>"$mid" });
    _fail _loc 'Topic document not found for topic mid %1', $mid;
    $doc = { %$doc, %prjs }; 
    mdb->topic->save( $doc );
}

sub deal_with_images{
    my ($self, $params ) = @_;
    my $topic_mid = $params->{topic_mid};
    my $field = $params->{field};
    
    for my $img ( $field =~ m{<img src="data:(.*?)"/?>}g ) {   # image/png;base64,xxxxxx
        my ($ct,$enc,$img_data) = ( $img =~ /^(\S+);(\S+),(.*)$/ );
        $img_data = from_base64( $img_data );
        my $img_id = mdb->grid_insert( $img_data, parent_mid=>$topic_mid, content_type=>$ct ); 
        # my $img_md5 = mdb->grid->get( $img_id )->{md5};
        $field =~ s{<img src="data:image/png;base64,(.*?)">}{<img class="bali-topic-editor-image" src="/topic/img/$img_id">};
    }

    for my $img ( $field =~ m{<img*(.*?)>} ){
        if ( !($img =~ m/class/) ){
            $field =~ s{$img}{ class="bali-topic-editor-image" $img};            
        }
    }

    return $field;
}

sub cleanup_images {
    my ($self, $topic_mid, $topic_data) = @_;
    return unless length $topic_mid;
    
    my @img_current_ids;

    # search for deleted images from all fields
    for my $field( grep { length } values %$topic_data ) {        
        next if ref $field;
        for my $img_code ( $field =~ m{"/topic/img/(.+?)"}g ) {   # /topic/img/id
            push @img_current_ids, $img_code;
        }
    }
    
    if( @img_current_ids ) {
        mdb->grid->remove({ md5=>mdb->nin(@img_current_ids), topic_mid=>$topic_mid });
    } else {
        mdb->grid->remove({ topic_mid=>$topic_mid });
    }
}

sub set_cal {
    my ($self, $ci_topic, $cal_data, $user, $id_field ) = @_;
    my $mid = $ci_topic->{mid};
    mdb->master_cal->remove({ mid=>$mid, rel_field=>$id_field },{ multiple=>1 });
   
    for my $row ( _array( $cal_data ) ) {
        $row->{rel_field} = $id_field;
        for( qw/start_date end_date plan_start_date plan_end_date/ ) {
            $row->{$_} =~ s/T/ /g if defined $row->{$_}; 
        }
        $row->{mid} = $mid; 
        $row->{allday} //= 0;
        $row->{id} //= mdb->seq('master_cal');
        mdb->master_cal->insert( $row );
    }
}

sub set_topics {
    my ($self, $ci_topic, $topics, $user, $id_field, $meta, $cancelEvent ) = @_;
    my @all_topics = ();

    my $mid = ''.$ci_topic->mid;
    cache->remove({ mid=>"$mid" }) if length $mid; # qr/:$rs_cache:/ ) 
    
    my $rel_field = $id_field;
    my $field_meta = [ grep { $_->{id_field} eq $id_field } _array($meta) ]->[0];
    my $rel_type = $field_meta->{rel_type} // 'topic_topic';
    my $topic_direction = "from_mid";
    my $data_direction = "to_mid";
    if ( $field_meta->{parent_field} ) {
        $rel_field = $field_meta->{parent_field};
        $topic_direction = "to_mid";
        $data_direction = "from_mid";
    }
    # related topics
    my @new_topics = map { split /,/, $_ } _array( $topics ) ;
    my @old_topics = map { $$_{$data_direction} } 
        mdb->master_rel->find({ $topic_direction=>$mid, rel_type=>$rel_type, rel_field=>$rel_field })->all;
    
    # no diferences, get out
    return if !array_diff(@new_topics, @old_topics);

    my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>$mid, rel_type=>'topic_project' });
    my $notify = {
        category        => $ci_topic->{id_category},
        category_status => $ci_topic->{id_category_status},
        field           => $id_field
    };
    $notify->{project} = \@projects if @projects;
        
    if(@old_topics){
        my $rdoc = {$topic_direction=>$mid, rel_field=>$rel_field, rel_type => $rel_type };
        mdb->master_rel->remove($rdoc,{multiple=>1});
    }

    if( @new_topics ) {
        # check if field is editable
        if( ! $$field_meta{editable} ) {
            _fail _loc 'Field `%1` is not editable in topic #%2', $$field_meta{name_field}, $mid;
        }
        # apply filters, if any
        $self->test_field_match( field_meta=>$field_meta, mids=>\@new_topics ) 
            or _fail _loc 'Incorrect type of topics added to field %1', _loc($$field_meta{name_field});
        # Tenemos que ver primero que los new topics para ese campo exista que sea single
        my @category_single_mode;
        my @categories = _unique map{$_->{category_id}}mdb->topic->find({mid=>mdb->in(@new_topics)})->fields({category_id=>1, _id=>0})->all;
        for my $topic_category (@categories){
            my $meta = Baseliner->model('Topic')->get_meta(undef, $topic_category);
            my @data_field = map {$_}grep{$_->{parent_field} eq $id_field} grep { exists $_->{parent_field}} @$meta;
            if (!@data_field){
                @data_field = map {$_}grep{$_->{release_field} eq $id_field} grep { exists $_->{release_field}} @$meta;
            }
            if ((@data_field) && ($data_field[0]->{single_mode} eq 'true')){
                push @category_single_mode, $topic_category;
            }
        }
        my $where;
        $where->{'category.id'} = mdb->nin(@category_single_mode);
        $where->{'mid'} = mdb->nin(@new_topics);
        my @mid_check_old_relations= mdb->topic->find({mid=>mdb->in(@new_topics), 
            category_id=>mdb->in(@category_single_mode)})->fields({topic_mid=>1, _id=>0})->all;
        for (@mid_check_old_relations){
            my $rdoc = {$data_direction => "$_->{topic_mid}", rel_type =>$rel_type, rel_field=>$rel_field};
            #Buscamos los que se van a borrar, cogemos los mids de las relaciones viejas
            my @old_relations_mids = map{$_->{$topic_direction}}mdb->master_rel->find($rdoc)->all;
            #Borramos las relaciones
            mdb->master_rel->remove($rdoc,{multiple=>1});
            #Borramos de cache los topicos con relaciones antiguas
            for my $rel (@old_relations_mids) { cache->remove({ mid=>"$rel" }) }
        }

        my $rel_seq = 1;  # oracle may resolve this with a seq, but sqlite doesn't
        for (@new_topics){
            my $rdoc = { $topic_direction => ''.$mid, $data_direction => "$_", rel_type =>$rel_type, rel_field=>$rel_field };
            mdb->master_rel->update($rdoc,{ %$rdoc, rel_seq=>0+($rel_seq++) },{ upsert=>1 });
        }

        my $topics = join(',', @new_topics);
        
      
        if($cancelEvent != 1){
            event_new 'event.topic.modify_field' => { username      => $user,
                                                field               => $id_field,
                                                old_value           => '',
                                                new_value           => $topics,
                                                text_new            => '%1 modified topic: %2 ( %4 )',
                                                mid => $mid,
                                               } => sub {
                                my $subject = _loc("#%1 %2 updated", $mid, $ci_topic->{title});

                                { mid => $mid, topic => $ci_topic->{title}, subject => $subject, notify => $notify }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };
        }

    } elsif( @old_topics ) {
        
        if($cancelEvent != 1){
            event_new 'event.topic.modify_field' => { username      => $user,
                                                field               => $id_field,
                                                old_value           => '',
                                                new_value           => '',
                                                text_new            => '%1 deleted all attached topics of ' . $id_field ,
                                                mid => $mid,
                                               } => sub {
                                my $subject = _loc("#%1 %2 updated", $mid, $ci_topic->{title});
                { mid => $mid, topic => $ci_topic->{title}, subject => $subject, notify => $notify }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };
        }

        my $rdoc = {from_mid => $mid, rel_field => $rel_field };
        mdb->master_rel->remove($rdoc,{multiple=>1});
    }

    $self->update_rels( @old_topics, @new_topics );
}

sub test_field_match {
    my ($self,%p) = @_; 
    my $field_meta = $p{field_meta} // _throw 'Missing field_meta';
    my $mids = $p{mids} // _throw 'Missing mids';
    my $categories = $$field_meta{categories};
    if( length($categories) && $categories ne 'none' ) {
        $categories = Util->_load($categories) if !ref $categories;
        my $where = { mid=>mdb->in($mids), 'category.id'=>mdb->in($categories) };
        my @filtered_topics = mdb->topic->find($where)->fields({ mid=>1, _id=>0 })->all;
        return @filtered_topics == _array($mids); 
    }
    return 1;
}

sub set_cis {
    my ($self, $ci_topic, $cis, $user, $id_field, $meta, $cancelEvent ) = @_;

    my $field_meta = [ grep { $_->{id_field} eq $id_field } _array($meta) ]->[0];
    my $name_field = $field_meta->{name_field};

    my $rel_type = $field_meta->{rel_type} or _fail "Missing rel_type for field $id_field";

    # related topics
    my @new_cis = _array( $cis ) ;
    @new_cis  = split /,/, $new_cis[0] if $new_cis[0] && $new_cis[0] =~ /,/ ;
    my @old_cis =
        map { $_->{to_mid} }
        mdb->master_rel->find({ from_mid=>"$ci_topic->{mid}", rel_type=>$rel_type, rel_field=>$id_field })->all;

    my @del_cis = array_minus( @old_cis, @new_cis );
    my @add_cis = array_minus( @new_cis, @old_cis );

    if( @add_cis || @del_cis ) {
        my ($del_cis, $add_cis) = ( '', '' );
        if( @del_cis ) {
            mdb->master_rel->remove({ from_mid => $ci_topic->{mid}, to_mid=>mdb->in(@del_cis), rel_type=>$rel_type, rel_field=>$id_field },{multiple=>1});
            $del_cis = join(',', map { ci->new($_)->name . '[-]' } @del_cis );
        }
        if( @add_cis ) {
            for( @add_cis ) {
                my $rdoc = { from_mid => ''.$ci_topic->{mid}, to_mid=>"$_", rel_type=>$rel_type, rel_field=>$id_field };
                mdb->master_rel->insert($rdoc);
            }
            $add_cis = join(',', map { ci->new($_)->name . '[+]' } @add_cis );
        }
        
        my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>$ci_topic->{mid}, rel_type=>'topic_project' });
        my $notify = {
            category        => $ci_topic->{id_category},
            category_status => $ci_topic->{id_category_status},
            field           => $id_field
        };
        $notify->{project} = \@projects if @projects;
    
        if ($cancelEvent != 1){
            event_new 'event.topic.modify_field' => {
                username  => $user,
                field     => $field_meta->{id_field},
                old_value => $del_cis,
                new_value => join(',', grep { length } $add_cis, $del_cis ),
                text_new  => ( $field_meta->{modify_text_new} // '%1 modified topic (%2): %4 ' ),
                mid => $ci_topic->{mid},
            } => sub {
                my $subject = _loc("#%1 %2 updated: %3 changed", $ci_topic->{mid}, $ci_topic->{title}, $name_field);
                { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, subject => $subject, notify => $notify }    # to the event
            } => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };            
        }
    }
}

sub set_revisions {
    my ($self, $ci_topic, $revisions, $user, $id_field, $meta, $cancelEvent ) = @_;
    
    my $topic_mid = $ci_topic->{mid};
    
    my ($name_field) =  map {$_->{name_field}} grep {$_->{id_field} eq $id_field} _array $meta;

    # related topics
    my @new_revisions = _array( $revisions ) ;
    my @old_revisions = map {$_->{to_mid}} mdb->master_rel->find({ from_mid => $ci_topic->{mid}, rel_type=>'topic_revision' })->all;
   
    my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>$ci_topic->{mid}, rel_type=>'topic_project' });
    my $notify = {
        category        => $ci_topic->{id_category},
        category_status => $ci_topic->{id_category_status},
        field           => $id_field
    };
    $notify->{project} = \@projects if @projects;
            
    if ( array_diff(@new_revisions, @old_revisions) ) {
        if( @new_revisions ) {
            @new_revisions  = split /,/, $new_revisions[0] if $new_revisions[0] =~ /,/ ;
            my @rs_revs = mdb->master->find({mid=>mdb->in(@new_revisions) })->all;
            # first remove all revisions
            mdb->master_rel->remove({ from_mid=>"$topic_mid", rel_type=>'topic_revision', rel_field=>$id_field });
            # now add
            for my $rev ( @rs_revs ) {
                my $rdoc = { to_mid=>"$$rev{mid}", from_mid=>"$topic_mid", rel_type=>'topic_revision', rel_field=>$id_field };
                mdb->master_rel->update($rdoc,{ %$rdoc, rel_seq=>mdb->seq('master_rel') },{ upsert=>1 });
            }
            
            my $revisions = join(',', map { ci->new($_->{mid})->load->{name}} @rs_revs);
    
            if ($cancelEvent != 1){
                event_new 'event.topic.modify_field' => { username   => $user,
                                                    field      => $id_field,
                                                    old_value      => '',
                                                    new_value  => $revisions,
                                                    text_new      => '%1 modified topic: %2 ( %4 )',
                                                    mid => $ci_topic->{mid},
                                                   } => sub {
                                                    my $subject = _loc("#%1 %2 updated: new revisions", $ci_topic->{mid}, $ci_topic->title);

                    { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, subject => $subject, notify => $notify }   # to the event
                } ## end try
                => sub {
                    _throw _loc( 'Error modifying Topic: %1', shift() );
                };                             
            }
            
        } else {
            if ($cancelEvent != 1){
                event_new 'event.topic.modify_field' => { username   => $user,
                                                    field      => $id_field,
                                                    old_value      => '',
                                                    new_value  => '',
                                                    text_new      => '%1 deleted all revisions',
                                                    mid => $ci_topic->{mid},
                                                   } => sub {
                                                    my $subject = _loc("#%1 %2 updated: all revisions removed", $ci_topic->{mid}, $ci_topic->title);
                    { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, subject => $subject, notify => $notify }   # to the event
                } ## end try
                => sub {
                    _throw _loc( 'Error modifying Topic: %1', shift() );
                };
            }

            my $rdoc = {from_mid => ''.$ci_topic->{mid}, rel_type => 'topic_revision', rel_field=>$id_field };
            mdb->master_rel->remove($rdoc,{multiple=>1});
        }
    }
}

sub set_release {
    my ($self, $ci_topic, $release, $user, $id_field, $meta, $cancelEvent) = @_;
    
    my @release_meta = grep { $_->{id_field} eq $id_field } _array $meta;

    my $release_field = $release_meta[0]->{release_field} // 'undef';
    my $name_field = $release_meta[0]->{name_field} // 'undef';
    my $rel_type = $release_meta[0]->{rel_type} // 'topic_topic';


    my $topic_mid = $ci_topic->{mid};
    $self->cache_topic_remove($topic_mid);
    my $where = { rel_type=>$rel_type, to_mid=>"$topic_mid" };
    $where->{rel_field} = $release_field if $release_field;
    my @rel_mids = map { $$_{from_mid} } mdb->master_rel->find($where)->fields({ from_mid=>1 })->all;
    my $release_row = mdb->topic->find_one({ is_release=>mdb->true, mid=>mdb->in(@rel_mids) });
    my $old_release = '';
    my $old_release_name = '';
    if($release_row) {
        $old_release = $release_row->{mid};
        $old_release_name = $release_row->{title};
    }        
        
    my ($new_release) = _array( $release );

    my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>$ci_topic->{mid}, rel_type=>'topic_project' });
    my $notify = {
        category        => $ci_topic->{id_category},
        category_status => $ci_topic->{id_category_status},
        field           => $id_field
    };
    $notify->{project} = \@projects if @projects;

    # check if arrays contain same members
    if ( $new_release ne $old_release ) {
        if($release_row){
            my $rdoc = {from_mid => "$old_release", to_mid=>''.$topic_mid, rel_field => $release_field, rel_type=>$rel_type};
            mdb->master_rel->remove($rdoc,{multiple=>1});
        }
        # release
        if( $new_release ) {
            my $row_release = mdb->topic->find_one({ mid=>$new_release });
            my $rdoc = { from_mid=>"$$row_release{mid}", to_mid=>"$topic_mid", rel_type=>$rel_type, rel_field=>$release_field };
            mdb->master_rel->update($rdoc, { %$rdoc, rel_seq=>mdb->seq('master_rel') },{ upsert=>1 });
    
            if ($cancelEvent != 1){
                event_new 'event.topic.modify_field' => { username   => $user,
                                                    field      => $id_field,
                                                    old_value      => $old_release_name,
                                                    new_value  => $row_release->{title},
                                                    text_new      => '%1 modified topic: changed %2 to %4',
                                                    mid => $ci_topic->{mid},
                                                   } => sub {
                                                    my $subject = _loc("#%1 %2 updated: %4 changed to %3", $ci_topic->{mid}, $ci_topic->{title}, $row_release->{title}, $name_field);
                    { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, subject => $subject, notify => $notify }   # to the event
                } ## end try
                => sub {
                    _throw _loc( 'Error modifying Topic: %1', shift() );
                };                
            }
        }else{
            mdb->master_rel->remove({from_mid => $old_release, to_mid=>$topic_mid, rel_type=>$rel_type, rel_field => $release_field },{multiple=>1});
	        $self->cache_topic_remove($old_release);
            if ($cancelEvent != 1){            
                event_new 'event.topic.modify_field' => { username   => $user,
                                                    field      => $id_field,
                                                    old_value      => $old_release_name,
                                                    new_value  => '',
                                                    text_new      => '%1 deleted %2 %3',
                                                    mid => $ci_topic->{mid},
                                                   } => sub {
                                                    my $subject = _loc("#%1 %2 updated: removed from %4 %3", $ci_topic->{mid}, $ci_topic->{title}, $old_release_name, $release_field);

                    { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, subject => $subject, notify => $notify}   # to the event
                } ## end try
                => sub {
                    _throw _loc( 'Error modifying Topic: %1', shift() );
                };  
            }
        }
    }
    $self->update_rels( $old_release, $new_release );
}

sub set_projects {
    my ($self, $ci_topic, $projects, $user, $id_field, $meta, $cancelEvent ) = @_;
    my $topic_mid = $ci_topic->{mid};
    my ($name_field) =  map {$_->{name_field}} grep {$_->{id_field} eq $id_field} _array $meta;
    
    my @new_projects = sort { $a <=> $b } _array( $projects ) ;
    my @old_projects = sort { $a <=> $b } map { $_->{to_mid} } 
        mdb->master_rel->find({ from_mid=>"$topic_mid", rel_type=>'topic_project', rel_field=>$id_field })->all;

    my $notify = {
        category        => $ci_topic->{id_category},
        category_status => $ci_topic->{id_category_status},
        field           => $id_field
    };
    $notify->{project} = \@old_projects if @old_projects;
    
    # check if arrays contain same members
    if ( array_diff(@new_projects, @old_projects) ) {
        my $rdoc = {from_mid => "$topic_mid", rel_type => 'topic_project', rel_field => $id_field};
        mdb->master_rel->remove($rdoc,{multiple=>1});
        
        # projects
        if (@new_projects){
            my @name_projects;
            my $rs_projects = mdb->master_doc->find({mid =>mdb->in(@new_projects) });
            while( my $project = $rs_projects->next){
                push @name_projects,  $project->{name};
                my $rdoc = { to_mid=>''.$project->{mid}, from_mid=>"$topic_mid", rel_type=>'topic_project', rel_field=>$id_field };
                mdb->master_rel->update($rdoc, { %$rdoc, rel_seq=>mdb->seq('master_rel') },{ upsert=>1 });
            }
            
            my $projects = join(',', @name_projects);
    
            if ($cancelEvent != 1) {
                event_new 'event.topic.modify_field' => { username   => $user,
                                                    field      => $id_field,
                                                    old_value      => '',
                                                    new_value  => $projects,
                                                    text_new      => '%1 modified topic: %2 ( %4 )',
                                                    mid => $ci_topic->{mid},
                                                   } => sub {
                                                    my $subject = _loc("#%1 %2 updated: %4 (%3)", $ci_topic->{mid}, $ci_topic->{title}, $projects, $name_field);
                    { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, subject => $subject, notify => $notify }   # to the event
                } ## end try
                => sub {
                    _throw _loc( 'Error modifying Topic: %1', shift() );
                };            
            }
        }
        else{
            if ($cancelEvent != 1){
                event_new 'event.topic.modify_field' => { username   => $user,
                                                    field      => $id_field,
                                                    old_value      => '',
                                                    new_value  => '',
                                                    text_new      => '%1 deleted %2',
                                                    mid => $ci_topic->{mid},
                                                   } => sub {
                                                    my $subject = _loc("#%1 %2 updated: %3 deleted", $ci_topic->{mid}, $ci_topic->{title}, $name_field );
                    { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, subject => $subject, notify => $notify }   # to the event
                } ## end try
                => sub {
                    _throw _loc( 'Error modifying Topic: %1', shift() );
                };              
            }
        }
    }
}

sub set_users{
    my ($self, $ci_topic, $users, $user, $id_field, $meta, $cancelEvent ) = @_;
    my $topic_mid = $ci_topic->{mid};
    
    my @new_users = _array( $users ) ;
    my @old_users = map { $$_{to_mid} } mdb->master_rel->find({from_mid =>"$topic_mid", rel_type=>'topic_users', rel_field=>$id_field })->all;

    my $notify = {
        category        => $ci_topic->{id_category},
        category_status => $ci_topic->{id_category_status},
        field           => $id_field
    };

    my $name_category = mdb->category->find_one({ id=>$ci_topic->{id_category} })->{name};
    
    my @projects = sort { $a <=> $b } map { $_->{to_mid} } 
        mdb->master_rel->find({ from_mid=>"$topic_mid", rel_type=>'topic_project', rel_field=>$id_field })->all;
    $notify->{project} = \@projects if @projects;
    
    # check if arrays contain same members
    @new_users = grep { is_number($_) } @new_users;
    if ( array_diff(@new_users, @old_users) ) {
        my $rdoc = {from_mid => "$topic_mid", rel_type => 'topic_users', rel_field=>$id_field };
        mdb->master_rel->remove($rdoc,{multiple=>1});
        # users
        if (@new_users){
            my @name_users;
            my $rs_users = ci->user->find({mid => mdb->in(@new_users)});
            while(my $user = $rs_users->next){
                push @name_users,  $user->{username};
                my $rdoc = { to_mid=>''.$user->{mid}, from_mid=>"$topic_mid", rel_type=>'topic_users', rel_field => $id_field };
                mdb->master_rel->update($rdoc,{ %$rdoc, rel_seq=>mdb->seq('master_rel') },{ upsert=>1 });
            }

            my $users = join(',', @name_users);

            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => $id_field,
                                                old_value      => '',
                                                new_value  => $users,
                                                text_new      => '%1 modified topic: %2 ( %4 )',
                                                mid => $ci_topic->{mid},
                                               } => sub {
                { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, notify => $notify, subject => _loc("Topic %1 (%2) has been assigned to you",$ci_topic->{mid},$name_category) }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };            

        }else{
            if ( !$cancelEvent ) {
                event_new 'event.topic.modify_field' => { username   => $user,
                                                    field      => $id_field,
                                                    old_value      => '',
                                                    new_value  => '',
                                                    text_new      => '%1 deleted all users',
                                                    mid => $ci_topic->{mid},
                                                   } => sub {
                    { mid => $ci_topic->{mid}, topic => $ci_topic->{title}, notify => $notify }   # to the event
                } ## end try
                => sub {
                    _throw _loc( 'Error modifying Topic: %1', shift() );
                };                              
            }

        }
    }
}

sub set_labels {
    my ($self, $ci_topic, $labels ) = @_;
    
    # XXX do nothing, now labels are in the mongo doc
}

sub get_categories_permissions{
    my ($self, %param) = @_;
    
    my $cache_key = { d=>'topic:meta', p=>\%param };
    ref($_) && return @$_ for cache->get($cache_key);
    
    my $username = delete $param{username};
    my $type = delete $param{type};
    my $order = delete $param{order};
    my $topic_mid = delete $param{topic_mid};
    
    my $dir = $order->{dir} && $order->{dir} =~ /desc/i ? -1 : 1;
    my $sort = $order->{sort} || 'name';
    
    my $re_action;

    if ( $type eq 'view') {
        $re_action = qr/^action\.topics\.(.*?)\.(view|edit|create)$/;
    } elsif ($type eq 'edit') {
        $re_action = qr/^action\.topics\.(.*?)\.(edit|create)$/;
    } elsif ($type eq 'create') {
        $re_action = qr/^action\.topics\.(.*?)\.(create)$/;
    } elsif ($type eq 'delete') {
        $re_action = qr/^action\.topics\.(.*?)\.(delete)$/;
    } elsif ($type eq 'comment') {
        $re_action = qr/^action\.topics\.(.*?)\.(comment)$/;
    }
    
    my @permission_categories;
    my $where = { id=>"$param{id}" } if $param{id};
    my $rs = mdb->category->find($where);
    $rs->fields({ id=>1, name=>1, color=>1 }) if !$param{all_fields}; 
    my @categories  = $rs->sort({ $sort=>$dir })->all;
    if ( Baseliner->model('Permissions')->is_root( $username) ) {
        return @categories;
    }
    
    push @permission_categories, _unique map { 
        $_ =~ $re_action;
        $1;
    } Baseliner->model('Permissions')->user_actions_list( username => $username, action => $re_action, mid => $topic_mid);
    
    my %granted_categories = map { $_ => 1 } @permission_categories;
    @categories = grep { $granted_categories{_name_to_id( $_->{name} )}} @categories;

    cache->set($cache_key, \@categories );
    return @categories;
}

sub get_meta_permissions {
    my ($self, %p) = @_;
    my ($username, $meta, $data, $name_category, $name_status,$id_category,$id_status) = 
        @p{qw(username meta data name_category name_status id_category id_status)};
    my @hidden_field;
    
    my $mid = $data->{topic_mid};
    my $cache_key = { d=>'topic:meta', 
        st=>($id_status//$$data{category_status}{id}//$name_status//_fail('Missing id_status')), 
        cat=>($id_category//$data->{category}{id}//_fail('Missing category.id')), u=>$username };
    defined && return $_ for cache->get($cache_key);
    
    my $parse_category = $data->{name_category} ? _name_to_id($data->{name_category}) : _name_to_id($name_category);
    my $parse_status = $data->{name_status} ? _name_to_id($data->{name_status}) : _name_to_id($name_status);
    my $sec = $data->{_project_security};
    
    my $is_root = model->Permissions->is_root( $username );
    my $user_security = ci->user->find_one( {name => $username}, { project_security => 1, _id => 0} )->{project_security};
    my $user_actions = model->Permissions->user_actions_by_topic( username=> $username, user_security => $user_security );
    my @user_actions_for_topic = $user_actions->{positive};
    my @user_read_actions_for_topic = $user_actions->{negative};

    for (_array $meta){
        my $parse_id_field = _name_to_id($_->{name_field});
        
        if($_->{fieldlets}){
        	my @fields_form = _array $_->{fieldlets};
            for my $field_form ( @fields_form ){
                my $parse_field_form_id = $field_form->{id_field};
                my $write_action = join '.', 'action.topicsfield', $parse_category, $parse_id_field,  $parse_field_form_id, $parse_status, 'write';
                if ( $is_root ) {
                        $field_form->{readonly} = \0;
                        $field_form->{allowBlank} = 'true' unless $field_form->{id_field} eq 'title';
                } else {
                    my $has_action = $write_action  ~~ @user_actions_for_topic;
                    if ( $has_action ){
                        $field_form->{readonly} = \0;
                    }else{
                        $field_form->{readonly} = \1;
                    }
                }                    
                my $read_action = join '.', 'action.topicsfield',  $parse_category,  $parse_id_field,  $parse_field_form_id, 'read';
                if ( $is_root ) {
                        $field_form->{hidden} = \0;
                } else {

                    if ( $read_action ~~ @user_read_actions_for_topic ){
                    # if (model->Permissions->user_has_read_action( username=> $username, action => $read_action )){
                        $field_form->{hidden} = \1;
                        #push @hidden_field, $field_form->{id_field};
                    }
                }
            }
        }else{
            my $write_action = 'action.topicsfield.' .  $parse_category . '.' .  $parse_id_field . '.' . $parse_status . '.write';
            my $readonly = 0;
            if ( $is_root ) {
                    $_->{readonly} = \0;
                    $_->{allowBlank} = 'true' unless $_->{id_field} eq 'title';
            } else {
                my $has_action = $write_action ~~ @user_actions_for_topic;
                #my $has_action = model->Permissions->user_has_action( username=> $username, action => $write_action, mid => $data->{topic_mid} );
                # _log "Comprobando ".$write_action."= ".$has_action;
                if ( $has_action ){
                    $_->{readonly} = \0;
                }else{
                    $_->{readonly} = \1;    
                    $readonly = 1;
                }
            }
            
            my $read_action = 'action.topicsfield.' .  $parse_category . '.' .  $parse_id_field . '.read';
            my $read_action_status = 'action.topicsfield.' .  $parse_category . '.' .  $parse_id_field . '.' . $parse_status . '.read';

            if ( !$is_root ) {
                if ( $read_action ~~ @user_read_actions_for_topic || $read_action_status ~~ @user_read_actions_for_topic || ($readonly && $_->{hidden_if_protected} && $_->{hidden_if_protected} eq 'true')){
                    push @hidden_field, $_->{id_field};
                }
            } 

        }
    }
    
    my %hidden_field = map { $_ => 1} @hidden_field;
    $meta = [grep { !($hidden_field{ $_->{id_field} }) } _array $meta];
        
    #_debug $meta;
    cache->set($cache_key,$meta);
    return $meta
}

# Global search

with 'Baseliner::Role::Search';

sub search_provider_name { 'Topics' };
sub search_provider_type { 'Topic' };
sub search_query {
    my ($self, %p ) = @_;
    my $params = $p{params} // {};
    my ($info, @rows ) =  $self->topics_for_user({ username=>$p{username}, limit=>$p{limit} // 1000, query=>$p{query}, topic_list=>$params->{topic_list}, clear_filter => 1});
    my @mids = map { $_->{topic_mid} } @rows;
    #my %descs = mdb->topic->find_hashed(mid => { mid=>mdb->in(@mids) },{ description=>1, mid=>1 })->all;
    return map {
        my $r = $_;
        #my $text = join ',', map { "$_: $r->{$_}" } grep { defined $_ && defined $r->{$_} } keys %$r;
        my @text = 
            map { "$_" }
            grep { length }
            map { _array( $_ ) }
            grep { defined }
            map { $r->{$_} }
            qw/category_name projects 
                assignee file_name category_status_name 
                labels modified_on modified_by created_on created_by 
                references_out referenced_in cis_out cis_in/;  # consider put references in separate, lower priority field
        push @text, _loc('Release') if $r->{is_release};
        push @text, _loc('Changeset') if $r->{is_changeset};
        my $info = join(', ',@text);
        my $desc = _strip_html( sprintf "%s %s", ($r->{description} // ''), ($r->{text} // '') );
        if( length $desc ) {
            $desc = _utf8 $desc;  # strip html messes up utf8
            $desc =~ s/[^\w\s]//g; 
            #$desc =~ s/[^\x{21}-\x{7E}\s\t\n\r]//g; 
        }
        +{
            title => sprintf( '%s', $_->{title} ),
            text  => $desc,
            info  => $info,
            url   => [ $_->{topic_mid}, $_->{topic_name}, $_->{category_color}, $_->{category_name} ],
            type  => 'topic',
            mid   => $r->{topic_mid},
            id    => $r->{topic_mid},
        }
    } @rows;
}

sub getAction {
    my ( $self, $type ) = @_;
    my $action;
    given ($type) {
        when ('I') { $action = 'New' }
        when ('F') { $action = 'Ok' }
        when ('FC') { $action = 'Fail' }
        when ('G') {$action = 'Processing'}
        default {$action = 'none'}
    }
    return $action
}

=head2 user_workflow

Workflow for a user. Gets the user role, then search for workflows.

=cut
sub user_workflow {
    my ( $self, $username, %p ) = @_;
    
    return Baseliner->model('Permissions')->is_root( $username ) 
        ? $self->root_workflow(%p) 
        : $self->non_root_workflow($username, %p);
}

=head2 non_root_workflow

Workflow for ordinary users. Usually 
called by user_workflow.

=cut
sub non_root_workflow {
    my ( $self, $username, %p ) = @_;
    my %roles = map { $_=>1 } Baseliner->model('Permissions')->user_role_ids($username);
    my $where = { 'workflow.id_role'=>mdb->in(keys %roles) };
    $where->{id} = mdb->in($p{categories}) if exists $p{categories};
    return _array( map { 
        # add category id to workflow array
        my $id_cat = $$_{id};
        [ map { $$_{id_category}=$id_cat; $_ } grep { $roles{$$_{id_role}} } _array($$_{workflow}) ]
    } mdb->category->find($where)->all );
}

=head2 root_workflow

Maximum workflow possible (for root user), 
all categ statuses to all categ statuses.

=cut
sub root_workflow {
    my ($self,%p) = @_;
    my %statuses = ci->status->statuses;
    my $where = {};
    $where->{id} = mdb->in($p{categories}) if exists $p{categories};

    my @categories = mdb->category->find($where)->fields({ statuses=>1, id=>1 })->all;
    my @wf;

    for my $cat (@categories) {
        my @stats = map { $statuses{$_} } _array( $cat->{statuses} );
        map {
            my $stat_from = $_;
            map {
                my $stat_to = $_;
                push @wf, {
                    id_status_from   => $stat_from->{id_status},
                    seq_from         => $stat_from->{seq},
                    status_name_from => $stat_from->{name},
                    id_status        => $stat_to->{id_status},
                    id_status_to     => $stat_to->{id_status},
                    seq_to           => $stat_to->{seq},
                    status_name      => $stat_to->{name},
                    status_bl        => $stat_to->{bl},
                    id_category      => $cat->{id},
                    seq              => $stat_to->{seq},
                }
            } @stats;
        } @stats;
    }

    @wf;    
}

sub list_posts {
    my ($self, %p) = @_;
    my $mid = $p{mid};

    if( $p{count_only} ) {
        return mdb->master_rel->find({ from_mid=>"$mid", rel_type=>'topic_post' })->count;
    }
    my @posts = sort { $b->ts cmp $a->ts } ci->new( $mid )->children( where=>{collection=>'post'} );
    my @rows;
    for my $r ( @posts ) {
        try{
            push @rows, {
                created_on   => $r->ts || $r->created_on,
                created_by   => $r->created_by,
                text         => $r->text,
                content_type => $r->content_type,
                id           => $r->mid,
            };
        }catch{
        };
    }
    return \@rows;
}

sub find_status_name {
    my ($self, $id_status ) = @_;
    [ map { $$_{name} } ci->status->find_one({ id_status=>"$id_status" },{ name=>1 }) ]->[0];
}

sub cache_topic_remove {
    my ($self, $topic_mid ) = @_;
    # my own first

    # refresh cache for related stuff 
    if ($topic_mid && $topic_mid ne -1) {    
        cache->remove({ mid=>"$topic_mid" }); #qr/:$topic_mid:/;
        for my $rel_mid ( 
            map { $_->{from_mid} == $topic_mid ? $_->{to_mid} : $_->{from_mid} }
            mdb->master_rel->find({ '$or'=>[{from_mid=>"$topic_mid"},{to_mid=>"$topic_mid"}] })->all
            )
        {
            #_debug "TOPIC CACHE REL remove :$rel_mid:";
            cache->remove({ mid=>"$rel_mid" }); # qr/:$rel_mid:/
        }
    };
}

sub change_status {
    my ($self, %p) = @_;
    my $mid = $p{mid} or _throw 'Missing parameter mid';
    $p{id_status} or _throw 'Missing parameter id_status';
    
    my $doc = mdb->topic->find_one({ mid=>"$mid" });
    my $id_old_status = $p{id_old_status} || $doc->{category_status}{id};
    my $status = $p{status} || $self->find_status_name($p{id_status});
    my $old_status = $p{old_status} || $self->find_status_name($id_old_status);
    my $callback = $p{callback};
    my @projects = map {$_->{mid}} ci->new($mid)->projects;

    event_new 'event.topic.change_status'
        => { mid => $mid, username => $p{username}, old_status => $old_status, id_old_status=> $id_old_status, id_status=>$p{id_status}, status => $status }
        => sub {
            # should I change the status?
            if( $p{change} ) {
                _fail( _loc('Id not found: %1', $mid) ) unless $doc;
                _fail _loc "Current topic status '%1' does not match the real status '%2'. Please refresh.", $doc->{category_status}{name}, $old_status 
                    if $doc->{category_status}{id} != $id_old_status;
                # XXX check workflow for user?
                # update mongo
                #my $modified_on = $doc->{modified_on};
                my $modified_on = mdb->ts;
                $self->update_category_status( $mid, $p{id_status}, $p{username}, $modified_on );
                
                $self->cache_topic_remove( $mid );
            }
            # callback, if any
            $callback->() if ref $callback eq 'CODE';
            
            my @users = $self->get_users_friend(mid => $mid, id_category => $doc->{id_category}, id_status => $p{id_status});
            
            my $notify = {
                project         => \@projects,
                category        => $doc->{id_category},
                category_status => $p{id_status},
            };

            my $subject = _loc("%3: #%1 %2", $mid, $doc->{title}, $status );
            mdb->master_cal->update({ mid => "$mid", slotname => $status, end_data => undef }, { '$set' => { end_date => ''.Class::Date->now }});
            +{ mid => $mid, title => $doc->{title}, notify_default => \@users, subject => $subject, notify => $notify } ;       
        } 
        => sub {
            _throw _loc( 'Error modifying Topic: %1', shift() );
        };                    
}

# fieldlet status_changes
sub status_changes {
    my ($self, $data) = @_;
    my @status_changes;
    my $cont = 0;
    for my $ev ( mdb->activity->find({ event_key=>'event.topic.change_status', mid=>$data->{topic_mid} })->sort({ ts=>-1 })->limit(100)->all ) {
        try {
            my $ed = $ev->{vars};
            push @status_changes, {
                old_status => $ed->{old_status},
                status     => $ed->{status},
                username   => $ed->{username},
                when       => Class::Date->new( $ev->{ts} )
            };
        } catch {};
    }
    return @status_changes;
}

sub get_users_friend {
    my ($self, %p) = @_;

    my @users;
    my $mid = $p{mid};
    my @roles = _unique map { $_->{id_role} } grep { $$_{id_status_from} == $p{id_status} } _array(
        mdb->category->find_one( 
            { id => ''.$p{id_category} },
            { workflow=>1 })->{workflow}
    );
    if (@roles){
        @users = Baseliner->model('Users')->get_users_from_mid_roles( mid => $mid, roles => \@roles);
        @users = _unique @users;
    }
    return @users
}

sub check_fields_required {
    my ($self, %p) = @_;
    my $mid = $p{mid} or _throw 'Missing parameter mid';
    my $username = $p{username} or _throw 'Missing parameter username';
    
    my $is_root = Baseliner->model('Permissions')->is_root( $username );
    my $isValid = 1;
    my @fields_required = ();
    my $field_name;
    if (!$is_root){
        if($mid != -1){
            my $meta = Baseliner->model('Topic')->get_meta( $mid );
            my %fields_required =  map { $_->{id_field} => $_->{name_field} } grep { $_->{allowBlank} && $_->{allowBlank} eq 'false' && $_->{origin} ne 'system' } _array( $meta );
            my $data = Baseliner->model('Topic')->get_data( $meta, $mid, no_cache => 1 );  
            
            for my $field ( keys %fields_required){
                next if !Baseliner->model('Permissions')->user_has_action( 
                    username => $username, 
                    action => 'action.topicsfield.'._name_to_id($data->{name_category}).'.'.$field.'.'._name_to_id($data->{name_status}).'.write',
                    mid => $mid
                );
                my $v = $data->{$field};
                $isValid = (ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? keys %$v : defined $v && $v ne '' ) ? 1 : 0;
                if($p{data}){
                    $v = $p{data}->{$field};
                    $isValid = (ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? keys %$v : defined $v && $v ne '' ) ? 1 : 0;                
                }
                
                push @fields_required , $fields_required{$field} if !$isValid;
                last if !$isValid;
            }
        } else {
            my $data = $p{data} or _throw 'Missing parameter data';
            my $meta = Baseliner->model('Topic')->get_meta(undef, $data->{category} );
            my $category = mdb->category->find_one({ id=>''.$data->{category} });
            my $status = ci->status->find_one({ id_status=>''. $data->{status_new} });
            
            my %fields_required =
                map { $_->{id_field} => $_->{name_field} }
                grep { $_->{allowBlank} && $_->{allowBlank} eq 'false' && $_->{origin} ne 'system' } _array($meta);
            for my $field ( keys %fields_required){
                next if !Baseliner->model('Permissions')->user_has_action( 
                    username => $username, 
                    action => 'action.topicsfield.'._name_to_id($category->{name}).'.'.$field.'.'._name_to_id($status->{name}).'.write',
                    mid => $mid
                );
                my $v = $data->{$field};
                $isValid = (ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? keys %$v : defined $v && $v ne '' ) ? 1 : 0;
                
                push @fields_required , $fields_required{$field} if !$isValid;
                last if !$isValid;
            }            
        }
    }
    return ($isValid, @fields_required);
}

sub get_short_name {
    my ($self, %p) = @_;
    my $name = $p{name} or _throw 'Missing parameter name';
    my $acronyms = _decode_json($self->getCategoryAcronyms());
    
    if ( $acronyms->{$name} ) {
        $name = $acronyms->{name};
    }
    return $name; 
}

sub user_can_search {
    my ($self, $username) = @_;
    return Baseliner->model('Permissions')->user_has_action( username => $username, action => 'action.search.topic');
}

sub apply_filter{
    my ($self, $where, %filter) = @_;

    for my $key (keys %filter){
        given ($key) {
            when ('mid') {
                $where->{'mid'} = mdb->in($filter{mid});
            }
            when ('category_id') {
                my @category_id = _array $filter{category_id};
                my @not_in = map { abs $_ } grep { $_ < 0 } @category_id;
                my @in = @not_in ? grep { $_ > 0 } @category_id : @category_id;
                if (@not_in && @in){
                    $where->{'category.id'} = [mdb->nin(@in), mdb->in(@in)];    
                }else{
                    if (@not_in){
                        $where->{'category.id'} = mdb->nin(@in);
                    }else{
                        $where->{'category.id'} = mdb->in(@in);  
                    }
                } 
            }
            when ('category_type') {
                given ($filter{category_type}){
                    when ('release') {
                        $where->{'category.is_release'} = '1';
                    }
                    when ('changeset'){
                        $where->{'category.is_changeset'} = '1';
                    }
                };
            }
            when ('category_status_id') {
                my @category_status_id = _array $filter{category_status_id};
                my @not_in = map { abs $_ } grep { 0+$_ < 0 } @category_status_id;
                my @in = @not_in ? grep { 0+$_ > 0 } @category_status_id : @category_status_id;
                if (@not_in && @in){
                    $where->{'category_status.id'} = [mdb->nin(@not_in), mdb->in(@in)];
                }else{
                    if (@not_in){
                        $where->{'category_status.id'} = mdb->nin(@not_in);
                    }else{
                        $where->{'category_status.id'} = mdb->in(@in);  
                    }
                } 
            }
            default {
                my @ids = _array $filter{$key};
                $where->{$key} = mdb->in(@ids);
            }        

        };
    }

    return $where;
}

sub get_topics_mdb{
    my ($self, %p ) = @_;
    my ($where, $username, $start, $limit, $fields) = @p{qw(where username start limit fields)}; 
    try{
        $where = {} if !$where;
        _throw _loc('Missing username') if !$username;

        Baseliner->model('Permissions')->build_project_security( $where, $username );
        #_warn $where;

        my $rs_topics = mdb->topic->find($where);
        $rs_topics->fields($fields) if $fields;
        my $cnt = $rs_topics->count;
        $rs_topics->skip($start) if ($start);
        $rs_topics->limit($limit) if ($limit);

        return ($cnt , $rs_topics->all);
    }
    catch{
        _throw _loc( 'Error getting Topics ( %1 )', shift() );
    }
}

sub get_fields_topic{
    my ($self) = @_;

    my @fields = map {$_} keys mdb->topic->find_one({},{ _txt=>0 }); #TODO: Improve to get all fields from topic collection. 

    return \@fields;
}

sub group_by_status { 
    my ($self,%p) = @_;
    my @topics = _array(ci->new( $p{mid} )->children( where => { collection => 'topic'}, depth => $p{depth}, docs_only => 1 ));
    if ( $p{filter_category} ) {
        if ( is_number($p{filter_category} ) ) {
            @topics = grep { $_->{id_category} eq $p{filter_category}} @topics;
        } else {
            @topics = grep { $_->{name_category} eq $p{filter_category} } @topics;
        }
    }
    @topics = map { $_->{mid} } @topics;

    my %statuses = mdb->topic->find_hashed(
        'id_category_status' => { mid => mdb->in(@topics) },
        {
            id_category_status      => 1,
            'category_status.color' => 1,
            'category_status.id'    => 1,
            'category_status.name'  => 1
        }
    );
    return (\@topics, map {
        my @v = _array( $statuses{$_} );
        +{
            status    => $v[0]->{category_status}{name},
            color     => $v[0]->{category_status}{color},
            status_id => $v[0]->{category_status}{id},
            total     => scalar @v
            }
    } keys %statuses);
}

sub get_status_history_topics{
    my ($self, %p) = @_;

    my $username = $p{username} or _throw 'Missing parameter username';
    my $topic_mid = $p{topic_mid} // undef;
    my $now1 = my $now2 = mdb->now;
    $now2 += '1D';

    my $date_from = $p{date_from} // $now1->ymd;
    my $date_until = $p{date_until} // $now2->ymd;
    $date_from =~ s/\//-/g;
    $date_until =~ s/\//-/g;

    my $query = {
        event_key   => 'event.topic.change_status',
        ts          => { '$lte' => ''.$date_until, '$gte' => ''.$date_from },
    };

    my %my_topics;

    #############################################################

    my $total = 1000;
    my @rows;
    my $i = 0;
    my $limit = 100;
    my @res;
    my $cnt = 0;
    for ($i=0; $i<$total; $i=$i+$limit){
        if ($i+$limit>$total) { $limit = $total-$i; };
        my ($partial_cnt, @res ) = Baseliner->model('Topic')->topics_for_user({ username => $username, start=>$i, limit=>$limit, query=>undef });
        push @rows, @res;
        $cnt = $cnt + $partial_cnt;
    }

    #############################################################

    # my ($cnt, @rows ) = Baseliner->model('Topic')->topics_for_user({ username => $username, limit=>1000, query=>undef });
    map { $my_topics{$_->{mid}} = 1 } @rows;

    my @status_changes;
    my @mid_topics;

    my @topics = mdb->event->find($query)->sort({ ts=>-1 })->all;
    map {
        
            my $ed = _load( $_->{event_data} );
            try{
                if ( (exists $my_topics{$ed->{topic_mid}} || Baseliner->model("Permissions")->is_root( $username ) ) && $ed->{old_status} ne $ed->{status}){
                    push @status_changes, { old_status => $ed->{old_status}, status => $ed->{status}, username => $ed->{username}, when => $_->{ts}, mid => $ed->{topic_mid} };
                    push @mid_topics, $ed->{topic_mid};
                }
            }catch{
                _log ">>>>>>>>>>>>>>>>>>>>Error topic: $ed->{topic_mid} ";
            }
    } @topics;

    if ($topic_mid) {
        return  grep {$_->{mid} eq $topic_mid} @status_changes;
    }else{
        return @status_changes;    
    }
}

sub upload {
    my ($self, %c) = @_;
    
    my $f = $c{f};
    my $p = $c{p};
    my $username = $c{username};

    my $filename = $p->{qqfile};
    my ($extension) =  $filename =~ /\.(\S+)$/;
    $extension //= '';
    my $msg;
    my $success;
    my $status;
    try {
        if((length $p->{topic_mid}) && (my $topic = mdb->topic->find_one({mid=>$p->{topic_mid}},{ mid=>1, category=>1 }))) {
            my ($topic_mid, $file_mid);
            $topic_mid = $topic->{mid};
            my $file_field = $$p{filter};
            #Comprobamos que el campo introducido es correcto
            my $found = 0;
            my $meta = model->topic->get_meta($topic_mid);
            for my $field ( _array $meta ) {
                if (( $field->{id_field} eq $file_field ) and ( $field->{type} eq 'upload_files' )) {
                    $found = 1;
                }
            }
            if (!$found){
                $msg = "The related field does not exist for the topic: " .  $topic_mid;
                $success = "false";
                $status = 404;
                return (success=>$success, msg=>$msg, status=>$status);
            }
            #Comprobamos que existe el fichero
            if (!-e $f){
                $msg = "The file " . $f . " does not exis: " .  $topic_mid;
                $success = "false";
                $status = 404;
                return (success=>$success, msg=>$msg, status=>$status);
            }

            #my @projects = ci->children( mid=>$_->{mid}, does=>'Project' );
            my @users = Baseliner->model("Topic")->get_users_friend(
                mid         => $p->{topic_mid}, 
                id_category => $topic->{category}{id}, 
                id_status   => $topic->{category_status}{id},
                #  projects    => \@projects  # get_users_friend ignores this
            );
            
            my $versionid = 1;
            #Comprobamos que non existe un fichero con el mismo md5 y el mismo título $filename
            my $md5 = _md5 ($f);

            my @files_mid = map{$_->{to_mid}}mdb->master_rel->find({ from_mid=>$topic_mid, rel_type=> 'topic_asset'})->all;
            my $highest_version;
            
            for my $file_mid (@files_mid){
                my $asset = ci->asset->find_one({mid=>$file_mid});
                $asset->{md5} = mdb->grid->files->find_one({ _id=>mdb->oid($asset->{id_data})})->{md5};
                if ( $asset->{name} eq $filename ) {
                    # asset is already up
                    if( !$highest_version->{versionid} ||  $asset->{versionid} > $highest_version->{versionid} ) {
                        $highest_version = $asset;
                    }
                }   
            }
            
            if( $highest_version ) {
                _fail( _loc('File is already the latest version') ) if $highest_version->{md5} eq $md5;
                $versionid = $highest_version->{versionid} + 1; 
            }

            my $new_asset = ci->asset->new(
                name=>$filename,
                versionid=>$versionid,
                extension=>$extension,
                created_by => $username,
                created_on => mdb->ts,
            );
            $new_asset->save;
            $new_asset->put_data( $f->openr );
            $file_mid = $new_asset->{mid};
            
            if ($p->{topic_mid}){
                my $subject = _loc("Created file %1 to topic [%2] %3", $filename, $topic->{mid}, $topic->{title});                            
                event_new 'event.file.create' => {
                    username        => $username,
                    mid             => $topic_mid,
                    id_file         => $new_asset->mid,
                    filename        => $filename,
                    notify_default  => \@users,
                    subject         => $subject
                };
                
                # tie file to topic
                my $doc = { from_mid=>$topic_mid, to_mid=>$new_asset->mid, rel_type=>'topic_asset', rel_field=>$$p{filter} };
                mdb->master_rel->update($doc,$doc,{ upsert=>1 });
            }
            cache->remove({ mid=>"$topic_mid" }); # qr/:$topic_mid:/ );
            $msg = _loc( 'Uploaded file %1', $filename ) . '", "file_uploaded_mid":"' . $file_mid;
            $success = "true";
            $status = 200;
        } else {
            if(!length $p->{topic_mid}){
                $msg = "You must save the topic before add new files";
                $success = "false";
                $status = 404;
            } else {
                $msg = "The Topic with mid: " . $p->{topic_mid} . " does not exist";
                $success = "false";
                $status = 500;
            }
        }
        return (success=>$success, msg=>$msg, status=>$status);
    } catch {
        my $err = shift;
        my $msg = _loc('Error uploading file: %1', $err );
        _error( $msg );
        my $status = 500;
        return (success=>$success, msg=>$msg, status=>$status);
    };
}


sub get_downloadable_files {
    my ($self, $p) = @_;

    my $categories = $p->{files_categories} // 'ALL';
    my @cats = $categories eq 'ALL' ? 
        map { $_->{name} } model->Topic->get_categories_permissions( username => $p->{username}, type => 'view' ) :
        split /,/, $categories;

    my $field = $p->{field} || _throw _loc('Missing field');

    my $topic = ci->new($p->{mid}) || _throw _loc('Missing mid') ;
    my $topic_meta = $topic->get_meta;
    my ($fields) = $field eq 'ALL'? ('ALL') : map { $_->{files_fields} } grep { $_->{id_field} eq $field } _array($topic_meta);
    my %filter_docs = map { $_ => 1 } split /,/, $fields;

    my $where;
    $where->{username} = $p->{username} || _throw _loc('Missing username');
    $where->{query_id} = $p->{mid};

    my ($cnt, @user_topics) = Baseliner->model('Topic')->topics_for_user( $where );

    my $filter = { 
        # mid => mdb->in(map {$_->{mid}} @user_topics), 
        collection => 'topic',
        name_category => mdb->in(@cats)
    };

    my @topics = $topic->children( where => $filter, depth => -1 );
    my $available_docs;

    for my $related ( @topics ) {
        my $rel_data = ci->new($related->{mid})->get_meta;
        my @cat_fields;
        push @cat_fields, 
            map {  { id_field => $_->{id_field}, name_field => $_->{name_field}, name_category => $related->{name_category} } } 
            grep { $_->{type} && $_->{type} eq 'upload_files' } _array($rel_data);
        for my $cat_field (@cat_fields){
            my $read_action = 'action.topicsfield.'._name_to_id($cat_field->{name_category}).'.'.$cat_field->{id_field}.'.read';
            my $write_action = 'action.topicsfield.'._name_to_id($cat_field->{name_category}).'.'.$cat_field->{id_field}.'.write';
            if ( !model->Permissions->user_has_read_action( username=> $p->{username}, action => $read_action) ) {
                if ($fields eq 'ALL'){
                    $available_docs->{$cat_field->{id_field}} = $cat_field->{name_field};
                } else {
                    $available_docs->{$cat_field->{id_field}} = $cat_field->{name_field} if ($filter_docs{$cat_field->{name_field}});
                }
            }
        }
    }
    return $available_docs;
}

sub getCategoryAcronyms {
    my ($self, $p) = @_;
    my $acronyms = cache->get('category:acronyms');

    if ( !$acronyms ) {
        my %acr = map {
            my $acronym = $_->{acronym} // '';
            if ( !$acronym ) {
                $acronym = $_->{name};
                $acronym =~ s/[^A-Z]//g;
            }
            $_->{name}, $acronym 
        }

        mdb->category->find( {}, { _id => -1, name => 1, acronym => 1 } )->all;
        cache->set('category:acronyms',\%acr);
        $acronyms = \%acr;
    }
    return _encode_json($acronyms);
}
1;
