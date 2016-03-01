package Baseliner::Dashboard::TopicsBurndown;
use Moose;

use Array::Utils qw(intersect);
use JSON ();
use Class::Date ();
use Baseliner::Model::Topic;
use Baseliner::Utils qw(_now _array);

sub dashboard {
    my $self = shift;
    my (%params) = @_;

    my $id_project = $params{id_project};
    my $topic_mid  = $params{topic_mid};

    my $username = $params{username} or die 'username required';

    my $to = $params{to} || _now();
    my $from = $params{from} || do { my $copy = $to; $copy =~ s/ \d\d:\d\d:\d\d/ 00:00:00/; $copy };

    $from = "$from 00:00:00" unless $to =~ m/ \d\d:\d\d:\d\d/;
    $to   = "$to 23:59:59"   unless $to =~ m/ \d\d:\d\d:\d\d/;

    my $from_date = Class::Date->new($from);
    my $to_date   = Class::Date->new($to);

    my $scale      = $params{scale}      || 'hour';
    my $date_field = $params{date_field} || 'created_on';
    my $categories = $params{categories} || [];
    my $query      = $params{query};
    my @closed_statuses = _array $params{closed_statuses};

    if (@closed_statuses) {
        @closed_statuses = map { $_->{name} }
          ci->status->find( { id_status => mdb->in(@closed_statuses) } )->fields( { _id => 0, name => 1 } )->all;
    }

    if ( !@closed_statuses ) {
        @closed_statuses = map { $_->{name} } ci->status->find( { type => qr/^F|FC$/ } )->all;
    }

    my $date_query_before_period = { '$lt' => $from };
    my $date_query_during_period = { '$gte' => $from, '$lte' => $to };

    my $group_by;
    my $where = {};

    if ($query) {
        $query = JSON::decode_json($query);
        $where = {%$query};
    }

    my %burndown = ();
    if ( $scale eq 'hour' ) {
        $group_by = { '$substr' => [ '$ts', 0, 13 ] };

        while ( $from_date < $to_date ) {
            for (0 .. 23) {
                $burndown{ substr($from_date, 0, 11) . sprintf('%02d', $_) } = 0;
            }

            $from_date = $from_date + '1D';
        }
    }
    elsif ( $scale eq 'day' ) {
        $group_by = { '$substr' => [ '$ts', 0, 10 ] };

        while ( $from_date < $to_date ) {
            $burndown{ substr $from_date, 0, 10 } = 0;

            $from_date = $from_date + '1D';
        }
    }
    elsif ( $scale eq 'month' ) {
        $group_by = { '$substr' => [ '$ts', 5, 2 ] };

        while ( $from_date < $to_date ) {
            $burndown{ substr $from_date, 0, 7 } = 0;

            $from_date = $from_date + '1M';
        }
    }
    else {
        die 'unknown scale';
    }

    my $topic_group_by = { '$substr' => [ @{ $group_by->{'$substr'} } ] };
    $topic_group_by->{'$substr'}->[0] = "\$${date_field}";

    my @user_categories = map { $_->{id} }
      Baseliner::Model::Topic->new->get_categories_permissions( username => $username, type => 'view' );
    if (@$categories) {
        my @categories_ids = _array($categories);
        @user_categories = intersect( @categories_ids, @user_categories );
    }

    my $perm = Baseliner::Model::Permissions->new;

    my $is_root = $perm->is_root($username);
    if ( $username && !$is_root ) {
        $perm->build_project_security( $where, $username, $is_root, @user_categories );
    }

    Baseliner::Model::Topic->new->filter_children( $where, id_project => $id_project, topic_mid => $topic_mid );

    my @backlog_remaining = map { $_->{mid} } mdb->topic->find(
        {
            'category.id'          => mdb->in(@user_categories),
            'category_status.name' => mdb->nin(@closed_statuses),
            $date_field            => $date_query_before_period,
            %$where,
        }
    )->fields( { _id => 0, mid => 1 } )->all;
    my @topics_created_during = map { $_->{mid} } mdb->topic->find(
        {
            'category.id' => mdb->in(@user_categories),
            $date_field   => $date_query_during_period,
            %$where,
        }
    )->fields( { mid => 1 } )->all;
    my @topics_created_before = map { $_->{mid} } mdb->topic->find(
        {
            'category.id' => mdb->in(@user_categories),
            $date_field   => $date_query_before_period,
            %$where,
        }
    )->fields( { mid => 1 } )->all;
    my @backlog_closed = map { $_->{mid} } mdb->activity->find(
        {
            'mid'         => mdb->in(@topics_created_before),
            'event_key'   => 'event.topic.change_status',
            'vars.status' => mdb->in(@closed_statuses),
            'ts'          => $date_query_during_period,
        },
    )->fields( { _id => 0, mid => 1 } )->all;

    foreach my $by ( keys %burndown ) {
        $burndown{$by} = @backlog_remaining + @backlog_closed;
    }

    my @closed_topics_aggr = mdb->activity->aggregate(
        [
            {
                '$match' => {
                    'event_key'   => 'event.topic.change_status',
                    'mid'         => mdb->in( @topics_created_during, @topics_created_before ),
                    'vars.status' => mdb->in(@closed_statuses),
                    'ts'          => $date_query_during_period,
                }
            },
            { '$group' => { _id => $group_by, total => { '$sum' => 1 } } }
        ]
    );

    my @created_topics_aggr = mdb->topic->aggregate(
        [
            {
                '$match' => {
                    'category.id' => mdb->in(@user_categories),
                    $date_field   => $date_query_during_period,
                    %$where,
                }
            },
            { '$group' => { _id => $topic_group_by, total => { '$sum' => 1 } } }
        ]
    );

    $self->_update_burndown( $created_topics_aggr[0], \%burndown, 1 );
    $self->_update_burndown( $closed_topics_aggr[0],  \%burndown, -1 );

    my $data = [
        map { [ $_, $burndown{$_} ] }
        sort { $a cmp $b } keys %burndown
    ];

    return $data;
}

sub _update_burndown {
    my $self = shift;
    my ( $topics, $burndown, $sign ) = @_;

    foreach my $topic (@$topics) {
        my $from  = $topic->{_id};
        my $total = $topic->{total};

        foreach my $by ( sort { $a cmp $b } keys %$burndown ) {
            next if $by lt $from;

            $burndown->{$by} += $total * $sign;
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
