package BaselinerX::Reports::estadisticas_jobs_semana;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use utf8;

register 'config.reports.estadisticas_jobs_semana' => {
    metadata=> [
        { id=>'user_list', label => 'Usuarios que ven el informe (lista separada por comas)', default => 'root', type=>'text', width=>200 },
    ],
};

register 'report.clarive.job_statistics_semana' => {
    name => 'Weekly Job Stats', 
    data => { },
    form => '/reports/listado_jobs.js', 
    security_handler => sub{
        my ($self,$username) =@_;
        my $config = config_get 'config.reports.estadisticas_jobs_semana';
        my @user_list = split /,/, $config->{user_list};

        return $username ~~ @user_list;
        #return $username =~ /(root|asalinaa|sdiaram|ricardo)/;  # or a 0 for no access
    },
    meta_handler => sub {
        my ( $self, $config ) = @_;
        return {
            fields => {
                ids => [
                    'semana', 'fallidos', 'pct_fallidos','correctos','pct_correctos','avg_exec',
                    'total'
                ],
                columns => [
                    {id => 'semana',  text => 'Semana'},
                    {id => 'fallidos',     text => 'Fallidos'},
                    {id => 'pct_fallidos',     text => '%Fallidos'},
                    {id => 'correctos',    text => 'Correctos'},
                    {id => 'pct_correctos',     text => '%Correctos'},
                    {id => 'avg_exec',     text => 'AVG ejecuciones'},
                    {id => 'total', text => 'Total'}
                ],
            },
            report_name => _loc('Weekly Job Stats'),
            report_type => 'custom',
            # report_rows => 100,
            hide_tree => \1,
        };
    },
    data_handler => sub{
        my ($self,$config, $p) = @_;


        my $username = $p->{username};
        my ($start,$limit,$sort,$dir,$query)=@{$p}{qw(start limit sort dir query)};

        # Condiciones fijas del informe
        my $where = { collection => 'job' };

        # Condiciones por defecto cuando no hay configuración guardada
        my $dt = Class::Date->now();
        if ( !$config ) {

        } else {
          $p = $config;
        };

        # Condiciones customizables
        if ( $p->{chk_inicio} eq 1 ) {
          $where->{starttime} = {
              '$ne'  => undef,
              '$nin' => [ '' ],
          };              
          if ( $p->{fecha_inicio_hasta} ) {
              $where->{starttime}->{'$lte'} = $p->{fecha_inicio_hasta};
          }
          if ( $p->{fecha_inicio_desde} ) {
              $where->{starttime}->{'$gte'} = $p->{fecha_inicio_desde};
          }
        };

        if ( $p->{chk_bl} eq 1 ) {
          $where->{bl} = mdb->in( [_array $p->{bl}] )
        };

        if ( $p->{chk_fin} eq 1 ) {
          $where->{endtime} = {
              '$ne'  => undef,
              '$nin' => [ '' ],
          };
          if ( $p->{fecha_fin_hasta} ) {
              $where->{endtime}->{'$lte'} = $p->{fecha_fin_hasta};
          }
          if ( $p->{fecha_fin_desde} ) {
              $where->{endtime}->{'$gte'} = $p->{fecha_fin_desde};
          }
        };

        if ( $p->{chk_projects} eq 1 ) {
          if ( $p->{chk_projects_and} eq 1 ) {
              my @ands;
              for my $project ( _array $p->{projects} ) {
                push @ands, {projects => mdb->in([$project])};
              }
              $where->{'$and'} = \@ands;
            } else {
              $where->{projects} = mdb->in( [_array $p->{projects}] )
            }
        };

        if ( $p->{chk_natures} eq 1 ) {
          if ( $p->{chk_natures_and} eq 1 ) {
              my @ands;
              for my $nature ( _array $p->{natures} ) {
                push @ands, {natures => mdb->in([$nature])};
              }
              $where->{'$and'} = \@ands;
            } else {
              $where->{natures} = mdb->in( [_array $p->{natures}] )
            }
        };

        if ( $p->{chk_users} eq 1 ) {
            my @usernames = map {$_->{name}} BaselinerX::CI::user->search_cis( mid => mdb->in(_array $p->{users}));
            $where->{username} = mdb->in( @usernames )
        };

        if ( $p->{chk_states} eq 1 ) {
            $where->{status} = mdb->in( _array $p->{states} )
        };

        if ( $p->{chk_releases} eq 1 ) {
          if ( $p->{chk_releases_and} eq 1 ) {
              my @ands;
              for my $release ( _array $p->{releases} ) {
                push @ands, {releases => mdb->in([$release])};
              }
              $where->{'$and'} = \@ands;
            } else {
              $where->{releases} = mdb->in( [_array $p->{releases}] )
            }
        };

        _warn $where;
        my @rows;
        # Baseliner->model('Topic')->build_field_query( $query, $where, $username ) if length $query;
        # Baseliner->model('Topic')->build_project_security( $where, $username );

        my @docs = _array(
            mdb->master_doc->aggregate(
                [
                    {'$match' => $where},
                    {
                        '$group' => {
                            _id    => { '$substr' => [ '$starttime',0,7] },
                            'fail' => {
                                '$sum' => {
                                    '$cond' => [
                                        {
                                            '$or' => [
                                                {'$eq' => [ '$status', 'CANCELLED' ]},
                                                {'$eq' => [ '$status', 'ERROR' ]},
                                                {'$eq' => [ '$status', 'EXPIRED' ]},
                                                {'$eq' => [ '$status', 'KILLED' ]},
                                                {'$eq' => [ '$status', 'REJECTED' ]},
                                                {'$eq' => [ '$status', 'ROLLBACKFAIL' ]},
                                                {'$eq' => [ '$status', 'ROLLEDBACK' ]}
                                            ]
                                        },
                                        1, 0
                                    ]
                                }
                            },
                            'success' => {
                                '$sum' =>
                                    {'$cond' => [ {'$eq' => [ '$status', 'FINISHED' ]}, 1, 0 ]}
                            },
                            'exec' => {
                                '$sum' => '$exec'
                            },

                            'total' => {'$sum' => 1}
                        }
                    },
                    {'$sort' => {total => -1}}
                ]
            )
        );

        my $meses = {
            '01' => 'Enero',
            '02' => 'Febrero',
            '03' => 'Marzo',
            '04' => 'Abril',
            '05' => 'Mayo',
            '06' => 'Junio',
            '07' => 'Julio',
            '08' => 'Agosto',
            '09' => 'Septiembre',
            '10' => 'Octubre',
            '11' => 'Noviembre',
            '12' => 'Diciembre'
        };
        for my $d (@docs) {
            my ($anyo,$mes) = $d->{_id} =~ /^(.*?)-(.*)$/;
            push @rows,
              {
                mes      => $anyo." ".$meses->{$mes},
                fallidos      => $d->{fail},
                pct_fallidos  => $d->{fail}/$d->{total}*100,
                correctos         => $d->{success},
                pct_correctos  => $d->{success}/$d->{total}*100,
                avg_exec => $d->{exec},
                total       => $d->{total}
              };
        }

        my $cnt = scalar @rows;
        return {
            rows=>\@rows, total=>$cnt, config=>$config,
        };
    }
};

1;
