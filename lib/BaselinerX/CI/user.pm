package BaselinerX::CI::user;
use Baseliner::Moose;
use Baseliner::Utils;
use experimental 'autoderef';
with 'Baseliner::Role::CI::Internal';

has api_key             => qw(is rw isa Any);
has email               => qw(is rw isa Any);
has avatar              => qw(is rw isa Any);
has phone               => qw(is rw isa Any);
has username            => qw(is rw isa Any);
has password            => qw(is rw isa Any);
has realname            => qw(is rw isa Any);
has alias               => qw(is rw isa Any);
has project_security    => qw(is rw isa Any), default => sub { +{} };
has dashboard           => qw(is rw isa Any);
has language_pref       => qw(is rw isa Any), default=>Baseliner->config->{default_lang};

has favorites  => qw(is rw isa HashRef), default => sub { +{} };
has workspaces => qw(is rw isa HashRef), default => sub { +{} };
has prefs      => qw(is rw isa HashRef), default => sub { +{} };
has dashlet_config => qw(is rw isa HashRef), default => sub { +{} };

has languages => ( is=>'rw', isa=>'ArrayRef', lazy=>1, 
    default=>sub{ [ Util->_array(Baseliner->config->{default_lang} // 'en') ] });

sub icon { '/static/images/icons/user.gif' }

sub has_description { 0 }

sub workspace_create {
    my ($self,$p) = @_;
    # create the favorite id 
    my $id = time . '-' .  int rand(9999);
    # delete empty ones
    $p->{$_} eq 'null' and delete $p->{$_} for qw/data menu/;
    # decode data structures
    $p->{id_workspace} = $id;
    if( $p->{password} ) {
        my $key = Baseliner->config->{decrypt_key} // Baseliner->config->{dec_key};
        die "Error: missing 'decrypt_key' config parameter" unless length $key;
        my $b = Crypt::Blowfish::Mod->new( $key );
        $p->{password} = $b->encrypt( $p->{password} // '' ); 
    }
    my $user = ci->user->find_one( { name=>$p->{username} }); 
    $user->workspaces->{$id} = $p; 
    $user->save;
    { id_workspace => $p->{id_workspace} }
}

sub prefs_load {
    my ($self,$p)=@_;
    $self = ci->user->search_ci( { name=>$p->{username} }) unless ref $self;
    my $prefs = $self->prefs;
    $prefs;
}

sub default_dashboard {
    my ($self,$p)=@_;
    $self = ci->user->search_ci( name=>$p->{username} ) unless ref $self;
    my $default_dashboard = $self->dashboard || '';
    { dashboard => $default_dashboard, msg => 'ok'};
}

sub general_prefs_save {
    my ($self,$p)=@_;
    my $data = $p->{data} // _fail(_loc('Missing data') );
    # check if user can edit prefs for somebody else
    if( $p->{for_username} && !model->Permissions->user_has_action(username=>$p->{username}, action=>'action.admin.users') ){
        _fail _loc 'User does not have permission to edit users';
    }
    my $username = $p->{for_username} || $p->{username};  # is it for me or somebody else?
    $self = ci->user->search_ci( name=>$username ) unless ref $self;
    $self->language_pref($data->{language_pref});
    $self->dashboard($data->{dashboard});
    $self->save;
    { msg => 'ok'};
}

# TODO there's no interface for this (yet?):
sub prefs_save {
    my ($self,$p)=@_;
    $self = ci->find( name=>$p->{username} ) unless ref $self;
    my $prefs = +{ %{ $self->prefs }, %{ $p->{prefs} } };
    $self->prefs( $prefs );
    $self->save;
    $prefs;
}

sub encrypt_password {
    my ($self, $username, $password) = @_;
    if( my $password_rule = Baseliner->config->{password_rule} ) {
        Util->_fail( Util->_loc('Password does not comply. Rule: %1', Baseliner->config->{password_rule_description} // $password_rule ) )
            unless $password =~ qr/$password_rule/;
    }
    if( my $password_len = Baseliner->config->{password_min_length} ) {
        Util->_fail( Util->_loc('Password length is less than %1 characters. Rule: %1', $password_len ) )
           if $password_len > 0 && length($password)<$password_len;
    }
    my $user_key = ( Baseliner->config->{decrypt_key} // Baseliner->config->{dec_key} ) .reverse ( $username );
    require Crypt::Blowfish::Mod;
    my $b = Crypt::Blowfish::Mod->new( $user_key );
    return Digest::MD5::md5_hex( $b->encrypt($password) );    
}

sub save_api_key  {
    my ($self, $p) = @_;
    # check if user can edit prefs for somebody else
    if( $p->{for_username} && !model->Permissions->user_has_action(username=>$p->{username}, action=>'action.admin.users') ){
        _fail _loc 'User does not have permission to edit users';
    }
    my $username = $p->{for_username} || $p->{username};  # is it for me or somebody else?
    $self = ref $self ? $self : Baseliner->user_ci( $username );
    my $new_key = $p->{api_key_param} // Util->_md5( $p->{username} . ( int ( rand( 32 * 32 ) % time ) ) );
    $self->update( api_key=>$new_key );
    { api_key=>$new_key, msg=>'ok', success=>\1 };
}

#sub username { $_[0]->name }


method gen_project_security {
    my ($projects, $roles) = @_;
    if( ref $self ) {
        my @colls = map { Baseliner::Utils::to_base_class($_) } Baseliner::Utils::packages_that_do( 'Baseliner::Role::CI::Project' );
        my $security = {};
        for my $role (Baseliner::Utils::_array($roles)){
            my @projs;
            for (Baseliner::Utils::_array($projects)){
                if ($_ eq 'todos'){
                    my @pjs;
                    foreach my $col (@colls){
                        my @tmp = map {$_->{mid}} ci->$col->search_cis;
                        push @{$security->{$role}->{$col}}, @tmp;
                    }
                    last;    
                }
                my $ci = ci->new($_);
                my $col = Baseliner::Utils::to_base_class(ref $ci);
                push @{$security->{$role}->{$col}}, $_;
            }
        }
        my $old_project_security = $self->{project_security};
        my %new_project_security;
        foreach my $r (Baseliner::Utils::_array $roles){
            foreach my $c (keys $security->{$r}){
                foreach my $p (values $security->{$r}->{$c}){
                    push @{$old_project_security->{$r}->{$c}}, $p;
                }
                @{$old_project_security->{$r}->{$c}} =  Baseliner::Utils::_unique @{$old_project_security->{$r}->{$c}};
            }
        }
        $self->project_security( $old_project_security );
    }
}

method is_root( $username=undef ) {
    Baseliner->model('Permissions')->is_root( $username || $self->username );
}

method has_action( $action ) {
    return Baseliner->model('Permissions')->user_has_action( action=>$action, username=>$self->username );
}

method roles( $username=undef ) {
    return grep { defined } map { $$_{id} } 
        Baseliner->model('Permissions')->user_roles( ref $self ? $self->username : $username );
}

method save_dashlet_config ( :$username=undef, :$data, :$id_dashlet) {

    my $user = ci->user->search_ci( name => $username );

    if ( $user ) {    
        $user->dashlet_config->{$id_dashlet} = $data; 
        $user->save;
    }
    { ok => \1, data => $data, msg => _loc('Dashlet config saved') }
}

method remove_dashlet_config ( :$username=undef, :$id_dashlet) {

    my $user = ci->user->search_ci( name => $username );

    if ( $user ) {    
        delete $user->dashlet_config->{$id_dashlet}; 
        $user->save;
    }
    { ok => \1, msg => _loc('Dashlet config saved') }
}

1;

__END__

            username: '<% $c->username %>',
            language: '<% [ _array( $c->languages ) ]->[0] %>',
            logo_file: '<% $c->config->{logo_file} %>',
            logo_filename: '<% $c->config->{logo_filename} || "logo.jpg" %>',
            site: <% _to_json({ map { $_ => $to_bool->( $c->config->{site}->{$_} ) } keys %{ $c->config->{site} || {} } }) %>,
            toolbar_height: <% $c->config->{toolbar_height} // 28 %>,
            menus: [ <% join ',', _array $c->stash->{menus} %> ],
            stash: <% _to_json({
                        map { $_ => $to_bool->( $c->stash->{$_} ) }
                        qw/site_raw can_menu can_change_password can_lifecycle can_surrogate portlets tab_list alert theme_dir/
                    })
                %>

                my $security = {};
                for my $role ( keys %{$sec} ) {
                    for my $coll ( keys %{$security->{$role}} ) {
                        my @projs;
                        for my $proj ( keys %{$security->{$role}->{$coll} } ) {
                            push @projs, $proj;
                        }
                        $security->{$role}->{$coll} = \@projs;
                    }
                }
