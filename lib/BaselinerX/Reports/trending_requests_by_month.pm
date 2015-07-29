package BaselinerX::Reports::trending_requests_by_month;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use utf8;
use experimental 'smartmatch';

register 'config.reports.trending_requests_by_month' => {
    metadata=> [
        { id=>'user_list', label => 'Usuarios que ven el informe (lista separada por comas)', default => 'root', type=>'text', width=>200 },
    ],
};

register 'report.clarive.trending_requests_by_month' => {
    name => 'TRENDING: Requests by month', 
    data => { },
    form => '/reports/trending.js', 
    security_handler => sub{
        my ($self,$username) =@_;
        my $config = config_get 'config.reports.trending_requests_by_month';
        my @user_list = split /,/, $config->{user_list};

        return $username ~~ @user_list;
        #return $username =~ /(root|asalinaa|sdiaram|ricardo)/;  # or a 0 for no access
    },
    meta_handler => sub {
        my ( $self, $config ) = @_;
        return {
            fields => {
                ids => [
                    'month', 'new','closed','cancelled'
                ],
                columns => [
                    {id => 'month',  text => _loc('Month')},
                    {id => 'new',     text => _loc('New')},
                    {id => 'closed',     text => _loc('Closed')},
                    {id => 'cancelled',     text => _loc('Cancelled')}
                ],
            },
            report_name => _loc('Monthly request trend'),
            report_type => 'custom',
            # report_rows => 100,
            hide_tree => \1,
        };
    },
    data_handler => sub{
        my ($self,$config, $p) = @_;


        my $username = $p->{username};
        my ($start,$limit,$sort,$dir,$query)=@{$p}{qw(start limit sort dir query)};

        # Condiciones por defecto cuando no hay configuración guardada
        my $dt = Class::Date->now();
        if ( !$config ) {

        } else {
          $p = $config;
        };

        my @close_status = map { $_->{name}} ci->status->find({ type => 'F'})->all;
        my @cancel_status = map { $_->{name}} ci->status->find({ type => 'FC'})->all;

        my $where = {'event_key' => 'event.topic.create'};
        my $where_closed = { 'vars.status' => mdb->in(@close_status), 'event_key' => 'event.topic.change_status'};
        my $where_cancelled = { 'vars.status' => mdb->in(@cancel_status), 'event_key' => 'event.topic.change_status'};

        # Condiciones customizables
        if ( $p->{cb_date} eq 1 ) {
          if ( $p->{to_date} ) {
              $where->{ts}->{'$lte'} = $p->{to_date};
              $where_closed->{ts}->{'$lte'} = $p->{to_date};
              $where_cancelled->{ts}->{'$lte'} = $p->{to_date};
          }
          if ( $p->{from_date} ) {
              $where->{ts}->{'$gte'} = $p->{from_date};
              $where_closed->{ts}->{'$gte'} = $p->{from_date};
              $where_cancelled->{ts}->{'$gte'} = $p->{from_date};
          }
        };

        if ( $p->{chk_categories} eq 1 ) {
          my @mids = map {$_->{mid}} mdb->topic->find({'category.id' => mdb->in(_array($p->{categories}))})->fields({ _id=>0,mid=>1})->all;
          $where->{mid} = mdb->in(@mids);
          $where_closed->{mid} = mdb->in(@mids);
          $where_cancelled->{mid} = mdb->in(@mids);
        };

        if ( $p->{chk_users} eq 1 ) {
            my @usernames = map {$_->{name}} BaselinerX::CI::user->search_cis( mid => mdb->in(_array $p->{users}));
            $where->{username} = mdb->in( @usernames );
            $where_closed->{username} = mdb->in( @usernames );
            $where_cancelled->{username} = mdb->in( @usernames );
        };

        my @new = _array(
            mdb->activity->aggregate(
                [
                    {'$match' => $where},
                    {
                        '$group' => {
                            _id    => { '$substr' => [ '$ts',0,7] },
                            'total' => {'$sum' => 1}
                        }
                    },
                    {'$sort' => {total => -1}}
                ]
            )
        );

        my @closed = _array(
                    mdb->activity->aggregate(
                        [
                            {'$match' => $where_closed},
                            {
                                '$group' => {
                                    _id    => { '$substr' => [ '$ts',0,7] },
                                    'total' => {'$sum' => 1}
                                }
                            },
                            {'$sort' => {total => -1}}
                        ]
                    )
                );

        my @cancelled = _array(
                    mdb->activity->aggregate(
                        [
                            {'$match' => $where_cancelled},
                            {
                                '$group' => {
                                    _id    => { '$substr' => [ '$ts',0,7] },
                                    'total' => {'$sum' => 1}
                                }
                            },
                            {'$sort' => {total => -1}}
                        ]
                    )
                );
        my $result = {};

        for (@new) {
            $result->{$_->{_id}}->{new} = $_->{total};
        }

        for (@closed) {
            $result->{$_->{_id}}->{closed} = $_->{total};
        }

        for (@cancelled) {
            $result->{$_->{_id}}->{cancelled} = $_->{total};
        }


        my $months = {
            '01' => 'January',
            '02' => 'February',
            '03' => 'March',
            '04' => 'April',
            '05' => 'May',
            '06' => 'June',
            '07' => 'July',
            '08' => 'August',
            '09' => 'September',
            '10' => 'October',
            '11' => 'November',
            '12' => 'December'
        };
        my @rows;
        for my $key (keys %$result) {
            my ($year,$month) = $key =~ /^(.*?)-(.*)$/;

            push @rows,
              {
                month      => $year." "._loc($months->{$month}),
                new        => $result->{$key}->{new} ? 0+$result->{$key}->{new}:0,
                closed        => $result->{$key}->{closed} ? 0+$result->{$key}->{closed}:0,
                cancelled        => $result->{$key}->{cancelled}?0+$result->{$key}->{cancelled}:0,
              };
        }

        if ( $sort ) {
            if ( $dir && $dir eq '1' ) {
                @rows = sort { _log $a->{$sort} . " " .$b->{$sort};$a->{$sort} <=> $b->{$sort} } @rows;
            } else {
                @rows = sort { _log $a->{$sort} . " " .$b->{$sort};$b->{$sort} <=> $a->{$sort} } @rows;
            }
        } else {
            @rows = sort { _log $b->{new} . " " .$a->{new};$b->{new} <=> $a->{new} } @rows;
        }

        my $cnt = scalar @rows;
        return {
            rows=>\@rows, total=>$cnt, config=>$config
        };
    }
};

1;
