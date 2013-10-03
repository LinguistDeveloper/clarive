package BaselinerX::CI::user;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Internal';

has favorites     => qw(is rw isa HashRef), default=>sub{ +{} };
has workspaces    => qw(is rw isa HashRef), default=>sub{ +{} };
has prefs         => qw(is rw isa HashRef), default=>sub{ +{} };

sub icon { '/static/images/icons/user.gif' }

sub has_description { 0 }

around load => sub {
    my ($orig, $self ) = @_;
    my $data = $self->$orig() // {};
    $data = { %$data, %{ +{ DB->BaliUser->find( $self->mid )->get_columns } || {} } };
    # $data = { %$data, %{ Baseliner->model('Topic')->get_data( undef, $self->mid, with_meta=>1 ) || {} } };
    #$data->{category} = { DB->BaliTopic->find( $self->mid )->categories->get_columns };
    return $data;
};

around save_data => sub {
    my ($orig, $self, $master_row, $data  ) = @_;

    my $mid = $master_row->mid;
	my $ret = $self->$orig($master_row, $data);
    
    my $row = DB->BaliUser->update_or_create({
        mid         => $mid,
        active      => $master_row->active // 1, 
        avatar      => $data->{avatar}, 
        data        => undef,
        api_key     => $data->{api_key}, 
        phone       => $data->{phone}, 
        username    => $data->{username} // $master_row->name, 
        email       => $data->{email}, 
        password    => length $data->{password} ? $data->{password} : Util->_md5(), 
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
