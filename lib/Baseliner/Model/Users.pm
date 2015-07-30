package Baseliner::Model::Users;
use Moose;
use Baseliner::Core::Registry ':dsl';
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use experimental 'smartmatch', 'autoderef';

sub get {
    my ($self, $username ) = @_;
    my $user = ci->user->find({ username=>$username })->next;
    $user->{data} = _load( $user->{data} ) if defined $user->{data};
    return $user if defined $user;
}

sub user_exists {
    my ($self,$username) = @_;
    return !! ci->user->find({ username=>$username })->count;
}

# get user data from the database
sub populate_from_ldap {
    my ($self, $who ) = @_;
    
    my $where = defined $who ? { username=>$who } : {};
    my $rs = ci->user->find($where);
    while( my $r = $rs->next ) {
        my $username = $r->{username};
        next unless $username;
        my $u = $self->get( $username );
        next unless defined $u->{realname};
        $u->{realname} =~ tr/0-9a-zA-Z //dcs; # sanitize
        $r->update({realname => $u->{realname} });
    }
}

sub get_users_friends_by_username{
    my ($self, $username ) = @_;
    
    my @res;
    my @user_projects = $self->get_projects_from_user($username);
    foreach my $project (@user_projects){
        push @res, $self->get_users_from_project($project);
    }
    @res= _unique @res;	
   
    return wantarray ? @res : \@res;
}

sub get_users_friends_by_projects{
    my ($self, $projects ) = @_;
    $projects or _throw 'Missing parameter projects';

    my @users;
    foreach my $project (_array $projects){
        push @users, $self->get_users_from_project($project);
    } 
    return wantarray ? @users : \@users;
}


sub get_roles_from_projects{
    my ($self, $projects ) = @_;
    $projects or _throw 'Missing parameter projects';

    my @users = ci->user->find->all;
    my @colls = map { Util->to_base_class($_) } packages_that_do( 'Baseliner::Role::CI::Project' );
    my @resp;

    foreach my $user (@users){
        foreach my $role (keys $user->{project_security}){
            foreach my $coll (@colls){
                my $ps = $user->{project_security};
                my %pjs = map { $_=>1 } @{$ps->{$role}->{$coll}} if $ps->{$role}->{$coll};
                push @resp, $role if @pjs{ @$projects }; # returns the number of matching keys in the hash
            }
        }
    }
    @resp = _unique @resp;        
    return wantarray ? @resp : \@resp;
}

sub get_users_from_actions {
    my ( $self, %p ) = @_;
    my @actions = _array $p{actions} or _throw 'Missing parameter actions';
    
    my @projects = _array $p{projects};

    my @users = Baseliner->model('Permissions')->users_with_actions( actions => \@actions, projects => \@projects, include_root => 0);

    return wantarray ? @users : \@users; 
}

sub get_users_from_mid_roles {
    my ( $self, %p ) = @_;
    my @roles = _array $p{roles} or _throw 'Missing parameter roles';
    my @projects = _array $p{projects};

    my @users = Baseliner->model('Permissions')->users_with_roles( roles => \@roles, projects => \@projects, include_root => 0);

    return wantarray ? @users : \@users; 
}

sub get_users_username {
    my @users = map { $_->{username} } ci->user->find({active => mdb->true})->fields({username => 1, _id => 0});
    return wantarray ? @users : \@users; 
}

sub get_categories_fields_meta_by_user {
    #Pendiente parametrizar por categorías
    my ( $self, %p) = @_;
    my $username = $p{username} or _throw 'Missing parameter username';
    my %categories_fields;
    my %categories;
    
    %categories = %{$p{categories}} if $p{categories};

    if(!%categories){
        map { $categories{$_->{id}} = $_->{name} } Baseliner->model('Topic')->get_categories_permissions( username => $username, type => 'view' );        
    }
    
    my $is_root = model->Permissions->is_root( $username );
    my $user_security = ci->user->find_one( {name => $username}, { project_security => 1, _id => 0} )->{project_security};
    my $user_actions = model->Permissions->user_actions_by_topic( username=> $username, user_security => $user_security );
    my @user_read_actions_for_topic = $user_actions->{negative};

    for my $key ( keys %categories ){
        my %fields_perm;
        my $parse_category =  _name_to_id($categories{$key});
        my @fieldlets = _array (Baseliner->model('Topic')->get_meta(undef, $key, $username));
        ##Se podría tener en cuenta para el metadato los permisos de escritura y lectura.
        for my $field ( @fieldlets){
            my $view_action = 'action.topicsfield.' .  $parse_category . '.' .  $field->{id_field} . '.read';  

            if (!($view_action ~~ @user_read_actions_for_topic)){
            #if (!Baseliner->model('Permissions')->user_has_read_action( username=> $username, action => $view_action )){
                $fields_perm{$field->{id_field}} = $field;
            };
        }
        
        $categories_fields{$parse_category} = \%fields_perm;
    }
    return \%categories_fields;
}

