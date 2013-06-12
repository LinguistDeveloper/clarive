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

service load_packages => 'Load Packages' => sub {
    my ($self,$c,$p) =@_;
    $self->load_revisions();
    return "ok scan: " . Util->_dump( $self );
};

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
            my $ci = BaselinerX::CI::CASCMPackage->new( ns=>$ns, name=>$pkg->{packagename} );
            $ci->save( data=>$pkg );
        } else {
            $pkg->{mid} = $row->mid;
            _ci( $row->mid )->update( data=>$pkg );; 
        }
    }
    @pkgs;
}

service scan => 'Scan files' => sub {
    my ($self,$c,$p) =@_;
    return "ok scan: " . Util->_dump( $self );
};

1;
