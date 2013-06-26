package BaselinerX::CI::CASCMRepository;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Repository';

has project       => qw(is rw isa Maybe[Str]);
has viewpath      => qw(is rw isa Str default /);
has db_connection => qw(is rw isa Str default), sub {
    my ($self)=@_;
    Baseliner->model('Harvest')->connect_info->{dsn};
};
has viewname     => qw(is rw isa Str);
has project_mask => qw(is rw isa Str ), default => sub {
    my ($self)=@_;
    $self->name . '%';
};
has project_name => qw(is rw isa Maybe[Str]);

sub collection { 'CASCMRepository' }
sub icon       { '/scm/repo.png' }

sub checkout { }
sub list_elements { }
sub repository { }
sub update_baselines { }

service scan => 'Scan Items' => sub {
    my ($self,$c,$p) =@_;
    my @items = $self->method_scan( $p );
    for ( @items ) {
        $_->tree_resolve;
    }
    \@items;
};


service load_items => 'Load Items' => sub {
    my ($self,$c,$p) =@_;
    my $its = $self->load_items();
    for( @{ $its->children } ) {
        $_->save;
    }
    # relate to packages
    for my $v ( @{ $its->children } ) {
        if( my $pkg = DB->BaliMaster->search({ ns=>'harpackage/'.$v->packageobjid })->first ) {
            DB->BaliMasterRel->find_or_create({ from_mid=>$pkg->mid, to_mid=>$v->mid, rel_type=>'revision_item' });
        }
    }
    return $its;
};

service load_packages => 'Load Packages' => sub {
    my ($self,$c,$p) =@_;
    $self->load_revisions();
    return "ok scan: " . Util->_dump( $self );
};

sub load_items {
    my ( $self, %p ) = @_;
    my $db = BaselinerX::CA::Harvest::DB->new;
    my @versions = $db->view_items( 
        environmentname=>$self->project_name, 
        viewname=>( $p{viewname} // $self->viewname ), 
        viewpath=>( $p{viewpath} // $self->viewpath ) );
    my @items = map {
        my $r = $_;
        my $vp = $r->{pathfullname};
        $vp =~ s{\\}{/}g;
        my $basename = $r->{itemname} =~ /^(.*)\.\w+$/ ? $1 : $r->{itemname};
        my $path = "$vp/$r->{itemname}";
        BaselinerX::CI::CASCMVersion->new(
            name             => $r->{itemname},
            basename         => $r->{itemname},
            size             => $r->{datasize} // 0,  # XXX missing in the previous query due to speed
            dir              => $vp,
            path             => $path,
            is_dir           => $r->{itemtype} != 1,
            itemobjid        => $r->{itemobjid},
            viewpath         => $vp,
            versionobjid     => $r->{versionobjid},
            versiondataobjid => $r->{versiondataobjid},
            packageobjid     => $r->{packageobjid},
            packagename      => $r->{packagename},
            versionid        => $r->{mappedversion},
            moniker          => $basename, 
            compressed       => defined $r->{compressed} ? ( $r->{compressed} eq 'Y' ) : 1,  # XXX missing in the previous query due to speed
            ns               => 'harversion/' . $r->{versionobjid}
        );
    } @versions;

    BaselinerX::CI::itemset->new( children => \@items );
}


sub load_revisions {
    my ($self,%p) = @_;
    use Baseliner::Utils;
    my $hpkg = Baseliner->model('Harvest::Harpackage');
    my $envname = $self->project_name || $self->project_mask;
    my $where = { 
            environmentname => { -like => $envname },
            packageobjid    => { '>'=>2 },
        };
    $where->{packagename} = $p{name} if $p{name};
    my @pkgs = Baseliner->model('Harvest::Harpackage')->search(
        $where,
        { join=>'envobjid', 
          select=>[qw/packageobjid packagename envobjid.environmentname/ ], 
          as=>[qw/packageobjid packagename project/] 
        }
    )->hashref->all;
    for my $pkg ( @pkgs ) {
        my $ns = "harpackage/$pkg->{packageobjid}";
        my $row = DB->BaliMaster->search({ ns=>$ns })->first;
        if( !$row ) {
            my $ci = BaselinerX::CI::CASCMPackage->new( ns=>$ns, name=>$pkg->{packagename}, packageobjid=>$pkg->{packageobjid} );
            $ci->save( data=>$pkg );
        } else {
            $pkg->{mid} = $row->mid;
            _ci( $row->mid )->update( data=>$pkg );; 
        }
    }
    @pkgs;
}

1;
