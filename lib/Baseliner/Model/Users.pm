package Baseliner::Model::Users;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Crypt::Blowfish::Mod;

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

sub encriptar_password{
    my ($self, $string, $key) = @_;
    my $b = Crypt::Blowfish::Mod->new( $key );
    return Digest::MD5::md5_hex($b->encrypt($string));    
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
    my @users_friends = [];
    
    if($projects){
        my @ns_projects = map { 'project/' . $_ } _array $projects;	
        my $where = { ns => \@ns_projects };
        my $rs_users = Baseliner->model('Baseliner::BaliRoleuser')->search(
                                                                    $where,
                                                                    { select => {distinct => 'username'}, as => ['username'] } #, order_by => 'username asc' }
                                                            );
        
        while( my $user = $rs_users->next ) {
            push @users_friends, $user->username;
        }
    }
    
    return wantarray ? @users_friends : \@users_friends;
}

1;
