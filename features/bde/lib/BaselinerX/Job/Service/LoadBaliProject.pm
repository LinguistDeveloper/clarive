package BaselinerX::Job::Service::LoadBaliProject;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Baseliner::Sugar;
use BaselinerX::Comm::Balix;
use BaselinerX::Ktecho::CamUtils;
use Try::Tiny;
use 5.010;
with 'Baseliner::Role::Service';

has 'config' => ( is=>'rw', isa=>'Any' );

register 'service.load.bali.project' => {
    name    => 'Carga de proyectos en BALI',
    config   => 'config.load.bali.project',
    handler => \&run
};

register 'service.load.bali.project_once' => {
    name    => 'Carga de proyectos en BALI',
    config   => 'config.load.bali.project',
    handler => \&run_once
};

sub run { # bucle de demonio aqui
    my ($self,$c, $config) = @_;
    _log "Starting service.load.bali.project";
    my $iterations = $config->{iterations};
    for( 1..$iterations ) {  # bucle del servicio, se pira a cada x, y el dispatcher lo rearranca de nuevo
        $self->run_once($c,$config);
        _log "Waiting for $config->{frequency} seconds";
        sleep $config->{frequency};
    }
    _log "Ending service.load.bali.project";
}

sub iii { require DBIx::Simple;
    return DBIx::Simple->connect( Baseliner->model('Inf')->storage->dbh );
}

sub run_once {
    my ( $self, $c, $config ) = @_;

    my $k = 0;

    try {
        _log "Updating or creating Baseliner projects... ";

        my %win = map { $_->{cc} => 1 } 
        iii->query(q{select cam||'-'||mv_valor cc from inf_data_mv m, inf_data d where d.idform in (select idform from inf_form_max) and column_name='WIN_APPL' and valor='@#'||id})->hashes;

        my %java = map { $_->{cc} => 1 } 
        iii->query(q{select cam||'-'||mv_valor cc from inf_data_mv m, inf_data d where d.idform in (select idform from inf_form_max) and column_name='JAVA_APPL' and valor='@#'||id})->hashes;

        my %pubs = map { $_->{cam} => 1 } 
        iii->query(q{select cam from inf_data d where d.idform in (select idform from inf_form_max) and column_name='SCM_APL_PUBLICA' and valor='Si'})->hashes;

        my $r = $c->model('Harvest::HarPathFullName')->search({ -not => { pathfullname=>{ -like => '\%\%\%\%' } }, pathfullname=>{-like=>'\%\%\%'} }, { distinct=>1, select=>'pathfullname' });
        rs_hashref( $r );
        my (%cam,%sa,%nat);
        for ( $r->all ) {
            my ($no,$cam,$nat,$sa) = split /\\/, $_->{pathfullname};
            $cam = substr $cam, 0, 3;
            next if $nat !~ /(J2EE|RS|\.NET|ORACLE|BIZTALK|JAVABATCH|FICHEROS|ECLIPSE)$/; 
            next if $sa =~ /(_SCM|_SHAREDLIB)$/;  
            for( 1..3 ) {
                $sa =~ s {(_BAT|_EAR|_EJB|_LIB|_IAS|_WEB|_TEST|_SERVIDOR)$}{}g; 
            }
            if( $sa =~ /^(.*)_BATCH$/ ) {
                $nat = 'JAVABATCH';
                $sa = $1;
            } 
            if( $nat =~ /\.NET|BIZTALK/ ) {
                next if ! exists $win{ $cam.'-'.$sa } && ! $pubs{ $cam };
            } elsif( $nat =~ /^(J2EE|JAVABATCH)$/ ) {
                next if ! exists $java{ $cam.'-'.$sa } && ! $pubs{ $cam };
            } else {
                $sa = lc $cam;
            }
            $cam{ $cam }{natures}{ $nat }{ $sa } = 1;
            $cam{ $cam }{subapls}{ $sa } = 1;
        }

        #my %cam = %{ _load( scalar $c->path_to( 'yy' )->slurp ) };

        for my $cam ( keys %cam ) {
            my $r = DB->BaliProject->search({ name=>$cam, id_parent=>undef, nature=>undef })->first;
            if( $r ) { $cam{ $cam }{id} = $r->id; next }
            master_new project => $cam => sub {
                my $mid = shift;
                _debug "Creando proyecto $cam lev=1 CAM ($mid)"; 
                $r = DB->BaliProject->create({ name=>$cam, mid=>$mid });
                $k++;
                $cam{ $cam }{id} = $r->id;
            };
        }

        #my %id_cam = map { $_->{name} => $_ } DB->BaliProject->search({ id_parent=>undef, nature=>undef })->all;
        for my $cam ( keys %cam ) {
            for my $sa ( keys %{ $cam{ $cam }{subapls} || {} } ) {
               my $r = DB->BaliProject->search({ name=>$sa, id_parent=>$cam{$cam}{id}, nature=>undef })->first;
               if( $r ) { $cam{ $cam }{subapls}{ $sa } = $r->id; next }
               master_new project => $sa => sub {
                   my $mid = shift;
                   _debug "Creando proyecto $sa lev=2 Subapl ($mid)"; 
                   $r = DB->BaliProject->create({ mid=>$mid, name=>$sa, id_parent=>$cam{$cam}{id}, nature=>undef });    
                   $k++;
                   $cam{ $cam }{subapls}{ $sa } = $r->id;       
               };
            }
        }

        for my $cam ( keys %cam ) {
            for my $nat ( keys %{ $cam{ $cam }{natures} || {} } ) {
               for my $sa ( keys %{ $cam{ $cam }{natures}{$nat} || {} } ) {
                   my $sa_id = $cam{$cam}{subapls}{ $sa };
                   next unless defined $sa_id;
                   if( $nat =~ /^(\.NET|BIZTALK|J2EE|JAVABATCH)$/ ) {
                       # en estas naturalezas los proyectos tienen NAME = subapl
                       my $r = DB->BaliProject->search({ name=>$sa, id_parent=>$sa_id, nature=>$nat })->first;
                       next if $r;
                       master_new project => $sa => sub {
                           my $mid = shift;
                           _debug "Creando proyecto $sa lev=3 NAT[$nat] ($mid)"; 
                           $k++;
                           $r = DB->BaliProject->create({ mid=>$mid, name=>$sa, id_parent=>$sa_id, nature=>$nat });
                           $r->mid;
                       };
                   } else {
                       # en el resto de naturalezas los proyectos tienen NAME = CAM
                       my $r = DB->BaliProject->search({ name=>$cam, id_parent=>$sa_id, nature=>$nat })->first;
                       next if $r;
                       master_new project => $cam => sub {
                           my $mid = shift;
                           _debug "Creando proyecto $cam lev=3 NAT[$nat] ($mid)"; 
                           $k++;
                           $r = DB->BaliProject->create({ mid=>$mid, name=>$cam, id_parent=>$sa_id, nature=>$nat });
                           $r->mid;
                       };
                   }
               }
           }
        }
        _log sprintf "Creados %d proyectos", $k;
    } catch {
        my $err = shift;
        _log "ERROR AL CARGAR PROYECTOS: $err";
    };
}

