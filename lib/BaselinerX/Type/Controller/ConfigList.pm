package BaselinerX::Type::Controller::ConfigList;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' };

register 'action.admin.config_list' => { name => 'Administer configuration variables'};
register 'menu.admin.config_list' => { label=>'Config List', url_comp=>'/configlist/grid', title=>'Config List', icon=>'/static/images/icons/config.gif', action => 'action.admin.config_list' };

sub grid : Local {
    my ($self,$c)=@_;
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/configlist/grid.mas';
}

sub delete : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    try {
        $c->model('ConfigStore')->delete( _id=>$p->{id} );
        $c->stash->{json} = { success => \1, msg => _loc("Config value %1 deleted", $$ ) };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting config value %1: %2", $p->{key}, $err ) };
    };
    $c->forward('View::JSON');	
}

sub resolve : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    try {
        my $value = $c->model('ConfigStore')->get( $p->{key}, ns=>$p->{ns}, bl=>$p->{bl}, long_key=>1, value=>1 );
        $c->stash->{json} = { success => \1, msg => $value };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting config value %1: %2", $p->{key}, $err ) };
    };
    $c->forward('View::JSON');	
}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my $row;
    try {
        if( $p->{id} ) {
            # update
            $row = $c->model('ConfigStore')->set( _id=>$p->{id}, key=>$p->{key}, value=>$p->{value}, bl=>$p->{bl}, ns=>$p->{ns} );
        } else {
            # create
            $row = $c->model('ConfigStore')->set( key=>$p->{key}, value=>$p->{value}, bl=>$p->{bl}, ns=>$p->{ns} );
        }
        $c->stash->{json} = { success => \1, msg => _loc("Config value %1 saved", $p->{key} ), _id => $row->{value} };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => _loc("Error storing config value %1: %2", $$, $err ) };
    };
    $c->forward('View::JSON');	
}

sub json : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;

    if( $p->{original} && $p->{original} eq 'true' ) {
        $c->forward('json_original') ;
    } elsif( $p->{modified} && $p->{modified} eq 'true' ) {
        $c->forward('json_modified') ;
    } else {
        $c->forward('json_combined');
    }
}

sub json_combined : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
    $sort ||= 'key';
    $dir ||= 'asc';

    my $res1 = $c->model('ConfigStore')->search_registry( query=>$query );

    my %original = map { $_->{key} => 1 } _array $res1->{data};

    my %modified;
    my $res2 = $c->model('ConfigStore')->search( query=>$query,  );  
    for( _array( $res2->{data} ) ) { 
        next unless $_->{ns} eq '/';
        next unless $_->{bl} eq '*';
        $modified{$_->{key}}=$_;
    }
    my @ret;
    my $modified = 0;
    for( _array( $res1->{data} ) ) {
        if( ref ( my $row = $modified{$_->{key}} ) ) {
            $row->{status} = 'modified';
            push @ret, $row;
            $modified++;
        } else { 
            $_->{status} = 'original';
            push @ret, $_;
        }
    }
    for( _array( $res2->{data} ) ) {
        my $orig = $original{ $_->{key} };
        next if ref $orig
            && $orig->{ns} eq $_->{ns}
            && $orig->{bl} eq $_->{bl}; 
        $_->{status} = 'missing';
        push @ret, $_;
    }

    @ret = sort { 
        my $va = $a->{$sort};
        my $vb = $b->{$sort};
        !defined $va ? 1 : !defined $vb ? -1 : $va cmp $vb
    } @ret if $sort;
    @ret = reverse @ret if lc($dir) eq 'desc';

    $c->stash->{json} = { 
        data =>  \@ret,
        totalCount => scalar @ret - $modified
    };
    $c->forward('View::JSON');
}

sub json_original : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start ps query dir sort/};
    $start||=0;
    $limit||=50;
    my $res = $c->model('ConfigStore')->search_registry( query=>$query, start=>$start, limit=>$limit, sort=>$sort, dir=>$dir );
    $c->stash->{json} = { 
        data => $res->{data},
        totalCount => $res->{total},
    };
    $c->forward('View::JSON');
}

sub json_modified : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
    $start||=0;
    $limit||=50;
    my $res = $c->model('ConfigStore')->search( query=>$query, start=>$start, limit=>$limit, sort=>$sort, dir=>$dir  );  
    $c->stash->{json} = { 
        data =>  $res->{data},
        totalCount => $res->{total},
    };
    $c->forward('View::JSON');
}

# save to a file in /etc
sub save : Local {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    try {
        $c->model('ConfigStore')->export_to_file;
        $c->stash->{json} = { success => \1, msg => _loc("Config data exported") };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => _loc("Error exporting config data: %1", $err ) };
    };
    $c->forward('View::JSON');
}


1;
