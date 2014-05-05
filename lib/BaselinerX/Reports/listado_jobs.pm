package BaselinerX::Reports::listado_jobs;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use utf8;

register 'config.reports.listado_jobs' => {
    metadata=> [
        { id=>'user_list', label => 'Usuarios que ven el informe (lista separada por comas)', default => 'root', type=>'text', width=>200 },
    ],
};

register 'report.jazztel.jobs' => {
    name => 'Listado de JOBS',
    data => { },
    form => '/reports/listado_jobs.js', 
    security_handler => sub{
        my ($self,$username) =@_;
        my $config = config_get 'config.reports.listado_jobs';
        my @user_list = split /,/, $config->{user_list};

        return $username ~~ @user_list;
        #return $username =~ /(root|asalinaa|sdiaram|ricardo)/;  # or a 0 for no access
    },
    meta_handler => sub {
        my ( $self, $config ) = @_;
        return {
            fields => {
                ids => [
                    'job_id','nombre_job',  'nombre_job', 'cambios', 'bl', 'sistemas',
                    'naturalezas', 'releases',   'inicio',  'fin', 'pre_inicio',  'pre_fin', 'run_inicio',  'run_fin',
                    'usuario',     'estado',     {name => 'ejecuciones', type => 'int', sortType => 'asInt'}
                ],
                columns => [
                    {id => 'job_id', text => 'JOB ID', meta_type => 'job_ID'},
                    {id => 'nombre_job',  text => 'Nombre'},
                    {id => 'cambios',     text => 'Cambios'},
                    {id => 'bl',     text => 'Entorno'},
                    {id => 'sistemas',    text => 'Sistemas'},
                    {id => 'naturalezas', text => 'Naturalezas'},
                    {id => 'releases',    text => 'Releases'},
                    {id => 'inicio',      text => 'Inicio', meta_type => 'date', sortable => \1},
                    {id => 'fin',         text => 'Fin', meta_type => 'date', sortable => \1},
                    {id => 'pre_inicio',      text => 'PRE Inicio', meta_type => 'date', sortable => \1},
                    {id => 'pre_fin',         text => 'PRE Fin', meta_type => 'date', sortable => \1},
                    {id => 'run_inicio',      text => 'RUN Inicio', meta_type => 'date', sortable => \1},
                    {id => 'run_fin',         text => 'RUN Fin', meta_type => 'date', sortable => \1},
                    {id => 'usuario',     text => 'Usuario'},
                    {id => 'estado',      text => 'Estado'},
                    {id => 'ejecuciones', text => 'Ejecuciones', meta_type => 'number'}
                ],
            },
            report_name => 'Listado de JOBS',
            report_type => 'jobs',
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

        if ( $p->{chk_bl} eq 1 ) {
          $where->{bl} = mdb->in( [_array $p->{bl}] )
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
        Baseliner->model('Jobs')->build_field_query( $query, $where, $username ) if length $query;
        # Baseliner->model('Topic')->build_project_security( $where, $username );

        my $rs  = mdb->master_doc->find($where);
        my $cnt = $rs->count;
        $start = 0 if length $start && $start >= $cnt;    # reset paging if offset
        $rs->skip($start)  if length $start;
        $rs->limit($limit) if $limit ne -1;
        $rs->sort( $sort ? $sort : { start_time => 1 } );

        my @docs = $rs->all;

        my %cis = map {
            map { $_ => undef }
              grep { $_ }
              _array( $_->{changesets}, $_->{projects}, $_->{natures}, $_->{releases} )
        } @docs;
        map { $cis{ $_->{mid} } = $_ }
          mdb->master_doc->find( { mid => mdb->in( keys %cis ) } )->all;

        for my $d (@docs) {
            my $sis = [
                grep { defined }
                map { my $r = $cis{$_}; $r->{name} if $r } _array( $d->{projects} )
            ];
            my $cambios = [
                grep { defined }
                map { my $r = $cis{$_}; $r->{name} if $r } _array( $d->{changesets} )
            ];
            my $natures = [
                grep { defined }
                map { my $r = $cis{$_}; $r->{name} if $r } _array( $d->{natures} )
            ];
            my $releases = [
                grep { defined }
                map { my $r = $cis{$_}; $r->{name} if $r } _array( $d->{releases} )
            ];

            my ($last_exec) = sort { $b cmp $a } keys %{$$d{milestones}};

            push @rows,
              {
                job_id => $$d{mid},
                nombre_job      => $$d{name},
                cambios     => $cambios,
                bl => $$d{bl},
                sistemas    => $sis,
                naturalezas => $natures,
                releases    => $releases,
                inicio      => $$d{starttime},
                fin         => $$d{endtime},
                pre_inicio      => $last_exec?$$d{milestones}->{$last_exec}->{PRE}->{start} || " ":" ",
                pre_fin         => $last_exec?$$d{milestones}->{$last_exec}->{PRE}->{end}|| " ":" ",
                run_inicio      => $last_exec?$$d{milestones}->{$last_exec}->{RUN}->{start}|| " ":" ",
                run_fin         => $last_exec?$$d{milestones}->{$last_exec}->{RUN}->{end}|| " ":" ",
                usuario     => $$d{username},
                estado      => _loc( $$d{status} ),
                ejecuciones => $$d{exec}
              };
        }
        return {
            rows=>\@rows, total=>$cnt, config=>$config,
        };
    },
};

1;