sub run_once_old {
    my ( $self, $c, $config ) = @_;

    try {
        _log "Updating or creating Baseliner projects... ";
    
        # Loads project names from Harenvironment
        my $rs = Baseliner->model('Harvest::Harenvironment')->search(
            { envisactive => 'Y' },
            {   select => ['environmentname'],
                as     => ['name']
            }
        );
        rs_hashref($rs);

        # Turns resultset into an array of values
        my @data;
        while ( my $value = $rs->next ) {
            #_log "Added $value->{name}";
            push @data, substr($value->{name},0,3);
        }

        # Sorts data...
        @data = sort(@data);

        # Removes first blank value...
        shift @data;

        foreach my $project ( _unique @data  ) {
            #_log "Treating cam $project";
            my $row_project = Baseliner->model('Baseliner::BaliProject')->search( { name => uc($project), id_parent => { '=' => undef } }   )->first;
            
            if ( !$row_project ) {
                $row_project = Baseliner->model('Baseliner::BaliProject')->create( { name => uc($project) } );
                _log "Created Project: ". uc($project);
            }

            my $current_cams_rs = Baseliner->model('Inf::InfForm')->search( undef, { select => [qw/ cam /], as => [qw/ cam /] } );
            rs_hashref($current_cams_rs);

            # Map from array of hashes to array...
            my @current_cams = map $_->{cam}, $current_cams_rs->all;
            
            # Naturalezas sin subaplicación
            for my $nature ( ('FICHEROS','RS','ORACLE','ECLIPSE') ) {
                my $db = Baseliner::Core::DBI->new({ model=>'Harvest' });               
                    
                my $SQL = "
                    select e.environmentname AS project
                               from harpackage p, harenvironment e, haritems i, harversions iv, harpathfullname pf
                               where 
                                     p.envobjid = e.envobjid AND
                                     p.packageobjid = iv.packageobjid AND
                                     iv.itemobjid = i.itemobjid AND
                                     i.parentobjid = pf.itemobjid AND
                                     (pf.pathfullnameupper LIKE UPPER( '\\$project\\$nature\\%' ) OR pf.pathfullnameupper LIKE UPPER( '\\$project\\$nature' ))
                               GROUP BY e.envobjid, e.environmentname
                ";
                my @datos = $db->array_hash("$SQL");
                if ( @datos ) {
                    my $row_subprojectnature = Baseliner->model('Baseliner::BaliProject')->search( { name => uc($project), nature => $nature }  )->first;
                    
                    if ( !$row_subprojectnature ) {
                        my $row_subproject = Baseliner->model('Baseliner::BaliProject')->search( { name => lc($project), nature => { '=' => undef }, id_parent => $row_project->mid }   )->first;
                        
                        if ( !$row_subproject ) {
                            my $prjname=lc($project);
                            master_new "project"=>$prjname=>sub{
                                my $mid=shift;
                                $row_subproject = Baseliner->model('Baseliner::BaliProject')->create( { mid=>$mid, name => $prjname, id_parent => $row_project->mid } );
                            };

                            _log "Created Subproject ".lc($project);
                        }
                        
                        my $sprjname=uc($project);
                        master_new "project"=>$sprjname=>sub{
                            my $mid=shift;
                            $row_subprojectnature = Baseliner->model('Baseliner::BaliProject')->create( { mid=>$mid, name => $sprjname, id_parent => $row_subproject->mid, nature => $nature } );
                        };
                        _log "Created Subproject ".$nature."/".uc($project);
                    }
                }
            }
            
            # Subaplicaciones BIZTALK y .NET

            for my $nature ( ('BIZTALK','.NET') ) {
                my $db = Baseliner::Core::DBI->new({ model=>'Harvest' });               
                    
                my $SQL = "
                    select DISTINCT SUBSTR(pathfullname, INSTR(trim(pathfullname),'\\',INSTR(trim(pathfullname),'\\',2)+1)+1, INSTR(SUBSTR(pathfullname,INSTR(trim(pathfullname),'\\',INSTR(trim(pathfullname),'\\',2)+1)+1 ),'\\')-1 ) as subapp
                               from haritems i, harpathfullname pf
                               where 
                                     i.parentobjid = pf.itemobjid AND
                                     (pf.pathfullnameupper LIKE UPPER( '\\$project\\$nature\\%' ) OR pf.pathfullnameupper LIKE UPPER( '\\$project\\$nature' )) AND
                                     length(SUBSTR(pathfullname, INSTR(trim(pathfullname),'\\',INSTR(trim(pathfullname),'\\',2)+1)+1, INSTR(SUBSTR(pathfullname,INSTR(trim(pathfullname),'\\',INSTR(trim(pathfullname),'\\',2)+1)+1 ),'\\')-1 )) <> 0
                ";

                my @datos = $db->array_hash("$SQL");
                
                if ( @datos ) {                 
#                   my @inf_subapps;
#                   
#                   if ( $nature eq '.NET' ) {
#                       @inf_subapps = sub_apps $project, 'net';
#                   } else {
#                       @inf_subapps = @datos;
#                   }

                    for my $row ( @datos ) {
                        
                        my $subproject = $row->{subapp};
                        
#                       if ( grep /$subproject/, @inf_subapps )                     
                        if ( $subproject =~ / /g ) {
                            _log "Subproject *".$subproject."* has blanks in its name.  It will not be loaded";
                            next;
                        } else {
                            #_log "Treating $subproject $nature";
                            my $rs_subnat = Baseliner->model('Baseliner::BaliProject')->search( { name => $subproject, nature => $nature }  );
                    
                            my $already_exists = 0;
                            my $row_subprojectnature;
                            while ( $row_subprojectnature = $rs_subnat->next ) {
                                if ( $row_subprojectnature->parent && $row_subprojectnature->parent->parent && $row_subprojectnature->parent->parent->mid eq $row_project->mid ) {
                                    $already_exists = 1;
                                }
                            }
                            if ( !$already_exists ) {

                                my $row_subproject = Baseliner->model('Baseliner::BaliProject')->search( { name => lc($subproject), nature => { '=' => undef }, id_parent => $row_project->mid }    )->first;
                                
                                if ( !$row_subproject ) {
                                    master_new "project"=>lc($subproject)=>sub{
                                        my $mid=shift;
                                        $row_subproject = Baseliner->model('Baseliner::BaliProject')->create( { mid=>$mid, name => lc($subproject), id_parent => $row_project->mid } );
                                    };
                                    _log "Created Subproject ".lc($subproject);
                                }
                                
                                master_new "project"=>$subproject=>sub{
                                    my $mid=shift;
                                    $row_subprojectnature = Baseliner->model('Baseliner::BaliProject')->create( { mid=>$mid, name => $subproject, id_parent => $row_subproject->mid, nature => $nature } );
                                };
                                _log "Created Subproject ".$nature."/".$subproject;
                            }
                        }                       
                    }
                }
            }

            # Subaplicaciones .NET y J2EE de INF
            
            if ( $project ~~ @current_cams) {           
#               foreach my $subproject ( sub_apps $project, 'net' ) {
#                   #_log "Treating $subproject .NET";
#                   my $row_subprojectnature = Baseliner->model('Baseliner::BaliProject')->search( { name => $subproject, nature => '.NET' }    )->first;
#                   
#                   if ( !$row_subprojectnature ) {
#                       my $row_subproject = Baseliner->model('Baseliner::BaliProject')->search( { name => lc($subproject), nature => { '=' => undef }, id_parent => $row_project->mid }    )->first;
#                       
#                       if ( !$row_subproject ) {
#                           $row_subproject = Baseliner->model('Baseliner::BaliProject')->create( { name => lc($subproject), id_parent => $row_project->mid } );
#                           _log "Created Subproject ".lc($subproject);
#                       }
#                       
#                       $row_subprojectnature = Baseliner->model('Baseliner::BaliProject')->create( { name => $subproject, id_parent => $row_subproject->mid, nature => '.NET' } );
#                       _log "Created Subproject ".lc($subproject). " with nature .NET";
#                   }
#               }
            # BUSCAMOS LAS APLICACIONES J2EE QUE ESTÁN EN DISCO
                foreach my $subproject ( sub_apps $project, 'java' ) {
                    #_log "Treating $subproject J2EE";
                
                    my $rs_subnat = Baseliner->model('Baseliner::BaliProject')->search( { name => $subproject, nature => 'J2EE' }   );
                    
                    my $already_exists = 0;
                    my $row_subprojectnature;
                    while ( $row_subprojectnature = $rs_subnat->next ) {
                        if ( $row_subprojectnature->parent && $row_subprojectnature->parent->parent && $row_subprojectnature->parent->parent->mid eq $row_project->mid ) {
                            $already_exists = 1;
                        }
                    }
                    if ( !$already_exists ) {
                        my $db = Baseliner::Core::DBI->new({ model=>'Harvest' });               
                    
                        my $SQL = "
                            select PF.PATHFULLNAMEUPPER
                                       from harpathfullname pf
                                       where (pf.pathfullnameupper LIKE UPPER( '\\$project\\J2EE\\$subproject%\\%' ) OR pf.pathfullnameupper LIKE UPPER( '\\$project\\J2EE\\$subproject%' ))
                        ";
        
                        my @datos = $db->array_hash("$SQL");
    
                        if ( @datos ) { 
                            my $row_subproject = Baseliner->model('Baseliner::BaliProject')->search( { name => lc($subproject), nature => { '=' => undef }, id_parent => $row_project->mid }    )->first;
                            
                            if ( !$row_subproject ) {
                                master_new "project"=>lc($subproject)=>sub{
                                    my $mid=shift;
                                    $row_subproject = Baseliner->model('Baseliner::BaliProject')->create( { mid=>$mid, name => lc($subproject), id_parent => $row_project->mid } );
                                };
                                _log "Created Subproject ".lc($subproject);
                            }
                            
                            master_new "project"=>$subproject=>sub{
                                my $mid=shift;
                                $row_subprojectnature = Baseliner->model('Baseliner::BaliProject')->create( { mid=>$mid, name => $subproject, id_parent => $row_subproject->mid, nature => 'J2EE' } );
                            };
                            _log "Created Subproject J2EE/".lc($subproject);
                        
                        } else {
                            _log "Subproject J2EE/$subproject ignored.  Not in harvest";
                        }
                    }
                }
            }
        }
        return;
    } catch {
        my $err = shift;
        _log "ERROR AL CARGAR PROYECTOS: $err";
    };
}

1;
