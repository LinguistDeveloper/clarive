package Baseliner::Dashboard::TopicsBurndown;
use Moose;

use Array::Utils qw(intersect);
use Baseliner::Model::Topic;
use Baseliner::Utils qw(_now _array);

sub dashboard {
    my $self = shift;
    my (%params) = @_;

    my $username = $params{username} or die 'username required';

    my $to = $params{to} || _now();
    my $from = $params{from} || do { my $copy = $to; $copy =~ s/ \d\d:\d\d:\d\d/ 00:00:00/; $copy };
    my $group_by_period = $params{group_by_period} || 'hour';
    my $date_field      = $params{date_field}      || 'created_on';
    my $categories      = $params{categories}      || [];

    my $date_query_before_period = { '$lt' => $from };
    my $date_query_during_period = { '$gte' => $from, '$lt' => $to };

    my $group_by;
    my $where = {};

    my %burndown = ();
    if ( $group_by_period eq 'hour' ) {
        $group_by = { '$substr' => [ '$ts', 11, 2 ] };

        $burndown{ sprintf( '%02d', $_ ) } = 0 for 0 .. 23;
    }
    elsif ( $group_by_period eq 'day' ) {
        $group_by = { '$substr' => [ '$ts', 8, 2 ] };

        $burndown{ sprintf( '%02d', $_ ) } = 0 for 0 .. 6;
    }
    elsif ( $group_by_period eq 'date' ) {
        $group_by = { '$substr' => [ '$ts', 0, 10 ] };

        my $from_date = Class::Date->new($from);
        my $to_date = Class::Date->new($to);

        while ($from_date < $to_date) {
            $burndown{ substr $from_date, 0, 10} = 0;

            $from_date = $from_date + '1D';
        }
    }
    else {
        die 'unknown group_by_period';
    }

    my @user_categories = map { $_->{id} }
      Baseliner::Model::Topic->new->get_categories_permissions( username => $username, type => 'view' );
    if ( @$categories ) {
        my @categories_ids = _array($categories);
        @user_categories = intersect( @categories_ids, @user_categories );
    }

    my $perm = Baseliner::Model::Permissions->new;

    my $is_root = $perm->is_root($username);
    if ( $username && !$is_root ) {
        $perm->build_project_security( $where, $username, $is_root, @user_categories );
    }

    my @closed_status = map { $_->{name} } ci->status->find( { type => qr/^F|FC$/ } )->all;

    my @backlog_remaining = map { $_->{mid} } mdb->topic->find(
        {
            'category.id'          => mdb->in(@user_categories),
            'category_status.name' => mdb->nin(@closed_status),
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
            'vars.status' => mdb->in(@closed_status),
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
                    'vars.status' => mdb->in(@closed_status),
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
            { '$group' => { _id => $group_by, total => { '$sum' => 1 } } }
        ]
    );

    $self->_update_burndown( $created_topics_aggr[0], \%burndown, 1 );
    $self->_update_burndown( $closed_topics_aggr[0],  \%burndown, -1 );

    return [
        map { [ $_, $burndown{$_} ] }
        sort { $a cmp $b } keys %burndown
    ];
}

sub _update_burndown {
    my $self = shift;
    my ( $topics, $burndown, $sign ) = @_;

    foreach my $topic (@$topics) {
        my $from  = $topic->{_id};
        my $total = $topic->{total};

        foreach my $by ( sort { $a cmp $b } keys %$burndown ) {
            #$by = sprintf( '%02d', $by );

            next if $by lt $from;

            $burndown->{$by} += $total * $sign;
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
