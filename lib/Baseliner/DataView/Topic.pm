package Baseliner::DataView::Topic;
use Moose;

use Array::Utils qw(intersect);
use Hash::Merge qw(merge);
use JSON ();
use Baseliner::Model::Topic;
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_fail _log _array _dump);

sub find {
    my $self = shift;
    my (%params) = @_;

    my $sort = delete $params{sort};
    my $dir  = delete $params{dir};
    $dir = $dir && (lc($dir) eq 'desc' || $dir eq '-1') ? -1 : 1;

    my $limit = delete $params{limit};
    my $skip = delete $params{skip} || delete $params{start};

    if ( my $filter = $params{filter} ) {
        $filter = $params{filter} = $self->_parse_filter($filter);

        $skip //= delete $filter->{skip} || delete $filter->{start};
        $limit //= delete $filter->{limit};
    }

    my $where = $self->build_where(%params);
    my $rs = mdb->topic->find($where);

    if ($sort) {
        $rs->sort( { $sort => $dir } );
    }

    $rs->limit($limit) if $limit;
    $rs->skip($skip)   if $skip;

    return $rs;
}

sub build_where {
    my $self = shift;
    my (%params) = @_;

    my $id_project = $params{id_project};
    my $topic_mid  = $params{topic_mid};

    my $where         = $params{where} || {};
    my $valuesqry     = $params{valuesqry};
    my $username      = $params{username} or _fail 'username required';
    my @categories    = _array $params{categories};
    my $category_type = $params{category_type};
    my @statuses      = _array $params{statuses};
    my $not_in_status = $params{not_in_status};
    my $filter        = $self->_parse_filter( $params{filter} );
    my $search_query  = $params{search_query};
    my @priorities;
    my @labels;
    my @category_status_id;

    if (!$valuesqry || $valuesqry ne 'true') {
        if ($filter) {
            delete $filter->{start};
            delete $filter->{limit};

            if ( my $categories = delete $filter->{categories} ) {
                push @categories, _array $categories;
            }

            if ( my $statuses = delete $filter->{statuses} ) {
                push @category_status_id, _array $statuses;
            }

            if ( my $priorities = delete $filter->{priorities} ) {
                push @priorities, _array $priorities;
            }

            if ( my $labels = delete $filter->{labels} ) {
                push @labels, _array $labels;
            }
        }

        if(@category_status_id){
            my @in = grep {!m/^\-/ } @category_status_id;
            my @not_in = map { s/^.{1}//s; $_} grep { m/^\-/ } @category_status_id;

            if (@statuses) {
                if ($not_in_status) {
                    push(@not_in, @statuses);
                }else {
                    push(@in, @statuses);
                }
            }
            if (@not_in && @in){
                $where->{'category_status.id'} = {'$nin' =>\@not_in, '$in' =>\@in};
            }else{
                $where->{'category_status.id'} = @not_in ? 
                        mdb->nin(@not_in) : mdb->in(@in);
            }
        } else {
            if (@statuses) {
                $where->{'category_status.id'} = $not_in_status ?
                        mdb->nin(@statuses) : mdb->in(@statuses);
            }
        }

        if (@labels) {
            $where->{'labels'} = mdb->in(@labels);
        }

        my @user_categories = map { $_->{id} }
          Baseliner::Model::Topic->new->get_categories_permissions( username => $username, type => 'view' );
        if (@categories) {
            @user_categories = intersect( @categories, @user_categories );
        }

        my $perm = Baseliner::Model::Permissions->new;

        my $is_root = $perm->is_root($username);
        if ( $username && !$is_root ) {
            $perm->build_project_security( $where, $username, $is_root, @user_categories );
        }

        $where->{'category.id'} = mdb->in(@user_categories) if @categories;

        if ($category_type) {
            if ( $category_type eq 'release' ) {
                $where->{'category.is_release'} = 1;
            }
            elsif ( $category_type eq 'changeset' ) {
                $where->{'category.is_changeset'} = 1;
            }
            else {
                _fail 'Uknown category type';
            }
        }

        Baseliner::Model::Topic->new->filter_children( $where, id_project => $id_project, topic_mid => $topic_mid );

        if ($filter) {
            $where = merge $where, $filter;
        }
       
        if ( defined $search_query && length $search_query ) {
            my @mids_in = _array( delete $where->{mid} );
            push @mids_in, _array( delete $where->{mid}{'$in'} ) if ref $where->{mid} eq 'HASH';
            push @mids_in,
              Baseliner::Model::Topic->new->run_query_builder( $search_query, $where, $username, build_query => 1 );
            $where->{mid} = mdb->in(@mids_in) if @mids_in;
        }
    }   

    return $where;
}

sub _parse_filter {
    my $self = shift;
    my ($filter) = @_;

    return {} unless defined $filter && length $filter;

    return $filter if ref $filter eq 'HASH';

    return eval { JSON::decode_json($filter) } or do { +{} };
}

1;
