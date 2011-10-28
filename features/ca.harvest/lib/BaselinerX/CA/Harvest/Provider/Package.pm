package BaselinerX::CA::Harvest::Provider::Package;
use utf8;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::CA::Harvest::Namespace::Package;
use BaselinerX::CA::Harvest::DB;
use utf8;
use Try::Tiny;

with 'Baseliner::Role::Provider';
with 'Baseliner::Role::Namespace::Create';

register 'namespace.harvest.package' => {
    name    =>_loc('Harvest Packages'),
    domain  => domain(),
    can_job => 1,
    finder =>  \&find,
    handler =>  \&list,
};

sub namespace { 'BaselinerX::CA::Harvest::Namespace::Package' }
sub domain    { 'harvest.package' }
sub icon      { '/static/images/scm/package.gif' }
sub name      { 'HarvestPackages' }

# returns the first rows it finds for a given name
sub find {
    my ($self, $item ) = @_;
    my $col = is_number( $item ) ? 'packageobjid' : 'packagename' ;
    my $package = Baseliner->model('Harvest::Harpackage')->search(
        { $col => $item },
        {
            join => [ 'state', 'modifier', 'envobjid', 'harview' ],
            '+select' => ['state.statename', 'envobjid.environmentname', 'modifier.username', 'harview.viewname' ],
            '+as' => ['statename', 'environmentname', 'username', 'viewname' ],
        }
    )->first;
    return BaselinerX::CA::Harvest::Namespace::Package->new({ row => $package }) if( ref $package );
}

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;
    _log "provider list started...";
    my $bl = $p->{bl};
    my $rfc = $p->{rfc};
    ( ref $c && ref $c->stash ) and $bl ||= $c->stash->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};

    my $hardb = BaselinerX::CA::Harvest::DB->new;

    # paging 
    my %range = defined $p->{limit}
        ? ( page => (abs( $p->{start} / $p->{limit} ) + 1), rows=>$p->{limit} )
        : ();
    
    #sorting 
    $range{order_by} = $p->{sort} || 'packagename';

    # checkin
    $p->{checkin} and do { $p->{states} = $hardb->states_for_checkin ; $bl = '*' };

    my $where = {};

    # searching
    $query and $where = query_sql_build(
        query  => $query,
        fields => {
            packagename => 'packagename',
            username    => 'modifier.username',
            harvest     => "'harvest'",
            statename   => 'statename',
            environmentname => 'environmentname',
        }
    );
    $where->{packageobjid} = { '>', 0 };

    if( $p->{can_job} ) {
        my $states = $hardb->states_for_job(bl=> $bl, job_type=>$job_type);
        $where->{statename} = $states;
    }
    elsif( $bl && $bl ne '*' ) {
        my $viewobjids = $hardb->viewobjids_for_bl($bl);
        $where->{'me.viewobjid'} = $viewobjids;
    }
    elsif( $p->{states} ) {
        $where->{statename} = $p->{states};
    }

    # user control
    if( $p->{username} && ! Baseliner->model('Permissions')->is_root($p->{username}) ) {
        my @envs = $hardb->envs_for_user( $p->{username} ); 
        $where->{'me.envobjid'} = { -in => [ @envs ] }; 
    }

    $where->{'envisactive'} = 'Y';

    if( $rfc ) {
        $where->{packagename} = { -like => "%$rfc%" };
    }

    _log _dump $where;
    my $rs = Baseliner->model('Harvest::Harpackage')->search(
        $where,
        {
            join => [ 'state', 'modifier', 'envobjid', 'harview' ],
            '+select' => ['state.statename', 'envobjid.environmentname', 'modifier.username', 'harview.viewname' ],
            '+as' => ['statename', 'environmentname', 'username', 'viewname' ],
            %range,
        }
    );
    my @ns;
    my $ns_type= _loc('Harvest Package');
    my $repo = Baseliner->model('Repository');
    my $domain = $self->domain;
    my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map' );
    my $vb = $inf->{view_to_baseline} ;
    while( my $r = $rs->next ) {
        my $item = BaselinerX::CA::Harvest::Namespace::Package->new({ row => $r });
        $item->view_to_baseline( $vb );

        my @paths = $hardb->packagename_pathfullname($item->ns_data->{packagename});
        my @nats  = (qw/ J2EE .NET BIZTALK /);    # Natures with subapps

        my $acc = _uacc(());
        $acc->($_) for map { _pathxs($_, 2) ~~ @nats ? _pathxs($_, 3) : q{} } @paths;
        my @subs = $acc->();
        $item->ns_data->{subapps} = \@subs;

        my $inc_id = BaselinerX::CA::Harvest::DB->package_inc_id(id => $item->{ns_id}) || 0;
        $item->{inc_id} = $inc_id if $inc_id;
        # _log("item => " . Data::Dumper::Dumper $item);

        $item->{moreInfo} .= "<b>Código de Incidencia: </b>" 
                          .  $item->{inc_id} 
                          .  "<br>" if exists $item->{inc_id};
        $item->{moreInfo} .= "<b>Subaplicaciones:&nbsp;</b>" 
                          .  join('&nbsp;', @{$item->ns_data->{subapps}}) 
                          .  '<br>' if exists $item->ns_data->{subapps} && scalar @{$item->ns_data->{subapps}};
 
        $item->ns_data->{statename} eq 'Pruebas'
          ? do { push @ns, $item 
                   # TODO: Get the env somehow to filter Pruebas.
                   # if substr($item->ns_data->{packagename}, 4, 1) eq 'R' 
               }
          : do { push @ns, $item };
        $repo->set( ns=>$item->{ns}, provider=>$domain, data=>$item->{ns_data} ); #TODO bulk set this outside
    }
    my $cnt = scalar @ns;
    my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;
    _log "provider list finished (records=$cnt/$total).";
    return { data=>\@ns, total=>$total, count=>$cnt };
}

sub create {
    my ($self, %p ) = @_;
    
    my $env = Baseliner->model('Harvest::HarEnvironment')->find( $p{envobjid } );
    _throw _loc("Harvest Environment %1 not found", $p{envobjid} ) unless ref $env;
    my $config = config_get 'config.ca.harvest.cli';
    my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$config->{broker}, login=>$config->{login} });
    my $cp_proc = $config->{package_create_process};
    my $state =  $config->{package_create_state};  #TODO consider using a hashref on BL
    my %args = (
        cmd   => 'hcp',
        -en   => $env->environmentname,
        -st   => $state,
        args  => $p{packagename},
    );
    $args{-pn} = $cp_proc if $cp_proc;
    my $cp = $cli->run( %args );
    return { rc=>$cp->{rc} , output=>$cp->{msg} };
}

sub create_form_url { '/harvest/create_form' }

1;
