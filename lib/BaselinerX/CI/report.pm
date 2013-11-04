package BaselinerX::CI::report;
use Baseliner::Moose;
use Baseliner::Utils qw(_array _loc _fail hash_flatten);
use v5.10;
use Try::Tiny;
with 'Baseliner::Role::CI::Internal';

has selected    => qw(is rw isa ArrayRef), default => sub{ [] };
has rows        => qw(is rw isa Num default 100);
has sql         => qw(is rw isa Any);
has mode        => qw(is rw isa Maybe[Str] default lock);
has_ci 'user';

sub icon { '/static/images/icons/report.png' }

sub rel_type {
    {
    user  => [from_mid => 'report_user'],
    }
}


sub report_list {
    my ($self,$p) = @_;
    
    my @folders = $self->search_cis; 
    my @tree;
    
    for my $folder ( @folders ){
        push @tree,
            {
                mid     => $folder->mid,
                text    => $folder->name,
                icon    => '/static/images/icons/report.png',
                menu    => [
                    {
                        text   => _loc('Edit') . '...',
                        icon   => '/static/images/icons/report.png',                        
                        eval   => { handler => 'Baseliner.open_new_search_folder' }
                    },
                    {
                        text   => _loc('Delete search folder') . '...',
                        icon   => '/static/images/icons/folder_delete.gif',
                        eval   => { handler => 'Baseliner.delete_search_folder' }
                    }                    
                ],
                data    => {
                    click   => {
                        icon    => '/static/images/icons/topic.png',
                        url     => '/comp/topic/topic_grid.js',
                        type    => 'comp',
                        title   => $folder->name,
                    },
                    #selecs         => $folder->fields,
                    #store_fields   => $folder->fields,
                    #columns        => $folder->fields,
                    fields         => $folder->selected_fields,
                    id_report      => $folder->mid,
                    #column_mode    => 'full', #$folder->mode,
                    hide_tree      => \1,
                },
                leaf    => \1,
            };
    }    
    
    return \@tree; 
}

sub report_update {
    my ($self, $p) = @_;
    my $action = $p->{action};
    my $username = $p->{username};
    my $mid = $p->{mid};
    my $data = $p->{data};
    
    my $user = ci->find( name=> $username, collection=>'user' );
    if(!$user){
        _fail _loc('Error user does not exist. ');
    }
    
    my $ret;
    
    given ($action) {
        when ('add') {
            try{
                $self = $self->new() unless ref $self;
                my @cis = $self->search_cis( name=>$data->{name} );
                if(!@cis){
                    $self->selected( $data->{selected} ) if ref $data->{selected};
                    $self->name( $data->{name} );
                    $self->user( $user );
                    $self->rows( $data->{rows} );
                    $self->sql( $data->{sql} );
                    $self->save;
                    $ret = { msg=>_loc('Search folder added'), success=>\1, mid=>$self->mid };
                } else {
                    _fail _loc('Folder name already exists, introduce another folder name');
                }
            }
            catch{
                _fail _loc('Error adding folder: %1', shift());
            };
        }
        when ('update') {
            try{
                my @cis = $self->search_cis( name=>$data->{name} );
                if( @cis && $cis[0]->mid != $self->mid ) {
                    _fail _loc('Folder name already exists, introduce another folder name');
                }
                else {
                    $self->name( $data->{name} );
                    $self->rows( $data->{rows} );
                    $self->sql( $data->{sql} );
                    $self->selected( $data->{selected} ) if ref $data->{selected}; # if the selector tab has not been show, this is submitted undef
                    $self->save;
                    $ret = { msg=>_loc('Search folder modified'), success=>\1, mid=>$self->mid };
                }
            }
            catch{
                _fail _loc('Error modifing folder: %1', shift());
            };
        }
        when ('delete') {
            try {
                $self->delete;
                $ret = { msg=>_loc('Search folder deleted'), success=>\1 };
            } catch {
                _fail _loc('Error deleting folder: %1', shift());
            };
        }
    }
    $ret;
}

sub dynamic_fields {
    my ($self,$p) = @_;
    my @tree;
    push @tree, mdb->topic->all_keys;
    return \@tree;
}

