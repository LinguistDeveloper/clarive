package Baseliner::Model::Users;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub get {
    my ($self, $username ) = @_;

    {
        # try locally
        my $rs = Baseliner->model('Baseliner::BaliUser')->search({ username=>$username });
        rs_hashref( $rs );
        my $user = $rs->first;
        $user->{data} = _load( $user->{data} ) if defined $user->{data};
        return $user if defined $user;
    }
    {
        # FIXME this is old
    my $rs = Baseliner->model('Harvest::Harallusers')->search({ username=>$username });
    rs_hashref( $rs );
    my $u = $rs->first;
    return {} unless ref $u;
    return $u;
}
}

# get user data from the database
sub populate_from_ldap {
    my ($self, $who ) = @_;
    
    my $where = defined $who ? { username=>$who } : {};
    my $rs = Baseliner->model('Baseliner::BaliUser')->search($where);
    while( my $r = $rs->next ) {
        my $username = $r->username;
        next unless $username;
        my $u = $self->get( $username );
        next unless defined $u->{realname};
        $u->{realname} =~ tr/0-9a-zA-Z //dcs; # sanitize
        $r->realname( $u->{realname} );
        $r->update;
    }
}

sub get_users_friends_by_username{
    my ($self, $username ) = @_;
    my $root = Baseliner->model('Permissions')->is_root( $username );
    my $where = {};
    my @users_friends = [];
    
    if (!$root){
        my @projects = Baseliner->model('Permissions')->user_projects( username => $username );	
        $where = { ns => \@projects };
    }
    
    my $rs_users = Baseliner->model('Baseliner::BaliRoleuser')->search(
                                                                $where,
                                                                { select => {distinct => 'username'}, as => ['username'] } #, order_by => 'username asc' }
                                                        );
    
    while( my $user = $rs_users->next ) {
        push @users_friends, $user->username;
    }
    
    return wantarray ? @users_friends : \@users_friends;
}

sub get_users_friends_by_projects{
    my ($self, $projects ) = @_;
    $projects or _throw 'Missing parameter projects';

    my @ns_projects = map { 'project/' . $_ } _array $projects;	
    my $where = { ns => \@ns_projects, ns => '/' };
    my @users_friends = map { $_->{username} } Baseliner->model('Baseliner::BaliRoleuser')->search(
                                                                $where,
                                                                { select => {distinct => 'username'}, as => ['username'] } 
                                                        )->hashref->all;
        
    return wantarray ? @users_friends : \@users_friends;
}

sub get_roles_from_projects{
    my ($self, $projects ) = @_;
    $projects or _throw 'Missing parameter projects';

    my @ns_projects = map { 'project/' . $_ } _array $projects;	
    my $where = { ns => \@ns_projects, ns => '/' };
    my @roles = map { $_->{id_role} } Baseliner->model('Baseliner::BaliRoleuser')->search(
                                                                $where,
                                                                { select => {distinct => 'id_role'}, as => ['id_role'] } 
                                                        )->hashref->all;
        
    return wantarray ? @roles : \@roles;
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
    my @users = map { $_->{username} } DB->BaliUser->search( {active => 1}, {select => 'username'} )->hashref->all;
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
    
    for my $key ( keys %categories ){
        my %fields_perm;
        my $parse_category =  _name_to_id($categories{$key});
        my @fieldlets = _array (Baseliner->model('Topic')->get_meta(undef, $key, $username));
        ##Se podría tener en cuenta para el metadato los permisos de escritura y lectura.
        for my $field ( @fieldlets){
            my $view_action = 'action.topicsfield.' .  $parse_category . '.' .  $field->{id_field} . '.read';  

            if (!Baseliner->model('Permissions')->user_has_read_action( username=> $username, action => $view_action )){
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
                ci->new( $mid )->children( where => {collection => 'topic'}, depth => 1 );
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

    $mega_where->{'$or'} = \@mega_ors;
    my @users = map {$_->{name}} _array(ci->user->find($mega_where)->all);
    return wantarray ? @users : \@users; 
}

1;
