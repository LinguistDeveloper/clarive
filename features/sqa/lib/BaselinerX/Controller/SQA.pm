package BaselinerX::Controller::SQA;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Controller' }
use Baseliner::Utils;
use BaselinerX::Model::SQA;
use BaselinerX::Comm::Balix;
use Baseliner::Core::DBI;
use Try::Tiny;

register 'menu.job.sqa' => {
    label    => _loc( 'Quality portal' ),
    url_comp => '/sqa/grid',
    title    => _loc( 'Quality portal' ),
    action   => 'action.sqa.view'
};

my @filters = ( 'J2EE', '.NET', 'ORACLE', 'FICHEROS', 'BIZTALK', 'ECLIPSE' );

sub grid : Local {
    my ( $self, $c ) = @_;
    my $config;

    if ( $c->model( 'Permissions' )->user_has_action( username => $c->username, action => 'action.sqa.view' ) )
    {
    	my @actions = $c->model('Permissions')->list( username => $c->username ) ;
		my %user_actions;
		@user_actions{ @actions }=();
		   
        $c->stash->{action_view_general} = exists $user_actions{ 'action.sqa.general' } ;
        $c->stash->{action_request_analysis} = exists $user_actions{ 'action.sqa.request_analysis' };
        $c->stash->{action_new_analysis} = exists $user_actions{ 'action.sqa.new_analysis' } ;
        $c->stash->{action_project_config} = exists $user_actions{ 'action.sqa.project_config' } ;
        $c->stash->{action_global_config} = exists $user_actions{ 'action.sqa.global_config' } ;
        $c->stash->{action_request_recalc} = exists $user_actions{ 'action.sqa.request_recalc' } ;
        $c->stash->{action_sqa_config} = exists $user_actions{ 'action.sqa.config' } ;
        $c->stash->{action_sqa_project} = exists $user_actions{ 'action.sqa.project' } ;
        $c->stash->{action_sqa_subproject} = exists $user_actions{ 'action.sqa.subproject' } ;
        $c->stash->{action_sqa_subprojectnature} = exists $user_actions{ 'action.sqa.subprojectnature' } ;
        $c->stash->{action_sqa_packages} = exists $user_actions{ 'action.sqa.packages' } ;
        $c->stash->{action_delete_analysis} = exists $user_actions{ 'action.sqa.delete_analysis' } ;
        $c->stash->{action_schedule_analysis} = exists $user_actions{ 'action.sqa.schedule_analysis' } ;

        $config = $c->model( 'ConfigStore' )->get( 'config.sqa', bl => 'TEST', ns => '/' );
        $c->stash->{global_run_sqa_test}          = $config->{run_sqa};
        $c->stash->{global_block_deployment_test} = $config->{block_deployment};

        $config = $c->model( 'ConfigStore' )->get( 'config.sqa', bl => 'ANTE', ns => '/' );
        $c->stash->{global_run_sqa_ante}          = $config->{run_sqa};
        $c->stash->{global_block_deployment_ante} = $config->{block_deployment};

        $config = $c->model( 'ConfigStore' )->get( 'config.sqa', bl => 'PROD', ns => '/' );
        $c->stash->{global_run_sqa_prod}          = $config->{run_sqa};
        $c->stash->{global_block_deployment_prod} = $config->{block_deployment};
        
        $config = $c->model( 'ConfigStore' )->get( 'config.sqa' );
        $c->stash->{sqa_url} = $config->{url_checking};
        $c->stash->{scm_url} = $config->{url_scm};

        $c->stash->{template} = '/comp/sqa/grid.js';
    } else {

        $c->stash->{json} = {
            success => \0,
            msg     => _loc( "The user %1 doesn't have permission to use SQA portal", $c->username )
        };
        $c->forward( "View::JSON" );
    }
}

sub grid_raw : Local {
    my ( $self, $c ) = @_;
    $c->stash->{site_raw} = 1;
    $c->forward( '/sqa/grid' );
}

