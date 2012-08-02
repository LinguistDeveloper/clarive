package BaselinerX::Release::Provider::Release;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Release::Namespace::Release;
use Try::Tiny;

with 'Baseliner::Role::Provider';

register 'namespace.release' => {
    name	=>_loc('Release'),
    domain  => domain(),
    can_job => 1,
    finder =>  \&find,
    handler =>  \&list,
};

sub namespace { 'BaselinerX::Release::Namespace::Release' }
sub domain    { 'release' }
sub icon      { '/static/images/icon/release.gif' }
sub name      { 'Releases' }

sub find {
    my ($self, $item ) = @_;
    my $col = is_number( $item ) ? 'id' : 'name';
    my $release = Baseliner->model('Baseliner::BaliRelease')->search({ $col=>$item })->first;
    return BaselinerX::Release::Namespace::Release->new({ row => $release }) if( ref $release );
}

#deprecated?
sub get { goto &find }

sub list {
    my ($self, $c, $p) = @_;
    _log "provider list started...";

    my $bl = $p->{bl};
    ( ref $c && ref $c->stash ) and $bl ||= $c->stash->{bl};
    my $query = $p->{query};
    my $job_type = $p->{job_type};  #TODO filter if job_type and release situation are compatible
    my $dir = $p->{dir};
    my $sort = $p->{'sort'};

    my @ns;
    my $where = {};
    my $filter = {};

    # user control
    if( $p->{username} && ! Baseliner->model('Permissions')->is_root( $p->{username} ) ) {
        my @ns_list = Baseliner->model('Permissions')->user_namespaces( $p->{username} ); 
        $where->{'me.ns'} = { -in => \@ns_list }; 
    }

    # bl
    if( $p->{bl} && $p->{bl} ne '*' ) {
        if( $p->{can_job} ) {
            my $bl_job = {
                DESA => [ 'DESA' ],
                PREP => [ 'DESA' ],
                PROD => [ 'PREP' ]
            };  #TODO a requesters problem, not mine
            $where->{bl} = $bl_job->{ $p->{bl} };
        } else {
            $where->{bl} = [ '*', $p->{bl} ];
        }
    }

    # ordering mappings
    $sort = 'ns' if $sort =~ /application/i;
    $sort = 'ns' if $sort =~ /contents/i; # no sorting on contents

    # paging 
    my %range = defined $p->{start} && defined $p->{limit}
        ? ( page => (abs( $p->{start} / $p->{limit} ) + 1), rows=>$p->{limit} )
        : ();

    # searching
    $query and $where = query_sql_build(
        query  => $query,
        fields => {
            name        => 'name',
            username    => 'username',
            bl          => 'bl',
            description => 'description',
            ts          => 'me.ts',
            items       => 'bali_release_items.item',
    }
    );

    # first, a joint search release + items
    my $rs_search = Baseliner->model('Baseliner::BaliRelease')->search(
        $where,
        { %$filter, join=>['bali_release_items'], select=>[ { distinct=>'me.id' }], as=>['id'],  }
    );
    rs_hashref( $rs_search );
    my @ids = map { $_->{id} } $rs_search->all;
    _debug "===================IDS=" . @ids;
    my $skipped=0;
    # now the release only search
    my $rs = Baseliner->model('Baseliner::BaliRelease')->search( { id=>\@ids }, { %$filter, %range, order_by=>($sort?"$sort $dir" : "name desc") } );
    while( my $r = $rs->next ) {
        my $item = BaselinerX::Release::Namespace::Release->new({ row=>$r });
        
        if ( $p->{job_type} ) {
            unless ( $item->can_job(job_type=>$p->{job_type}, bl=>$p->{bl}) || $item->why_not !~ m/PROM_TGT_ENV/g )	{
                $skipped+=1;
                next;
                } 
            }
            
        push @ns, $item ;

        # fix bl problems
        if( $r->bl eq '*' || !$r->bl ) {
            $r->bl( $item->bl_from_contents );
            $r->update;
        }
    }

    my $cnt = scalar @ns;
    my $total = $rs->is_paged ? ($rs->pager->total_entries - $skipped) : $cnt;
    # my $total = $rs->is_paged ? $rs->pager->total_entries : $cnt;
    _log "provider list finished (records=$cnt/$total).";
    return { data=>\@ns, total=>$total, count=>$cnt };
}


1;
