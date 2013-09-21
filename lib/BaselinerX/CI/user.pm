package BaselinerX::CI::user;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Internal';

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
    
1;