sub grid_json : Local {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $username = $c->username;
    my ( $start, $limit, $query, $dir, $sort, $query_status, $type, $groupBy, $groupDir, $cnt ) =
        ( '', '', '', '', '', '', '', '' );

    # sent by ExtJS
    ( $start, $limit, $query, $dir, $sort, $query_status, $type, $groupBy, $groupDir ) =
        @{$p}{qw/start limit query dir sort query_status type groupBy groupDir/};
    $start ||= 0;
    $limit ||= 25;

    my $page = to_pages( start => $start, limit => $limit );
    my ( $post_sort, $post_sort_type ) = ( '', '' );
    if ( $sort =~ /subapp|project|qualification/i ) {
        $post_sort      = $sort;
        $post_sort_type = 'num' if $sort =~ /qualifi/;
        $sort           = '';
    } elsif ( $sort =~ /result/ ) {
        $sort = 'status';
    }

    my $where = {};
    my $args;


    #$query and

    if ( $type && $type =~ /^CFG/ ) {
        $query and $where = query_sql_build(
            query  => $query,
            fields => {
                cam     => 'me.project_name',
                project => 'me.sp_name',
                nature  => 'me.nature'
            }
        );
    } else {
        $query and $where = query_sql_build(
            query  => $query,
            fields => {
                cam           => 'me.ns',
                bl            => 'me.bl',
                nature        => 'me.nature',
                project       => 'project.name',
                status        => 'me.status',
                start         => "to_char(me.tsstart,'DD/MM/YYYY HH24:MI:SS')",
                end           => "to_char(me.tsend,'DD/MM/YYYY HH24:MI:SS')",
                qualification => 'me.qualification'
            }
        );
        $where->{'me.status'} = $query_status if $query_status;
    }

    my $table = 'Baseliner::BaliSqa';

	if ( $type && $type =~ /CFGNAT/ ) {
        $table = 'Baseliner::BaliProjectNatureConfig';
        $args = {page => $page, rows => $limit};
        $args->{order_by} = $sort ? "$sort $dir" : 'project_name asc';
        $groupBy eq 'project' and $groupBy = '';
    } elsif ( $type && $type =~ /^CFG/ ) {
        $table = 'Baseliner::BaliProjectTree';
        $args = {page => $page, rows => $limit};
        $args->{order_by} = $sort ? "$sort $dir" : 'project_name asc';
        $groupBy eq 'project' and $groupBy = 'project_name';
    } elsif ( $type ) {
        $where->{'me.type'} = {'=' => $type};
        $args = {join => [ 'project' ], page => $page, rows => $limit};
        $args->{order_by} = $sort ? "$sort $dir" : 'me.ns asc';
        $groupBy eq 'project' and $groupBy = 'me.ns';
    } else {
        $where->{'me.type'} = {'<>' => 'PKG'};
        $args = {join => [ 'project' ], page => $page, rows => $limit};
        $args->{order_by} = $sort ? "$sort $dir" : 'me.ns asc';
        $groupBy eq 'project' and $groupBy = 'me.ns';
    }
    $groupBy and $args->{order_by} = "$groupBy $groupDir, " . $args->{order_by};

    my $projects;

    if ( $type && $type =~ /^CFG/ ) {
        $where->{'me.id'} = $c->model( 'Permissions' )->user_projects_with_action(
            username => $c->username,
            action   => 'action.sqa.view_project'
        );
        if ( $type eq 'CFGSNA' ) {
            $where->{'me.tree_level'} = 'NAT';
        } elsif ( $type eq 'CFGSUB' ) {
            $where->{'me.tree_level'} = 'SUB';
        } elsif ( $type =~ /CFGCAM|CFGNAT/ ) {
            $where->{'me.tree_level'} = 'CAM';
        }
    } elsif ( $type && $type =~ /PKG/ ) {
        $where->{'me.id_prj'} = $c->model( 'Permissions' )->user_projects_with_action(
            username => $c->username,
            action   => 'action.sqa.packages'
        );
    } else {
        $where->{'me.id_prj'} = $c->model( 'Permissions' )->user_projects_with_action(
            username => $c->username,
            action   => 'action.sqa.view_project'
        );
    }

    my @data;
    my $rs = Baseliner->model( $table )->search( $where, $args );
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;
    #_log _dump $rs->as_query;
    _log "************** ARGUMENTOS: " . _dump $args;

    my $run_sqa_test          = '';
    my $run_sqa_ante          = '';
    my $run_sqa_prod          = '';
    my $block_deployment_test = '';
    my $block_deployment_ante = '';
    my $block_deployment_prod = '';

    _log "************************* Filtros: ".join ',',@filters;

    #rs_hashref( $rs );
    while ( my $row = $rs->next ) {

        if ( $type && $type =~ /^CFG/ ) {
            my $project_name;
            my $row_type;
            my $subproject;
            my $nature;

            #### OPTIMIZACI?N ACCESOS

            $run_sqa_test          = '';
            $run_sqa_ante          = '';
            $run_sqa_prod          = '';
            $block_deployment_test = '';
            $block_deployment_ante = '';
            $block_deployment_prod = '';


            my $ns;

            if ( $type eq 'CFGNAT' ) {


                    #### OPTIMIZACI?N ACCESOS FIN


                    $project_name = $row->project_name;
                    $row_type     = 'CAM';
                    $subproject   = ' ';

                    push @data,
                        {
                        id                    => $row->nature . "/" . $row->id,
                        project               => $project_name,
                        nature                => $row->nature,
                        type                  => $row_type,
                        subapp                => $subproject,
                        run_sqa_test          => $row->run_sqa_test,
                        run_sqa_ante          => $row->run_sqa_ante,
                        run_sqa_prod          => $row->run_sqa_prod,
                        id_project            => $row->id,
                        block_deployment_test => $row->block_deployment_test,
                        block_deployment_ante => $row->block_deployment_ante,
                        block_deployment_prod => $row->block_deployment_prod
                        };
                    _log '********************** REGISTRO AÑADIDO';
            } else {
                $ns = 'project/' . $row->id;


                my $rs_config =
                    Baseliner->model( 'Baseliner::BaliConfig' )
                    ->search(
                    {ns => $ns, key => [ 'config.sqa.run_sqa', 'config.sqa.block_deployment' ]} );

                while ( my $row_config = $rs_config->next ) {

                    if ( $row_config->bl eq 'TEST' ) {
                        if ( $row_config->key eq 'config.sqa.run_sqa' ) {
                            $run_sqa_test = $row_config->value;
                        } else {
                            $block_deployment_test = $row_config->value;
                        }
                    } elsif ( $row_config->bl eq 'ANTE' ) {
                        if ( $row_config->key eq 'config.sqa.run_sqa' ) {
                            $run_sqa_ante = $row_config->value;
                        } else {
                            $block_deployment_ante = $row_config->value;
                        }
                    } elsif ( $row_config->bl eq 'PROD' ) {
                        if ( $row_config->key eq 'config.sqa.run_sqa' ) {
                            $run_sqa_prod = $row_config->value;
                        } else {
                            $block_deployment_prod = $row_config->value;
                        }
                    }
                }

                #### OPTIMIZACI?N ACCESOS FIN


                if ( $row->tree_level eq 'CAM' ) {
                    $project_name = $row->project_name;
                    $row_type     = 'CAM';
                    $subproject   = ' ';
                    $nature       = ' ';

                } elsif ( $row->tree_level eq 'SUB' ) {
                    $project_name = $row->project_name;
                    $row_type     = 'SUB';
                    $subproject   = $row->sp_name;
                    $nature       = ' ';
                } else {
                    $project_name = $row->project_name;
                    $row_type     = 'NAT';
                    $subproject   = $row->spn_name;
                    $nature       = $row->nature;
                }
                push @data,
                    {
                    id                    => $row->id,
                    project               => $project_name,
                    nature                => $nature,
                    type                  => $row_type,
                    subapp                => $subproject,
                    run_sqa_test          => $run_sqa_test,
                    run_sqa_ante          => $run_sqa_ante,
                    run_sqa_prod          => $run_sqa_prod,
                    id_project            => $row->id,
                    block_deployment_test => $block_deployment_test,
                    block_deployment_ante => $block_deployment_ante,
                    block_deployment_prod => $block_deployment_prod
                    };
            }
        } else {
            if ( $row->type && $row->type eq 'PKG' ) {

                ## Cargamos los links a los informes
                my $clobdata  = _load( $row->data ) if $row->data;
                my $links     = $clobdata->{URLS};
                my $linksHTML = "";

                foreach my $link ( keys %{$links} ) {
                    $linksHTML .=
                        "<li><b><A HREF='$links->{$link}' TARGET='_BLANK'>$link</b></A></li>";
                }

                ## Cargamos la lista de paquetes

                #_log $clobdata->{version}?"VERSION: $clobdata->{version}":"VERSION: null";
                my @packages     = {};
                my $packagesHTML = "";

                if ( $clobdata->{PACKAGES} ) {
                    @packages = _array $clobdata->{PACKAGES};

                    foreach my $package ( @packages ) {
                        $packagesHTML .= "<li>$package</li>";
                    }
                }

                push @data,
                    {
                    id      => $row->id,
                    bl      => $row->bl,
                    project => $row->ns,
                    result  => $row->status,
                    status  => $row->status,
                    tsstart => defined $row->tsstart
                    ? $row->tsstart->dmy( '/' ) . ' ' . $row->tsstart->hms
                    : '',
                    tsend => defined $row->tsend ? $row->tsend->dmy( '/' ) . ' ' . $row->tsend->hms
                    : '',
                    type     => $row->type,
                    links    => $linksHTML,
                    packages => $packagesHTML,
                    id_project      => $row->id_prj
                    };

            } else {
                my $sub_project;
                my $prj_name;
                if ( $row->type ne 'CAM' ) {
                    $sub_project = $row->project->name;
                } else {
                    $sub_project = '';
                }
                $prj_name = $row->ns;
                my $clobdata = _load( $row->data ) if $row->data;

                #use Data::Dumper;
                #warn Dumper $row;

                #my $global_hash = {};
                my $indicadores = '';

                #_log $clobdata->{version}?"VERSION: $clobdata->{version}":"VERSION: null";

                if ( $clobdata->{version} && $clobdata->{version} eq "1.0" ) {

                    #_log "Versi?n antigua";
                    for ( keys %{$clobdata->{indicadores}} ) {
                        $indicadores .= "<li><b>$_:</b> $clobdata->{indicadores}->{$_}</li>"
                            if $_ ne "GLOBAL";
                    }
                } else {

                    #_log "Versi?n nueva";
                    for my $linea ( _array $clobdata->{scores} ) {

                        #$linea =~ s/\"| |\n|.$//g;

                        my ( $indicador, $valor ) = split ":", $linea;

                        #$valor= sprintf("%.2f", $valor);
                        #$global_hash->{ $indicador } = $valor;
                        $indicadores .= "<li><b>$indicador:</b> $valor</li>"
                            if $indicador ne "GLOBAL";
                    }
                }

                my $trend = "?";
                if ( $clobdata->{prev_qualification} ) {
                    my $prev = $clobdata->{prev_qualification};
                    my $curr = $row->qualification;

                    $trend = $curr - $prev;

                    if ( $trend > 0 ) {
                        _log "Up: $trend";
                        $trend = '1';
                    } elsif ( $trend == 0 ) {
                        _log "Same: $trend";
                        $trend = '0';
                    } else {
                        _log "Down: $trend";
                        $trend = '-1';
                    }
                }

                push @data, {
                    id            => $row->id,
                    bl            => $row->bl,
                    project       => $prj_name,
                    result        => $row->status,
                    status        => $row->status,
                    global        => $indicadores,
                    subapp        => $sub_project || '',
                    qualification => $row->qualification,
                    nature        => $row->nature || '',
                    has_html      => $clobdata->{html} ? 1 : 0,
                    tsstart       => defined $row->tsstart
                    ? $row->tsstart->dmy( '/' ) . ' ' . $row->tsstart->hms
                    : '',
                    tsend => defined $row->tsend ? $row->tsend->dmy( '/' ) . ' ' . $row->tsend->hms
                    : '',

                    #actions => $clobdata->{actions},
                    #actions => { html=>\1 },
                    id_project      => $row->id_prj,
                    type            => $row->type,
                    tests_errors    => $clobdata->{tests_errores},
                    tests_coverture => $clobdata->{tests_cobertura},
                    url_errors      => $clobdata->{url_errores},
                    url_coverture   => $clobdata->{url_cobertura},
                    trend           => $trend
                };
            }
        }
    }

    #_log _dump [ map { [ $_->{project},$_->{tsstart}, $_->{tsend} ] } @data ];
    @data = sort {
        $dir eq 'ASC'
            ? ( $post_sort_type eq 'num'
            ? $a->{$post_sort} <=> $b->{$post_sort}
            : lc $a->{$post_sort} cmp lc $b->{$post_sort} )
            : ( $post_sort_type eq 'num'
            ? $b->{$post_sort} <=> $a->{$post_sort}
            : lc $b->{$post_sort} cmp lc $a->{$post_sort} )
    } @data if $post_sort;

    #_log _dump \@data;
    $c->stash->{json} = {
        totalCount => $cnt,
        data       => \@data,
        gridType   => $type
    };
    $c->forward( 'View::JSON' );
}

