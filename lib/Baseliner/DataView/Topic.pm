package Baseliner::DataView::Topic;
use Moose;

use Array::Utils qw(intersect);
use Hash::Merge qw(merge);
use JSON ();
use Baseliner::Model::Topic;
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_fail _array);

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
    my $username      = $params{username} or _fail 'username required';
    my @categories    = _array $params{categories};
    my $category_type = $params{category_type};
    my @statuses      = _array $params{statuses};
    my $not_in_status = $params{not_in_status};
    my $filter        = $self->_parse_filter( $params{filter} );
    my $search_query  = $params{search_query};

    if ($filter) {
        delete $filter->{start};
        delete $filter->{limit};

        if ( my $categories = delete $filter->{categories} ) {
            push @categories, _array $categories;
        }

        if ( my $statuses = delete $filter->{statuses} ) {
            push @statuses, _array $statuses;
        }
    }

    if (@statuses) {
        if ($not_in_status) {
            $where->{'category_status.id'} = mdb->nin(@statuses);
        }
        else {
            $where->{'category_status.id'} = mdb->in(@statuses);
        }
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
        $where->{query} = $search_query;
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
