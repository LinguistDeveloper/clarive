package BaselinerX::CA::Harvest::Provider::PackageGroup;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::PackageGroup;
use BaselinerX::CA::Harvest::DB;
use Try::Tiny;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.packagegroup' => {
    name    =>_loc('Harvest Package Groups'),
    domain  => domain(),
    can_job => 1,
    finder =>  \&find,
    handler =>  \&list,
};

sub namespace { 'BaselinerX::CA::Harvest::Namespace::PackageGroup' }
sub domain    { 'harvest.packagegroup' }
sub icon      { '/static/images/scm/packages.gif' }
sub name      { 'PackageGroups' }

sub find {
    my ($self, $item ) = @_;
    #my ($domain, $item ) = ns_split( $ns );
    my $col = is_number( $item ) ? 'pkggrpobjid' : 'pkggrpname' ;
    _debug "Finding $item...";
    my $package = Baseliner->model('Harvest::Harpackagegroup')->search({ $col=>$item })->first;
    return BaselinerX::CA::Harvest::Namespace::PackageGroup->new({ row => $package }) if( ref $package );
}

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;
    _log "Provider list started...";
    my $bl = $p->{bl};
    ( ref $c && ref $c->stash ) and $bl ||= $c->stash->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};

    my $hardb = BaselinerX::CA::Harvest::DB->new;

    # paging 
    my %range = defined $p->{limit}
        ? ( page => (abs( $p->{start} / $p->{limit} ) + 1), rows=>$p->{limit} )
        : ();

    #sorting 
    $range{order_by} = $p->{sort} || 'pkggrpname';

    my $where = {};

    # searching
    $query and $where = query_sql_build(
        query  => $query,
        fields => {
            pkggrpname  => 'pkggrpname',
            username    => 'modifier.username',
            harvest     => "'harvest'",
        }
    );
    $where->{pkggrpobjid} = { '>', 0 };

    #if( $p->{can_job} ) {
    #    #my $states = $hardb->states_for_job( bl=> $bl, job_type=>$job_type );
    #    $where = { pkggrpobjid => { '>', 0 } };
    #}
    #elsif( $p->{states} ) {
    #    $where = { pkggrpobjid => { '>', 0 } };
    #}
    #else {
    #    $where = { pkggrpobjid => { '>', 0 } };
    #}

    # user control
    if( $p->{username} && ! $hardb->is_superuser($p->{username}) ) {
        my @envs = $hardb->envs_for_user( $p->{username} ); 
        $where->{'me.envobjid'} = { -in => [ @envs ] }; 
    }

    $where->{'envisactive'} = 'Y';

    # from
    my $from = {
        join => [ 'modifier', 'envobjid' ],
        %range,
    };
    # setup bl lookup
    my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map', ns=>'/' );
    my $bl_map = $inf->{view_to_baseline} || {};

    if( $bl && $bl ne '*' ) {
        my @ids = $hardb->packagegroup_for_bl($bl );
        $where->{'me.pkggrpobjid'} = \@ids if @ids;
    }

    my $rs = Baseliner->model('Harvest::Harpackagegroup')->search( $where, $from );

    my @ns;
    my @bl_filter = _array( $bl ) unless $bl eq '*';
    my $ns_type= _loc('Package Group');
    my $repo = Baseliner->model('Repository');
    my $domain = $self->domain;
    while( my $r = $rs->next ) {
        my $item = BaselinerX::CA::Harvest::Namespace::PackageGroup->new({ row => $r, });
        #my @bls = $item->bl;  # expensive!
        #  my $bl_item = @bls>1 || @bls==0 ? '*' : $bls[0];
        #   $item->_bl( $bl_item );
        # check bl
        #if( $bl && $bl ne '*' ) {
        #   next unless grep { my $b=$_; grep { $b && ($b eq $_) } @bl_filter } @bls;
        #}
        push @ns, $item;
        $repo->set( ns=>$item->{ns}, provider=>$domain, data=>$item->{ns_data} );   
    }
    my $cnt = scalar @ns;
    my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;
    _log "provider list finished (records=$cnt/$total).";
    return { data=>\@ns, total=>$total, count=>$cnt };
}

1;
