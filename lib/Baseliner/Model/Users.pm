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

1;
