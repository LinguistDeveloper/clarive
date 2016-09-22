package Baseliner::DataView::Job;
use Moose;

use JSON ();
use Array::Utils qw(intersect);
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_fail _array _unique _debug);

sub find {
    my $self = shift;
    my (%params) = @_;

    my $groupby    = delete $params{groupby};
    my $dir        = delete $params{dir};
    my $sort       = delete $params{sort};
    my $groupdir   = delete $params{groupdir};
    my $group_keys = $params{group_keys};

    my $permissions  = Baseliner::Model::Permissions->new;
    return unless $permissions->user_has_action( $params{username}, 'action.job.viewall', bounds => '*');

    $sort ||= 'starttime';
    $dir = !$dir ? -1 : lc $dir eq 'desc' ? -1 : 1;

    my @order_by;
    if ( length($groupby) ) {
        $groupdir = $groupdir eq 'ASC' ? 1 : -1;
        @order_by = (
            $group_keys->{$groupby} => ( $groupby eq 'when' ? -1 : $groupdir ),
            $group_keys->{$sort} => $dir
        );
    }
    else {
        @order_by = ( $group_keys->{$sort} => $dir ) if $group_keys->{$sort};
    }

    my $where = $self->build_where(%params);

    my $rs = mdb->master_doc->find( { collection => 'job', %$where } );

    if (@order_by) {
        $rs->sort( mdb->ixhash(@order_by) );
    }

    return $rs;
}

sub build_where {
    my $self = shift;
    my (%params) = @_;

    my $username     = delete $params{username} or _fail 'username required';
    my $filter       = $self->_parse_filter( $params{filter} );
    my $where        = delete $params{where} || {};
    my $group_keys   = delete $params{group_keys};
    my $query_id     = delete $params{query_id};
    my $query        = delete $params{query};
    my $period       = delete $filter->{period};
    my $where_filter = delete $params{where_filter};
    my @bls          = _array $filter->{bls};
    my $permissions  = Baseliner::Model::Permissions->new;

    if ($query) {
        _debug "Job QUERY=$query";
        my @mids_query;
        if ( $query !~ /\+|\-|\"|\:/ ) {
            $query =~ s{(\w+)\*}{job "$1"}g;
            $query =~ s{([\w\-\.]+)}{"$1"}g;
            $query =~ s{\+(\S+)}{"$1"}g;
            $query =~ s{""+}{"}g;
            @mids_query = map { $_->{obj}{mid} } _array(
                mdb->master_doc->search(
                    query   => $query,
                    limit   => 1000,
                    project => { mid => 1 },
                    filter  => { collection => 'job' }
                )->{results}
            );
        }
        if ( !@mids_query ) {
            mdb->query_build( where => $where, query => $query, fields => [ keys %$group_keys ] );
        }
        else {
            my @mid_filters;
            push @mid_filters, { mid => mdb->in(@mids_query) };
            $where->{'$and'} = \@mid_filters if @mid_filters;
        }
    }

    $permissions->inject_project_filter( $username, 'action.job.viewall', $where, filter => $filter->{filter_project} );

    $permissions->inject_bounds_filters(
        $username,
        'action.job.viewall',
        $where,
        filters => {
            bl => \@bls
        }
    );

    if ($period) {
        my $start = substr( Class::Date->now - $period, 0, 10 );
        $where->{endtime} = { '$gt' => "$start" };
    }
    if ( $filter->{filter_nature} ) {
        $where->{natures} = mdb->in( _array( $filter->{filter_nature} ) );
    }
    if ( $filter->{filter_type} ) {
        $where->{job_type} = $filter->{filter_type};
    }

    if ( $filter->{job_state_filter} ) {
        my @job_state_filters = do {
            my $job_state_filter = Util->_decode_json( $filter->{job_state_filter} );
            _unique grep { $job_state_filter->{$_} } keys %$job_state_filter;
        };
        $where->{status} = mdb->in( \@job_state_filters );
    }

    if ( $query_id && $query_id ne '-1' ) {
        my @jobs = split( ",", $query_id );
        $where->{'mid'} = mdb->in( \@jobs );
    }

    if ($where_filter) {
        $where = { %$where, %$where_filter };
    }

    return $where;
}

sub _parse_filter {
    my $self = shift;
    my ($filter) = @_;

    return {} unless defined $filter && length $filter;

    return $filter if ref $filter eq 'HASH';

    my $result = eval { JSON::decode_json($filter) };
    $result //= {};
    return $result;
}

1;