sub view_html : Local {
    my ( $self, $c, $id ) = @_;
    my $row  = $c->model( 'Baseliner::BaliSqa' )->find( $id );
    my $data = _load $row->data if $row->data;
    my $html = $data->{html};

    $c->res->body( $html );
}

=head2 run_request_results_start

Puts the row in running mode.

=cut

sub run_request_results : Local {
    my ( $self, $c ) = @_;
    my $ns = $c->request->params->{ns};
    _log "Starting request...";

# ant -f getReport.xml -Dentorno=ANTE -DCAM=IAS -Dsubapp=IAS -Dplugin=auditrep -DreportName=auditrep.xml -DlocalReport.dir=.
    my ( $rc, $ret, $xml );
    try {
        my $config = Baseliner->model( 'ConfigStore' )->get( 'config.sqa' );

        my ( $domain, $bl, $cam, $subapp ) = split /\//, $ns;

        # XML
        my $bx = BaselinerX::Comm::Balix->new(
            host => $config->{server},
            port => $config->{port},
            key  => $config->{key}
        );
        die _loc( "Could not connect to sqa server %1:%2", $config->{server}, $config->{port} )
            . "\n"
            unless ref $bx;
        ( $rc, $ret ) = $bx->execute(
            qq{cd /D $config->{script_dir} & ant -f $config->{script_name} -Dentorno=$bl -DCAM=$cam -Dsubapp=$subapp -Dplugin=$config->{plugin} -DreportName=$config->{file} -DlocalReport.dir=$config->{dir} }
        );
        ( $rc, $xml ) = $bx->execute( qq{type $config->{dir}\\$config->{file}} );

        _log "Done xml request...";
        my $x    = XML::Simple->new;
        my $data = $x->XMLin( $xml );

        my $result = $data->{result};

        my $ts     = $data->{timestamp};
        my $global = $data->{category}{'indicadores globales'}{checkpoint}{violation};

        Baseliner->model( 'Repository' )->set(
            ns   => $ns,
            data => {status => 'ok', result => $result, ts => $ts, global => $global}
        );

# HTML
#my $html;
#$bx = BaselinerX::Comm::Balix->new( host=>$config->{server}, port=>$config->{port}, key=>$config->{key} );
#($rc, $ret) = $bx->execute( qq{cd /D $config->{script_dir} & ant -f $config->{script_name} -Dentorno=$bl -DCAM=$cam -Dsubapp=$subapp -Dplugin=$config->{plugin} -DreportName=$config->{file_html} -DlocalReport.dir=$config->{dir} } );
#($rc,$html) = $bx->execute( qq{type $config->{dir}\\$config->{file_html}} );

#Baseliner->model('Repository')->set( ns=>$ns, data=>{ status=>'ok', result=>$result, ts=>$ts, global=>$global, html=>$html } );

        $c->stash->{json} = {msg => 'ok', success => \1};
    }
    catch {
        my $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub result_html : Local {
    my ( $self, $c ) = @_;
    my $ns = $c->request->params->{ns};
    my $data = Baseliner->model( 'Repository' )->get( ns => $ns );
    $c->res->body( $data->{html} || q{<h1>No results available</h1>'} );
}

sub request_analysis : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->params;

    my $user         = $c->username;
    my $project      = $p->{project};
    my $subproject   = $p->{subapp};
    my $nature       = $p->{nature};
    my $bl           = $p->{bl};
    my $project_name = $p->{project_name};
    my $project_id   = $p->{project_id};
    my $job_id       = $p->{project_id};
    my $schedule     = $p->{schedule};
    my $time         = $p->{time};
    my $err          = '';
    my $return       = '';
    my $out          = '';

    try {
        if ( $c->model( 'Permissions' )
            ->user_has_action( username => $c->username, action => 'action.sqa.request_analysis' ) )
        {

            if ( $project_name ) {
                $project = $project_name;
            }
            if ( $schedule ) {
                ( $return, $out ) = BaselinerX::Model::SQA->request_schedule(
                    job_id     => $job_id,
                    
                    bl         => $bl,
                    project    => $project,
                    subproject => $subproject,
                    nature     => $nature,
                    user       => $user,
                    time       => $time,
                    id_prj     => $project_id
                );
              } else {
                 ( $return, $out ) = BaselinerX::Model::SQA->request_analysis(
                    job_id     => $job_id,
                    bl         => $bl,
                    project    => $project,
                    subproject => $subproject,
                    nature     => $nature,
                    user       => $user
                );       
              }
            } else {
                $err = "The user doesn't have permission to request an analysis";
        }

        if ( $return ) {
            $c->stash->{json} = {msg => 'ok', success => \1};
        } else {
            $c->stash->{json} = {msg => _loc( "Error: %1", $err ), success => \0};
        }

    }
    catch {
        $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub harvest_projects : Local {
    my ( $self, $c ) = @_;
    my $p          = $c->request->params;
    my $project    = $p->{project};
    my $subproject = $p->{subapp};
    my $nature     = $p->{nature};
    my $query      = $p->{query};
    my $bl 		   = $p->{bl};
    my $blcond	   = '';
    
    if ($bl eq 'DESA') {
    	$blcond = " AND ( trim(v.VIEWNAME) = 'DESA' OR trim(v.VIEWNAME) = 'TEST' OR trim(v.VIEWNAME) = 'ANTE' OR trim(v.VIEWNAME) = 'PROD')"
    } elsif ($bl eq 'TEST') {
    	$blcond = " AND ( trim(v.VIEWNAME) = 'TEST' OR trim(v.VIEWNAME) = 'ANTE' OR trim(v.VIEWNAME) = 'PROD')"
    } elsif ($bl eq 'ANTE') {
    	$blcond = " AND ( trim(v.VIEWNAME) = 'ANTE' OR trim(v.VIEWNAME) = 'PROD')"
    } elsif ($bl eq 'PROD') {
    	$blcond = " AND ( trim(v.VIEWNAME) = 'PROD')"
    }

    my $db = Baseliner::Core::DBI->new( {model => 'Harvest'} );
    my $checkSubapp = "";

    $checkSubapp = "AND pf.pathfullnameupper LIKE UPPER( '%\\$project\\J2EE\\$subproject%\\%' )"
        if $nature =~ /J2EE/;
    $checkSubapp = "AND pf.pathfullnameupper LIKE UPPER( '%\\$project\\.NET\\$subproject\\%' )"
        if $nature =~ /NET/;
    $checkSubapp = "AND pf.pathfullnameupper LIKE UPPER( '%\\$project\\BIZTALK\\$subproject\\%' )"
        if $nature =~ /BIZTALK/;

    my $filter = "AND e.environmentname like '${query}%'" if $query;
    my $SQL = "
		select e.envobjid AS id, e.environmentname AS project, e.envisactive, e.isarchive
				   from harpackage p, harenvironment e, haritems i, harversions iv, harpathfullname pf, HARVIEW v
				   where p.VIEWOBJID = v.VIEWOBJID AND
                         p.envobjid = e.envobjid AND
				   		 p.packageobjid = iv.packageobjid AND
				   		 iv.itemobjid = i.itemobjid AND
				   		 i.parentobjid = pf.itemobjid AND
				   		 (pf.pathfullnameupper LIKE UPPER( '%\\$project\\$nature\\%' ) OR pf.pathfullnameupper LIKE UPPER( '%\\$project\\$nature' ))
						 $blcond 
				   		 $checkSubapp 
				   GROUP BY e.envobjid, e.environmentname, e.envisactive, e.isarchive
				   HAVING e.environmentname like '${project}\%' AND
                          TRIM(e.envisactive) = 'Y' AND TRIM(e.isarchive) = 'N'
	";
    _log "$SQL";

    my @data = $db->array_hash( "$SQL" );
    $c->stash->{json} = {
        totalCount => scalar( @data ),
        data       => \@data
    };
    $c->forward( 'View::JSON' );
}

sub harvest_all_projects : Local {
    my ( $self, $c ) = @_;
    my $p     = $c->request->params;
    my $query = $p->{query};

    my @data;
    my @projects = $c->model( 'Permissions' )->user_projects_with_action(
        username => $c->username,
        action   => 'action.sqa.new_analysis'
    );

    my $rs =
        Baseliner->model( 'Baseliner::BaliProject' )
        ->search( {id_parent => {'=', undef}, name => {'like', uc( "$query%" )}, mid => \@projects},
        {order_by => 'name asc'} );

    #rs_hashref( $rs );
    while ( my $row = $rs->next ) {
        push @data,
            {
            id      => $row->id,
            project => $row->name,
            };
    }
    $c->stash->{json} = {
        totalCount => scalar( @data ),
        data       => \@data
    };
    $c->forward( 'View::JSON' );
}

sub harvest_subprojects : Local {
    my ( $self, $c ) = @_;
    my $p       = $c->request->params;
    my $project = $p->{project};
    my $query   = $p->{query};

    my @data;

    _log
        "******************** Buscando subaplicaciones de |$project| **************************************";

    if ( $project ) {
        $query =~ s/_/\\_/g if $query;
        $query =~ s/%/\\%/g if $query;

        my $rs =
            Baseliner->model( 'Baseliner::BaliProject' )
            ->search( {id_parent => $project, name => {'like', \"'$query%' escape '\\'"}},
            {order_by => 'name asc'} );
 

        my $har_items = Baseliner->model('Harvest::Haritems');  # avoid repeating his call

        my $har_db = BaselinerX::CA::Harvest::DB->new;

SUBAPL:
        while ( my $row = $rs->next ) {
        	
### El fix que solucionaba la incidencia GDF necesita de una jerarquía
### Aplicación / Tecnología / Sub-aplicación que no es estándar, por lo
### que genera falsos positivos.
###
###            ## check if it still exists GDF #71547
###            next unless $har_items->search({ itemnameupper => uc( $row->name ), itemtype=>0 })->count;

            ## Hay que filtrar aquellas subaplicaciones que no estén 
            ## contenidas en Harvest.
            ## Capturamos el nombre de la aplicación.
            my $project_name;
            try {
              my $rs = Baseliner->model('Baseliner::BaliProject')->search({mid => $row->id}, {select => 'id_parent'});
              rs_hashref($rs);
              my $proyect_id = $rs->next->{id_parent};
              
              $rs = Baseliner->model('Baseliner::BaliProject')->search({mid => $proyect_id}, {select => 'name'});
              rs_hashref($rs);
              $project_name = $rs->next->{name};
            }
            catch {
              _log "Error al capturar el nombre del proyecto con id " . $row->id . ".";
              next SUBAPL;
            };

            next unless $har_db->subapl_in_harvest_p($project_name, $row->name);

            push @data, {
                id      => $row->id,
                project => $row->name,
            };
        }
    }
    $c->stash->{json} = {
        totalCount => scalar( @data ),
        data       => \@data
    };
    $c->forward( 'View::JSON' );
}

sub subproject_natures : Local {
    my ( $self, $c ) = @_;
    my $p       = $c->request->params;
    my $project = $p->{project};
    my $query   = $p->{query};

    my @data;

    _log
        "******************** Buscando subaplicaciones de |$project| **************************************";

    if ( $project ) {
        my $rs =
            Baseliner->model( 'Baseliner::BaliProject' )
            ->search( {id_parent => $project}, {order_by => 'nature asc'} );
        while ( my $row = $rs->next ) {
        	my $nat = $row->nature;
        	if (grep /$nat/, @filters) {
        		_log "*********************************He agregado al combo la fila". $row->name ."/$nat";
	            push @data,
	                {
	                id     => $row->name."(".$nat.")",
	                nature => $nat,
	                };
        	}
        }
    }
    
    $c->stash->{json} = {
        totalCount => scalar( @data ),
        data       => \@data
    };
    $c->forward( 'View::JSON' );
}

sub request_recalc : Local {
    my ( $self, $c ) = @_;
    my $p          = $c->request->params;
    my $project    = $p->{project};
    my $subproject = $p->{subapp};
    my $nature     = $p->{nature};
    my $bl         = $p->{bl};
    my $level      = $p->{level};
    my $job_id     = $p->{project_id};
    my $err        = '';
    my $return     = '';

    try {
        if ( $c->model( 'Permissions' )
            ->user_has_action( username => $c->username, action => 'action.sqa.request_recalc' ) )
        {
            $return = BaselinerX::Model::SQA->calculate_aggregate(
                job_id     => $job_id,
                bl         => $bl,
                project    => $project,
                subproject => $subproject,
                nature     => $nature,
                level      => $level
            );
        } else {
            $err = "The user doesn't have permission to request an analysis";
        }
        if ( $return ) {
            $c->stash->{json} = {msg => 'ok', success => \1};
        } else {
            $c->stash->{json} = {msg => "Error: %1", success => \0};
        }
    }
    catch {
        $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub request_subapp_projects : Local {
    my ( $self, $c ) = @_;
    my $user      = $c->username;
    my $p         = $c->request->params;
    my $subapp_id = $p->{subapp_id};

    my $project = $p->{project};
    my $bl      = $p->{bl};

    my $return = '';
    my $out    = '';
    my $err    = '';

    try {
        if (
            $c->model( 'Permissions' )->user_has_action(
                username => $c->username,
                action   => 'action.sqa.request_subproject'
            )
            )
        {
            my $rs =
                Baseliner->model( 'Baseliner::BaliProject' )
                ->search( {id_parent => $subapp_id}, {order_by => 'name asc'} );
            my $cont = 0;
            while ( my $row = $rs->next ) {
                $row->id;
                $row->nature;
                $row->name;

				my $nature_work = $row->nature;
                if ( grep /$nature_work/, @filters ) {
	                _log "Solicitando análisis de " . $row->name . "/" . $row->nature;
	                ( $return, $out ) = BaselinerX::Model::SQA->request_analysis(
	                    bl         => $bl,
	                    project    => $project,
	                    subproject => $row->name,
	                    nature     => $row->nature,
	                    user       => $user
	                );
	                _log "Análisis de " . $row->name . "/" . $row->nature . " solicitado\n";
	                $cont++;
				} else {
					_log $row->name."/".$row->nature." ignorada.";
				}
            }

            _log "$cont análisis solicitados";
        } else {
            $err =
                "The user doesn't have permission to request the analysis of a entire subproject";
        }
        if ( $return ) {
            $c->stash->{json} = {msg => 'ok', success => \1};
        } else {
            $c->stash->{json} = {msg => _loc( "Error: %1", $err ), success => \0};
        }
    }
    catch {
        $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub request_cam_projects : Local {
    my ( $self, $c ) = @_;
    my $user       = $c->username;
    my $p          = $c->request->params;
    my $project_id = $p->{project_id};

    my $project = $p->{project};
    my $bl      = $p->{bl};

    my $return = '';
    my $out    = '';
    my $err    = '';

    try {
        if ( $c->model( 'Permissions' )
            ->user_has_action( username => $c->username, action => 'action.sqa.request_project' ) )
        {
            my $rs =
                Baseliner->model( 'Baseliner::BaliProject' )->search( {id_parent => $project_id} );
            my $cont = 0;
            while ( my $row = $rs->next ) {
                my $rs2 =
                    Baseliner->model( 'Baseliner::BaliProject' )->search( {id_parent => $row->id} );
                while ( my $row2 = $rs2->next ) {
                    
                    try {
                    	my $nature_work = $row2->nature;
                    	if ( grep /$nature_work/, @filters ) {
	                    	_log "Solicitando análisis de " . $row2->name . "/" . $row2->nature;
		                    ( $return, $out ) = BaselinerX::Model::SQA->request_analysis(
		                        bl         => $bl,
		                        project    => $project,
		                        subproject => $row2->name,
		                        nature     => $row2->nature,
		                        user       => $user
		                    );
		                    _log "Análisis de " . $row2->name . "/" . $row2->nature . " solicitado\n";
	                    	$cont++;
                    	} else {
							_log $row2->name."/".$row2->nature." ignorada.";
						}
                    } catch {
                    	_log "Error al solicitar el análisis de " . $row2->name . "/" . $row2->nature;
                    };
                }
            }

            _log "$cont análisis solicitados";
        } else {
            $err = _loc(
                "The user doesn't have permission to request the analysis of a entire subproject" );
        }
        if ( $return ) {
            $c->stash->{json} = {msg => 'ok', success => \1};
        } else {
            $c->stash->{json} = {msg => _loc( "Error: %1", $err ), success => \0};
        }
    }
    catch {
        $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub update_config : Local {
    my ( $self, $c ) = @_;
    my $user                  = $c->username;
    my $p                     = $c->request->params;
    my $project_id            = $p->{fproject_id};
    my $run_sqa_test          = $p->{chk_run_sqa_test} ? 'Y' : 'N';
    my $run_sqa_ante          = $p->{chk_run_sqa_ante} ? 'Y' : 'N';
    my $run_sqa_prod          = $p->{chk_run_sqa_prod} ? 'Y' : 'N';
    my $block_deployment_test = $p->{chk_block_deployment_test} ? 'Y' : 'N';
    my $block_deployment_ante = $p->{chk_block_deployment_ante} ? 'Y' : 'N';
    my $block_deployment_prod = $p->{chk_block_deployment_prod} ? 'Y' : 'N';
    my $err;
    my $project;

    try {
        if ( $project_id eq 'global' ) {
            $project = '/';
        } elsif ( $project_id =~ /\// ) {
            $project = 'nature/' . $project_id;
        } else {
            $project = 'project/' . $project_id;
        }

        $c->model( 'ConfigStore' )->set(
            key   => 'config.sqa.run_sqa',
            value => $run_sqa_test,
            bl    => 'TEST',
            ns    => $project
        );
        $c->model( 'ConfigStore' )->set(
            key   => 'config.sqa.run_sqa',
            value => $run_sqa_ante,
            bl    => 'ANTE',
            ns    => $project
        );
        $c->model( 'ConfigStore' )->set(
            key   => 'config.sqa.run_sqa',
            value => $run_sqa_prod,
            bl    => 'PROD',
            ns    => $project
        );

        $c->model( 'ConfigStore' )->set(
            key   => 'config.sqa.block_deployment',
            value => $block_deployment_test,
            bl    => 'TEST',
            ns    => $project
        );
        $c->model( 'ConfigStore' )->set(
            key   => 'config.sqa.block_deployment',
            value => $block_deployment_ante,
            bl    => 'ANTE',
            ns    => $project
        );
        $c->model( 'ConfigStore' )->set(
            key   => 'config.sqa.block_deployment',
            value => $block_deployment_prod,
            bl    => 'PROD',
            ns    => $project
        );

        $c->stash->{json} = {msg => 'ok', success => \1};
    }
    catch {
        $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub remove_config : Local {
    my ( $self, $c ) = @_;
    my $user       = $c->username;
    my $p          = $c->request->params;
    my $project_id = $p->{project_id};
    my $err;
    my $project;

    try {
        if ( $project_id ) {
            if ( $project_id =~ /\// ) {
                $project = 'nature/' . $project_id;
            } else {
                $project = 'project/' . $project_id;
            }
        } else {
            $project = '/';
        }
        $c->model( 'ConfigStore' )->delete(
            key => [ 'config.sqa.run_sqa', 'config.sqa.block_deployment' ],
            bl  => [ 'TEST',               'ANTE', 'PROD' ],
            ns => $project
        );

        $c->stash->{json} = {msg => 'ok', success => \1};
    }
    catch {
        $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub get_row_permissions : Local {
    my ( $self, $c ) = @_;
    my $user       = $c->username;
    my $p          = $c->request->params;
    my $project_id = $p->{project_id};
    my $gridType   = $p->{type};
    my $err;
    my $permissions = {};

    try {


        if ( $gridType eq 'PKG' ) {
            $permissions->{request_analysis}      = \0;
            $permissions->{request_recalc}        = \0;
            $permissions->{delete_analysis}       = \0;
            $permissions->{edit_config}   = \0;
            $permissions->{remove_config} = \0;
            $permissions->{edit_global}   = \0;
        } elsif ( $gridType =~ /CFG/ ) {
            $permissions->{request_analysis}     = \0;
            $permissions->{request_recalc}       = \0;
            $permissions->{delete_analysis}      = \0;
            $permissions->{edit_config}   = $c->model( 'Permissions' )->user_has_action(
                action   => 'action.sqa.project_config',
                username => $c->username,
                ns => 'project/'.$project_id
            );

        } else {
            $permissions->{request_analysis}     = $c->model( 'Permissions' )->user_has_action(
                action   => 'action.sqa.request_analysis',
                username => $c->username,
                ns => 'project/'.$project_id
            );
            $permissions->{request_recalc}       = $c->model( 'Permissions' )->user_has_action(
                action   => 'action.sqa.request_recalc',
                username => $c->username,
                ns => 'project/'.$project_id
            );
            $permissions->{delete_analysis}       = $c->model( 'Permissions' )->user_has_action(
                action   => 'action.sqa.delete_analysis',
                username => $c->username,
                ns => 'project/'.$project_id
            );
            
            $permissions->{edit_config}   = \0;
        }
        $c->stash->{json} = {msg => 'ok', success => \1, permissions => $permissions};
    }
    catch {
        $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub delete_analysis : Local {
    my ( $self, $c ) = @_;
    my $user       = $c->username;
    my $p          = $c->request->params;
    my $job_id = $p->{id};
    my $err;

    try {
    	_log "TENGO QUE BORRAR EL ID $job_id";
		
		BaselinerX::Model::SQA->delete (
           id     => $job_id
     	);
		
        $c->stash->{json} = {msg => 'ok', success => \1};
    } catch {
        $err = shift;
        $c->stash->{json} = {msg => _loc( "Error running sqa commands: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );
}

sub subproject_natures : Local {
    my ( $self, $c ) = @_;

    my @data;
    my $where = {};
    
	$where->{'me.id'} = $c->model( 'Permissions' )->user_projects_with_action(
	            username => $c->username,
	            action   => 'action.sqa.view_project'
	        );
        my $rs =
            Baseliner->model( 'Baseliner::BaliSqaPlannedTest' )
            ->search( $where, {order_by => { -asc => 'project'}} );
        while ( my $row = $rs->next ) {
            push @data,
                {
	                id     => $row->id,
	                project     => $row->project,
	                subapl     => $row->subapl,
	                nature     => $row->nature,
	                username     => $row->username,
	                active     => $row->active,
	                last_exec     => $row->last_exec,
	                comments     => $row->comments,
	                schedule     => $row->schedule,
	                bl     => $row->bl,
	                next_exec     => $row->next_exec
                };
        }
    
    $c->stash->{json} = {
        totalCount => scalar( @data ),
        data       => \@data
    };
    $c->forward( 'View::JSON' );
}
1;

