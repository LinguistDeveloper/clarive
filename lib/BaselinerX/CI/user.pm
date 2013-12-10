package BaselinerX::CI::user;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Internal';

has api_key          => qw(is rw isa Any);
has email            => qw(is rw isa Any);
has avatar           => qw(is rw isa Any);
has phone            => qw(is rw isa Any);
has username         => qw(is rw isa Any);
has password         => qw(is rw isa Any);
has realname         => qw(is rw isa Any);
has alias            => qw(is rw isa Any);
has project_security => qw(is rw isa Any), default => sub { +{} };

has favorites  => qw(is rw isa HashRef), default => sub { +{} };
has workspaces => qw(is rw isa HashRef), default => sub { +{} };
has prefs      => qw(is rw isa HashRef), default => sub { +{} };

sub icon { '/static/images/icons/user.gif' }

sub has_description { 0 }

around load_post_data => sub {
    my ($orig, $class, $mid, $data ) = @_;
    #my $data = $self->$orig() // {};
    my $row = DB->BaliUser->find( $mid );
    my $row_data = $row ? +{ $row->get_columns } : {};
    $data = { %$data, %$row_data };
    return $data;
};

around save_data => sub {
    my ($orig, $self, $master_row, $data, $opts ) = @_;

    my $mid = $master_row->mid;
    
    # TODO encrypt here too? if $self->password . " == " . $data->{password};    
    if( $opts->{save_type} eq 'new' ) {
        $data->{password} = $self->encrypt_password( $data->{name}, $data->{password} );
    }
    elsif( exists $opts->{changed}{password} ) {  # its an update, and the password has changed
        $data->{password} = $self->encrypt_password( $data->{name}, $data->{password} );
        $self->password( $data->{password} );
    }
    Util->_debug( $data->{name} );
    Util->_debug( $data->{password} );
            
    my $ret = $self->$orig($master_row, $data, $opts);

    my $row = DB->BaliUser->update_or_create({
        mid         => $mid,
        active      => $master_row->active // 1, 
        avatar      => $data->{avatar}, 
        data        => undef,
        api_key     => $data->{api_key}, 
        phone       => $data->{phone}, 
        username    => $data->{username} // $master_row->name, 
        email       => $data->{email}, 
        password    => length $data->{password} ? $data->{password} : Util->_md5(rand(9999999).time()), 
        realname    => $data->{realname}, 
        alias       => $data->{alias}, 
    });
    
    return $ret;
};

around delete => sub {
    my ($orig, $self, $mid ) = @_;
    my $row = DB->BaliUser->find( $mid // $self->mid );  
    my $cnt = $row->delete if $row; 
    Baseliner->cache_remove( qr/^ci:/ );
    #$self->$orig( $mid );  # BaliUser deletes its master automatically
    # bali project deletes CI from master, no orig call then 
    return $cnt;
};
    
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
    my $user = ci->find( name=>$p->{username} ); 
    $user->workspaces->{$id} = $p; 
    $user->save;
    { id_workspace => $p->{id_workspace} }
}

sub prefs_load {
    my ($self,$p)=@_;
    $self = ci->find( name=>$p->{username} ) unless ref $self;
    my $prefs = $self->prefs;
    $prefs;
}

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
    $self = ref $self ? $self : Baseliner->user_ci( $p->{username} );
    my $new_key = $p->{api_key} // Util->_md5( $p->{username} . ( int ( rand( 32 * 32 ) % time ) ) );
    $self->update( api_key=>$new_key );
    { api_key=>$new_key, msg=>'ok', success=>\1 };
}

sub username { $_[0]->name }

method gen_project_security {
    if( ref $self ) {
        my $sec = Baseliner->model('Permissions')->user_projects_ids_with_collection( username=>$self->name, with_role=>1 );
        $self->project_security( $sec );
    } else {
        for my $user ( ci->user->search_cis ) {
            $user->gen_project_security;
            $user->save;
        }
        
    }
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