sub get_users_from_mid_roles_topic {
    my ( $self, %p ) = @_;
    my @roles = _array $p{roles} or _throw 'Missing parameter roles';
    my $mid   = $p{mid};

    my @topic_securities;

    if ( !$mid ) {
        push @topic_securities, {};
    } else {

        my $topic = mdb->topic->find_one( {mid => "$mid"} );


        push @topic_securities, $topic->{_project_security} if $topic->{_project_security};

        if ( $topic->{category}->{is_release} && !@topic_securities ) {
            my @children =
                map { $_->{mid} }
                ci->new( $mid )->children( where => {collection => 'topic'}, depth => 1, mids_only => 1 );
            @topic_securities =
                map { $_->{_project_security} }
                mdb->topic->find( {mid => mdb->in( @children )} )->all;
            if ( !@topic_securities ) {
                push @topic_securities, {};
            }
        } ## end if ( $topic->{category...})
    } ## end else [ if ( !$mid ) ]

    my $mega_where = {};
    my @mega_ors;

    for my $topic_security ( @topic_securities ) {
        my @ors;
        my $total_where = {};
        
        for my $role (@roles) {
            my $where = {};
            $where->{"project_security.$role"} = { '$nin' => [undef] };
            while ( my ( $k, $v ) = each %{ $topic_security || {} } ) {
                $where->{"project_security.$role.$k"} = { '$in' => [ undef, @$v ] };
            } ## end while ( my ( $k, $v ) = each...)
            push @ors, $where;
        }
        $total_where->{'$or'} = \@ors;
        push @mega_ors, $total_where;
    }

    my @users;
    if ( @mega_ors ) {
        $mega_where->{'$or'} = \@mega_ors;
        @users = map {$_->{name}} _array(ci->user->find($mega_where)->all);
    } else {
        @users = Baseliner->model('Permissions')->users_with_roles( roles => \@roles, include_root => 0);        
    }
    return wantarray ? @users : \@users; 
}

sub get_actions_from_user{
    my ($self, $username, @bl) = @_;
    my @final;
    if($username eq 'root' || $username eq 'local/root'){
        @final = Baseliner->model( 'Actions' )->list;   
    }else{
        my $user = ci->user->find_one({ name=>$username });
        _fail _loc 'User %1 not found', $username unless $user;
        my @roles = keys $user->{project_security};
        #my @id_roles = map { $_ } @roles;
        my @actions = mdb->role->find({ id=>{ '$in'=>\@roles } })->fields( {actions=>1, _id=>0} )->all;
        @actions = grep {%{$_}} @actions; ######### DELETE RESULTS OF ACTIONS OF ROLES WITHOUT ACTIONS
        foreach my $f (map { values $_->{actions} } @actions){
            if(@bl){
                if(scalar(@bl) eq 1 && '*' ~~ @bl){
                    push @final, $f->{action};
                } elsif ($f->{bl} ~~ @bl) {
                    push @final, $f->{action};
                }
            }else{
                push @final, $f->{action};
            }
        }
    }
    return _unique @final;
}

sub get_users_from_project{
    my ($self, $project_id) = @_;
    my @all_users = ci->user->find->all;
    my @ret;
    my @colls = map { Util->to_base_class($_) } packages_that_do( 'Baseliner::Role::CI::Project' );
    foreach my $user (@all_users){
        my $ps = $user->{project_security};
        my @user_projects;
        foreach my $col (@colls){
            foreach my $role ( keys $ps){
                @user_projects = (@user_projects, _array $user->{project_security}->{$role}->{$col});
            }
        }
        if($project_id ~~ @user_projects){
            push @ret, $user->{name};
        }
    }
    return _unique @ret;
}

sub get_projects_from_user{
    my ($self, $username) = @_;
    my @id_projects;
    my %project_security = %{ci->user->find({username=>$username})->next->{project_security}};
    my @id_roles = keys %project_security;
    foreach my $id_role (@id_roles){
        my @project_types = keys $project_security{$id_role};
        map { push @id_projects, @{$project_security{$id_role}->{$_}} } @project_types;
    }
    _unique @id_projects;
}


sub get_projectnames_and_descriptions_from_user{
    my ($self, $username, $collection, $query, $roles) = @_;
    $collection ||='project';
    my $is_root = Baseliner->model('Permissions')->is_root( $username );
    my $where;
    my @roles_filter_names = Util->_array_or_commas($roles);
    if ($is_root){
        $where = {collection=>"$collection"};
    }else{
        my @roles_filter_ids;
        if ( @roles_filter_names ) {
            push @roles_filter_ids, map { $_->{id} } mdb->role->find({ role => mdb->in(@roles_filter_names)})->all;
        }
        my @id_projects;
        my @res;
        my %project_security = %{ci->user->find_one({username=>$username})->{project_security}};
        my @id_roles = keys %project_security;
        foreach my $id_role (@id_roles){
            next if ( @roles_filter_ids && !($id_role ~~ @roles_filter_ids ));
            #my @project_types = keys $project_security{$id_role};
            push @id_projects, @{$project_security{$id_role}->{$collection}} if $project_security{$id_role}->{$collection};
        }
        $where = {collection=>"$collection", mid=>mdb->in(@id_projects)};
    }

    if ( !is_number($query) ) { # Exclude mids
        $where->{name} = qr/$query/i if length($query);
    }
    $where->{active} = '1';
    mdb->master_doc->find($where)->fields({name=>1,description=>1, mid=>1, _id=>0})->sort({ name=>1 })->all;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