sub all_fields {
    my ($self,$p) = @_;
    
    my @cats = DB->BaliTopicCategories->search(undef,{ order_by=>{ -asc=>'name' } })->hashref->all;
    my @tree = (
        { text=>_loc('Values'),
            leaf=>\0,
            expanded => \1,
            icon => '/static/images/icons/search.png',
            children=>[
                map { $_->{icon}='/static/images/icons/where.png'; $_->{type}='value'; $_->{leaf}=\1; $_ } 
                (
                    { text=>_loc('Is String'), where=>'string', },
                    { text=>_loc('Like'), where=>'like' },
                    { text=>_loc('Is Number'), where=>'number' },
                    { text=>_loc('Number'), where=>'number' },
                    { text=>_loc('Number From'), where=>'number_from' },
                    { text=>_loc('Number To'), where=>'number_to' },
                    { text=>_loc('Date From'), where=>'date_from' },
                    { text=>_loc('Date To'), where=>'date_to' },
                    { text=>_loc('CIs'), where=>'cis' },
                )
            ]
        }
    );
    push @tree, {
        text => _loc('Dynamic'),
        leaf => \0,
        icon     => '/static/images/icons/all.png',
        #url  => '/ci/report/dynamic_fields',
        children => [
            map {
                {
                    text     => $_,
                    icon     => '/static/images/icons/field-add.png',
                    id_field => $_,
                    type     => 'select_field',
                    leaf     => \1
                }
            } mdb->topic->all_keys
        ],
    };
    push @tree, map { 
        my $cat = $_;
        my @chi = map { +{ 
                %$_,
                text => _loc($_->{name_field}), 
                icon => '/static/images/icons/field-add.png',
                type => 'select_field',
                category => $cat,
                leaf=>\1, 
             } } 
            _array( Baseliner->model('Topic')->get_meta( undef, $cat->{id} ) ); 
        +{  text => _loc($cat->{name}),
            data => $cat, 
            icon => '/static/images/icons/topic.png',
            expanded => \0,
            draggable => \0,
            children =>\@chi, 
        }
    } @cats;

    return \@tree;
}

sub field_tree {
    my ($self,$p) = @_;
    return $self->selected;
} 

our %field_map = (
    status => 'category.status',       
    status_new => 'category.status',       
    name_status => 'category.status',       
);

sub selected_fields {
    my ($self, $p ) = @_; 
    my %ret = ( ids=>['mid'], names=>[] );
    my %fields = map { $_->{type}=>$_->{children} } _array( $self->selected );
    for ( _array($fields{select}) ) {
        my $id = $field_map{$_->{id_field}} // $_->{id_field};
        my $as = $_->{as} // $_->{name_field};
        push @{ $ret{ids} }, $id;
        push @{ $ret{names} }, $as; 
        push @{ $ret{columns} }, { as=>$as, id=>$id };
    }
    return \%ret;
}

sub run {
    my ($self, $p ) = @_; 
    my $rows = $self->rows;
    my %fields = map { $_->{type}=>$_->{children} } _array( $self->selected );
    my @selects = map { ( $field_map{$_->{id_field}} // $_->{id_field} )  => 1 } _array($fields{select});
    my @sort = map { $_->{id_field} => -1 } _array($fields{order_by});
    my $rs = mdb->topic->find();
    my $cnt = $rs->count;
    my @topics = map { +{ hash_flatten($_) } } 
      $rs
      ->fields({ @selects, _id=>0, mid=>1 })
      ->sort({ @sort })
      ->limit($rows)
      ->all;
    return ( $cnt, @topics );
}

1;

__END__

- set sort direction in sort fields
- return data with dots instead of nested 
- set alias Header on select_field
- fieldlet "attribute" tells the mongo dot attribute (but for now, we can just map some of them manually)
- fieldlet "meta_type" tells what type it is: text,date,number 
- statements OR ($or), AND ($and), NOT ($not) ... in? nin?
- sql post filter with SQLite
- topic returns data from run (no post processing), topic store gets dot.fields 





