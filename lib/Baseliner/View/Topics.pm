package Baseliner::View::Topics;
use Moose;

use Array::Utils qw(intersect);
use Hash::Merge qw(merge);
use Baseliner::Model::Topic;
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_fail _array);

sub view {
    my $self = shift;
    my (%params) = @_;

    my $sort = delete $params{sort};
    my $dir  = delete $params{dir};
    $dir = $dir && lc($dir) eq 'desc' ? -1 : 1;

    my $limit = delete $params{limit};
    my $skip = delete $params{skip} || delete $params{start};

    if ( my $query = $params{query} ) {
        $skip //= delete $params{skip} || delete $query->{start};
        $limit //= delete $query->{limit};
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

    my $username      = $params{username};
    my @categories    = _array $params{categories};
    my $category_type = $params{category_type};
    my @statuses      = _array $params{statuses};
    my $not_in_status = $params{not_in_status};
    my $query         = $params{query};

    my $where = {};

    if ($query) {
        delete $query->{start};
        delete $query->{limit};

        if ( my $categories = delete $query->{categories} ) {
            push @categories, _array $categories;
        }

        if ( my $statuses = delete $query->{statuses} ) {
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

    if ($query) {
        $where = merge $where, $query;

        delete $where->{query} unless defined($where->{query}) && $where->{query} ne '';
    }

    return $where;
}

1;
