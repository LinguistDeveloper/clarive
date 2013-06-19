package Baseliner::Controller::Project;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Controller' };
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Moose::Autobox;
use JSON::XS;
use namespace::clean;
use v5.10;

register 'action.admin.project' => { name => 'Administer projects'};

register 'menu.admin.project' => {
    label => 'Projects', url_comp=>'/project/grid', actions=>['action.admin.project'],
    title=>'Projects', index=>80,
    icon=>'/static/images/icons/project.png' };

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my $sw_crear_editar = $p->{sw_crear_editar};
    
    my @tree;
    my $total_rows;
    
    ##VIENE POR LA PARTE PRINCIPAL DE PROYECTOS, OSEA LA CARGA DEL GRID.
    if($sw_crear_editar ne 'true'){
    my $id_project;
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    my $dbh = $db->dbh;
        my ($start, $limit, $query) = ( @{$p}{qw/start limit query/});
    $start ||= 0;
        $limit ||= 100;
    
        my $page = to_pages( start=>$start, limit=>$limit );

    if ($p->{anode}){
        $id_project=$p->{anode};
    }else{
        $id_project='todos';
    }

    
    if($query ne ''){ #ENTRA CUANDO TIENE ALGO EN EL FILTRO DE BÚSQUEDA
        my $SQL;
        if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
        $SQL = 'SELECT FILA, NIVEL, B.MID, B.NAME, A.NAME AS NAME_PARENT, B.DESCRIPTION, B.NATURE FROM (SELECT ROWNUM AS FILA, LEVEL AS NIVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE FROM BALI_PROJECT A START WITH ID_PARENT IS NULL AND ACTIVE = 1 CONNECT BY PRIOR MID = ID_PARENT AND ACTIVE = 1) B  LEFT JOIN BALI_PROJECT A ON A.MID = B.ID_PARENT';
        }
        else{
        ##INSTRUCCION PARA COMPATIBILIDAD CON SQL SERVER #######################################################################
        $SQL = 'WITH N(LEVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE) AS
            (SELECT 1 AS LEVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE
            FROM BALI_PROJECT
            WHERE ID_PARENT IS NULL AND ACTIVE = 1
            UNION ALL
            SELECT LEVEL + 1, NPLUS1.MID, NPLUS1.ID_PARENT, NPLUS1.NAME, NPLUS1.DESCRIPTION, NPLUS1.NATURE
            FROM BALI_PROJECT AS NPLUS1, N
            WHERE N.MID = NPLUS1.ID_PARENT AND NPLUS1.ACTIVE = 1)
            SELECT ROW_NUMBER() OVER(ORDER BY N.MID ASC) AS FILA, LEVEL AS NIVEL, N.MID, N.NAME, Z.NAME AS NAME_PARENT,
                N.DESCRIPTION, N.NATURE FROM N LEFT JOIN BALI_PROJECT Z ON Z.MID = N.ID_PARENT ';
        }
        
        my @datas = $db->array_hash( $SQL );
         
        @datas = grep { lc($_->{name}) =~ $query } @datas if $query;
     
        foreach my $data (@datas){
        push @tree, {
            name => $data->{name},
            description => $data->{description},
            nature => $data->{nature},
            parent => $data->{name_parent}?$data->{name_parent}:'/',
            _id => $data->{mid},
            _parent => undef,
            _level => 1,
            _num_fila => $data->{rownum},
            _lft => ($data->{rownum} - 1) * 2 + 1,
            _rgt => ($data->{rownum} - 1) * 2 + 1 + 1,
            _is_leaf => \1
        };
        }
        $total_rows = $#tree + 1 ;	
    } 
    else{ #COMPORTAMIENTO NORMAL
        my @datas;
        if($id_project ne 'todos'){
        @datas = ObtenerNodosHijosPrimerNivel($id_project);
        $total_rows = $#datas + 1 ;
        }
        else{
        my @data = ObtenerNodosPrincipalesPrimerNivel();
        $total_rows = $#data + 1 ;
        my $end = ($start+$limit-1) >= @data?@data - 1:($start+$limit-1);
            @datas = @data[$start..$end];		
        }
        for my $data (@datas){
        push @tree, {
             name => $data->{name},
             description => $data->{description},
             nature => $data->{nature},
             parent => $data->{name_parent}?$data->{name_parent}:'/',
             _id => $data->{mid},
             _parent => undef,
             _level => $data->{nivel},
             _num_fila => $data->{fila},
             _lft => ($data->{fila} - 1) * 2 + 1,
             _rgt => undef,
             _is_leaf => \$data->{leaf}
        };
        }
        
        if ($id_project eq 'todos'){
        for(0..$#tree){
            if($_ == $#tree){
            if(_array $tree[$_]->{_is_leaf} == 1){
                $tree[$_]->{_rgt} = $tree[$_]->{_lft} + 1;
            }else{
                my $SQL;
                if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
                $SQL = 'SELECT COUNT(*) AS NUMHIJOS FROM BALI_PROJECT A START WITH ID_PARENT = ? AND ACTIVE = 1 CONNECT BY PRIOR MID = ID_PARENT AND ACTIVE = 1';
                }
                else{
                ##INSTRUCCION PARA COMPATIBILIDAD CON SQL SERVER #######################################################################
                $SQL = 'WITH N AS
                    (SELECT MID, ID_PARENT
                    FROM BALI_PROJECT
                    WHERE ID_PARENT = ? AND ACTIVE = 1
                    UNION ALL
                    SELECT NPLUS1.MID, NPLUS1.ID_PARENT
                    FROM BALI_PROJECT AS NPLUS1, N
                    WHERE N.MID = NPLUS1.ID_PARENT AND NPLUS1.ACTIVE = 1)
                    SELECT COUNT(*) FROM N ';
                }
                my @datas = $db->array_hash( $SQL, $tree[$_]->{_id} );
                $tree[$_]->{_rgt} = $tree[$_]->{_lft} + ($datas[0]->{numhijos}*2+1);
            }
            }else{
            $tree[$_]->{_rgt} = $tree[$_+1]->{_lft} - 1;
            }
        }
        }else{
            $tree[0]->{_lft} = $p->{lft_padre} + 1;
            $tree[0]->{_rgt} = $p->{hijos_node};
            for(1..$#tree){
                if($_ == $#tree){
                    $tree[$_]->{_lft} = ($tree[$_]->{_num_fila} - $tree[$_-1]->{_num_fila}) * 2 + $tree[$_-1]->{_lft};  
                    $tree[$_]->{_rgt} = $p->{hijos_node};
                    $tree[$_-1]->{_rgt} = $tree[$_]->{_lft} - 1;
                    }else{
                    $tree[$_]->{_lft} = ($tree[$_]->{_num_fila} - $tree[$_-1]->{_num_fila}) * 2 + $tree[$_-1]->{_lft};
                    $tree[$_-1]->{_rgt} = $tree[$_]->{_lft} - 1;
                }
            }	    
        }	    
    }
 
    $c->stash->{json} = {data =>\@tree, success=>\1, total=>$total_rows};
    
    ##VIENE POR EL ASISTENTE DE CREACIÓN O MODIFICACIÓN DEL PROYECTO. SÓLO CARGA LA LISTA DE PROYECTOS
    }else{
        my $id_project = $p->{id_project};
        my @datas;
        if($id_project eq 'todos'){
            @datas = ObtenerNodosPrincipalesPrimerNivel();
            push @tree, {
            text        => _loc('Root (/)'),
            nature	=> '',
            description => '',
            data        => {
                id_project => '/',
                project    => '/',
                sw_crear_editar => \1,
            },
            icon       => '/static/images/icons/drive.png',
            leaf       => \1,
            };	    
        }else{
            @datas = ObtenerNodosHijosPrimerNivel($id_project);
        }

        foreach my $data(@datas){
            push @tree, {
            text        => $data->{name} . ($data->{nature}?" (" . $data->{nature} . ")":''),
            nature	=> $data->{nature}?$data->{nature}:"",
            description => $data->{description}?$data->{description}:"",
            data        => {
                id_project => $data->{mid},
                project    => $data->{name},
                sw_crear_editar => \1,
            },	    
            icon       => '/static/images/icons/project_small.png',
            leaf       => \$data->{leaf},
            };
        }
        $c->stash->{json} = \@tree;
    }

    $c->forward('View::JSON');
}

sub ObtenerNodosPrincipalesPrimerNivel(){
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    my $dbh = $db->dbh;
    my $SQL;
    if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
    $SQL = 'SELECT * FROM (SELECT B.MID, B.NAME, 1 AS LEAF, B.NATURE, B.DESCRIPTION, B.ID_PARENT
                   FROM BALI_PROJECT B
                   WHERE B.ID_PARENT IS NULL AND B.ACTIVE = 1
                     AND B.MID NOT IN (SELECT DISTINCT A.ID_PARENT
                              FROM BALI_PROJECT A
                              WHERE A.ID_PARENT IS NOT NULL AND A.ACTIVE = 1) 
                   UNION ALL
                   SELECT E.MID, E.NAME, 0 AS LEAF, E.NATURE, E.DESCRIPTION, E.ID_PARENT
                   FROM BALI_PROJECT E
                   WHERE E.MID IN (SELECT DISTINCT D.MID 
                          FROM BALI_PROJECT D,  
                          BALI_PROJECT C
                          WHERE D.ID_PARENT IS NULL AND C.ACTIVE = 1 AND
                            D.MID = C.ID_PARENT)) RESULT, 
            (SELECT FILA, NIVEL, F.MID, F.NAME, A.NAME AS NAME_PARENT FROM (SELECT ROWNUM AS FILA, LEVEL AS NIVEL, MID, ID_PARENT, NAME FROM BALI_PROJECT A START WITH ID_PARENT IS NULL CONNECT BY PRIOR MID = ID_PARENT) F LEFT JOIN BALI_PROJECT A ON A.MID = F.ID_PARENT) RESULT1
             WHERE RESULT.MID = RESULT1.MID
        ORDER BY FILA ASC';
    }
    else{
    ##INSTRUCCION PARA COMPATIBILIDAD CON SQL SERVER #######################################################################
    $SQL = 'WITH N(LEVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE) AS
        (SELECT 1 AS LEVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE
        FROM BALI_PROJECT
        WHERE ID_PARENT IS NULL AND ACTIVE = 1
        UNION ALL
        SELECT LEVEL + 1, NPLUS1.MID, NPLUS1.ID_PARENT, NPLUS1.NAME, NPLUS1.DESCRIPTION, NPLUS1.NATURE
        FROM BALI_PROJECT AS NPLUS1, N
        WHERE N.MID = NPLUS1.ID_PARENT AND NPLUS1.ACTIVE = 1)
        SELECT W.LEAF, ROW_NUMBER() OVER(ORDER BY N.MID ASC) AS FILA, LEVEL AS NIVEL, N.MID, N.NAME, Z.NAME AS NAME_PARENT,
            N.DESCRIPTION, N.NATURE FROM N LEFT JOIN BALI_PROJECT Z ON Z.MID = N.ID_PARENT,
        (SELECT B.MID, B.NAME, 1 AS LEAF, B.NATURE, B.DESCRIPTION, B.ID_PARENT
                   FROM BALI_PROJECT B
                   WHERE B.ID_PARENT IS NULL AND B.ACTIVE = 1
                     AND B.MID NOT IN (SELECT DISTINCT A.ID_PARENT
                              FROM BALI_PROJECT A
                              WHERE A.ID_PARENT IS NOT NULL AND A.ACTIVE = 1) 
                   UNION ALL
                   SELECT E.MID, E.NAME, 0 AS LEAF, E.NATURE, E.DESCRIPTION, E.ID_PARENT
                   FROM BALI_PROJECT E
                   WHERE E.MID IN (SELECT DISTINCT D.MID 
                          FROM BALI_PROJECT D,  
                          BALI_PROJECT C
                          WHERE D.ID_PARENT IS NULL AND C.ACTIVE = 1 AND
                            D.MID = C.ID_PARENT)) W WHERE N.MID = W.MID ORDER BY FILA ASC ';
    }

    my @datas = $db->array_hash( $SQL );
    
    return @datas;
}

sub ObtenerNodosHijosPrimerNivel(){
    my $id_project = shift;
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    my $dbh = $db->dbh;
    my $SQL;

    if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
        $SQL = 'SELECT * FROM (SELECT B.MID, B.NAME, 1 AS LEAF, B.NATURE, B.DESCRIPTION, B.ID_PARENT
                FROM BALI_PROJECT B
                WHERE B.ID_PARENT = ? AND B.ACTIVE = 1
                  AND B.MID NOT IN (SELECT DISTINCT A.ID_PARENT
                           FROM BALI_PROJECT A
                           WHERE A.ID_PARENT IS NOT NULL AND A.ACTIVE = 1) 
                UNION ALL
                SELECT E.MID, E.NAME, 0 AS LEAF, E.NATURE, E.DESCRIPTION, E.ID_PARENT
                FROM BALI_PROJECT E
                WHERE E.MID IN (SELECT DISTINCT D.MID 
                       FROM BALI_PROJECT D,  
                       BALI_PROJECT C
                       WHERE D.ID_PARENT = ? AND C.ACTIVE = 1 AND
                         D.MID = C.ID_PARENT)) RESULT, 
              (SELECT FILA, NIVEL, F.MID, F.NAME, A.NAME AS NAME_PARENT FROM (SELECT ROWNUM AS FILA, LEVEL AS NIVEL, MID, ID_PARENT, NAME FROM BALI_PROJECT A START WITH ID_PARENT IS NULL CONNECT BY PRIOR MID = ID_PARENT) F LEFT JOIN BALI_PROJECT A ON A.MID = F.ID_PARENT) RESULT1
              WHERE RESULT.MID = RESULT1.MID
         ORDER BY FILA ASC';
    }
    else{
    ##INSTRUCCION PARA COMPATIBILIDAD CON SQL SERVER #######################################################################
    $SQL = 'WITH N(LEVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE) AS
        (SELECT 1 AS LEVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE
        FROM BALI_PROJECT
        WHERE ID_PARENT IS NULL AND ACTIVE = 1
        UNION ALL
        SELECT LEVEL + 1, NPLUS1.MID, NPLUS1.ID_PARENT, NPLUS1.NAME, NPLUS1.DESCRIPTION, NPLUS1.NATURE
        FROM BALI_PROJECT AS NPLUS1, N
        WHERE N.MID = NPLUS1.ID_PARENT AND NPLUS1.ACTIVE = 1)
        SELECT W.LEAF, ROW_NUMBER() OVER(ORDER BY N.MID ASC) AS FILA, LEVEL AS NIVEL, N.MID, N.NAME, Z.NAME AS NAME_PARENT,
            N.DESCRIPTION, N.NATURE FROM N LEFT JOIN BALI_PROJECT Z ON Z.MID = N.ID_PARENT,
        (SELECT B.MID, B.NAME, 1 AS LEAF, B.NATURE, B.DESCRIPTION, B.ID_PARENT
                   FROM BALI_PROJECT B
                   WHERE B.ID_PARENT = ? AND B.ACTIVE = 1
                     AND B.MID NOT IN (SELECT DISTINCT A.ID_PARENT
                              FROM BALI_PROJECT A
                              WHERE A.ID_PARENT IS NOT NULL AND A.ACTIVE = 1) 
                   UNION ALL
                   SELECT E.MID, E.NAME, 0 AS LEAF, E.NATURE, E.DESCRIPTION, E.ID_PARENT
                   FROM BALI_PROJECT E
                   WHERE E.MID IN (SELECT DISTINCT D.MID 
                          FROM BALI_PROJECT D,  
                          BALI_PROJECT C
                          WHERE D.ID_PARENT = ? AND C.ACTIVE = 1 AND
                            D.MID = C.ID_PARENT)) W WHERE N.MID = W.MID ORDER BY FILA ASC ';
    }
         
    my @datas = $db->array_hash( $SQL , $id_project, $id_project);
    
    return @datas;
}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    my $id_project = $p->{_id};
    
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    my $dbh = $db->dbh;
    my $SQL;
    my @datas;

    $p->{id_parent} eq '' and $p->{id_parent} = undef;
    
    given ($action) {
        when ('add') {
            try{
            my $row = $c->model('Baseliner::BaliProject')->search({name => $p->{name}, active => 1})->first;
            if(!$row){
                my $project_mid;
                my $project;
                
                $project_mid = master_new 'project' => $p->{name} => sub {
                    my $mid = shift;			
                    $project = $c->model('Baseliner::BaliProject')->create(
                                {
                                    mid			=> $mid,
                                    name        => $p->{name},
                                    id_parent   => $p->{id_parent} eq '/' ? undef : $p->{id_parent},
                                    nature      => $p->{nature},
                                    description => $p->{description},
                                    active      => '1',
                                });
                };
                
                $c->stash->{json} = { msg=>_loc('Project added'), success=>\1, project_id=> $project->mid };
            }else{
                $c->stash->{json} = { msg=>_loc('Project name already exists, introduce another project name'), failure=>\1 };
            }
            }
            catch{
            $c->stash->{json} = { msg=>_loc('Error adding Project: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {
            try{
                my $project = $c->model('Baseliner::BaliProject')->find( $id_project );
                $project->name( $p->{name} );
                $project->id_parent( $p->{id_parent} eq '/'? undef : $p->{id_parent} );
                $project->nature( $p->{nature} );
                $project->description( $p->{description} );
                $project->update();
                $c->stash->{json} = { msg=>_loc('Project modified'), success=>\1, project_id=> $id_project };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error modifying Project: %1', shift()), failure=>\1 };
            }
        }
        when ('delete') {
            try{
                my $row = $c->model('Baseliner::BaliProject')->find( $id_project );
                $row->active(0);
                $row->update();
                
                if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
                    $SQL = 'SELECT ROWNUM, LEVEL, MID, NAME, DESCRIPTION, NATURE FROM BALI_PROJECT A START WITH ID_PARENT = ? AND ACTIVE = 1 CONNECT BY PRIOR MID = ID_PARENT AND ACTIVE = 1';
                }
                else{
                    ##INSTRUCCION PARA COMPATIBILIDAD CON SQL SERVER #######################################################################
                    $SQL = 'WITH N(LEVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE) AS
                        (SELECT 1 AS LEVEL, MID, ID_PARENT, NAME, DESCRIPTION, NATURE
                        FROM BALI_PROJECT
                        WHERE ID_PARENT IS NULL AND ACTIVE = 1
                        UNION ALL
                        SELECT LEVEL + 1, NPLUS1.MID, NPLUS1.ID_PARENT, NPLUS1.NAME, NPLUS1.DESCRIPTION, NPLUS1.NATURE
                        FROM BALI_PROJECT AS NPLUS1, N
                        WHERE N.MID = NPLUS1.ID_PARENT AND NPLUS1.ACTIVE = 1)
                        SELECT ROW_NUMBER() OVER(ORDER BY N.MID ASC) AS FILA, LEVEL AS NIVEL, N.MID, N.NAME,
                            N.DESCRIPTION, N.NATURE FROM N ';		    
                    
                }
                @datas = $db->array_hash( $SQL, $id_project );
                my @ids_projects_hijos = map $_->{mid}, @datas;
                
                my $rs = $c->model('Baseliner::BaliProject')->search({ mid=>\@ids_projects_hijos});
                $rs->update({ active => 0});
                
                @ids_projects_hijos = map 'project/' . $_, @ids_projects_hijos;
                push @ids_projects_hijos, 'project/' . $id_project;
                $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ ns=>\@ids_projects_hijos });
                $rs->delete;
        
                $c->stash->{json} = {  success => 1, msg=>_loc('Project deleted')};
            }
            catch{
                $c->stash->{json} = {  success => 0, msg=>_loc('Error deleting Project') };
            }
        }
    }

    $c->forward('View::JSON');
}


# old methods:

sub add : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $name = $p->{name};
    try {
        $name or die "Missing name";
        my $ns = $p->{ns};
        $ns ||= $name;
        $ns = "project/$ns" unless $ns =~ /\//;
        my $row = { name => $name, ns => $ns, description => $p->{description} };
        Baseliner->model('Baseliner::BaliProject')->create( $row );
        $c->stash->{json} = { success=>\1, msg=>'ok' };
    } catch {
        my $err = shift;
        _log $err;
        my $msg = _loc("Error adding project %1: %2", $name, $err);
        $c->stash->{json} = { success=>\1, msg=>$msg };
    };
    $c->forward('View::JSON');
}

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/project_grid.js';
}

=head2 all_projects

returns all projects

    include_root => 1     includes the "all prroject" or "/" namespace

=cut
sub all_projects : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'name';
    $dir ||= 'asc';
    $limit ||= 100;
    my $where = {};
    $query and $where = query_sql_build( query=>$query, fields=>[qw/name ns/] );
    my $rs = $c->model('Baseliner::BaliProject')->search($where);
    rs_hashref($rs);
    #my @rows = map { $_->{data}=_load($_->{data}); $_ } $rs->all;
    my @rows = $rs->all;
    $c->stash->{json} = { data => \@rows, totalCount=>scalar(@rows) };		
    $c->forward('View::JSON');
}
sub delete : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    try {
        Baseliner->model('Baseliner::BaliProject')->find($id)->delete;
        $c->stash->{json} = { success=>\1, msg=>'Delete Ok' };
    } catch {
        my $err = shift;
        _log $err;
        my $msg = _loc("Error deleting project %1: %2", $id, $err);
        $c->stash->{json} = { success=>\1, msg=>$msg };
    };
    $c->forward('View::JSON');
}

sub show : Local {
    my ( $self, $c, $id ) = @_;
    my $p = $c->request->parameters;
    $id ||= $p->{id};
    my $prj = Baseliner->model('Baseliner::BaliProject')->search({ mid=>$id })->first;

    $c->stash->{id} = $id;
    $c->stash->{prj} = $prj;
    $c->stash->{template} = '/site/project/project.html';
}

=head2 user_projects

returns the user project json

    include_root => 1     includes the "all prroject" or "/" namespace

=cut
sub user_projects : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'name';
    $dir ||= 'asc';
    $limit ||= 100;
    $query and $query = qr/$query/i;
    my @rows;
    my $username = $c->username;
    my $perm = $c->model('Permissions');
    #@rows =  $perm->user_namespaces( $username ); # user apps

    my $where = {};
    #$where->{username} = $c->username unless $c->is_root;
    #my $rs_ns = Baseliner->model('Baseliner::BaliRoleuser')->search( $where, { select=>'ns', distinct=>1 } )->as_query;
    #@rows = grep { $_ ne '/' } @rows unless $c->is_root || $p->{include_root};
    #@rows = grep { $_ =~ $query } @rows if $query;

    # my $rs = $c->model('Baseliner::BaliProject')->search({ -or=>[ ns=>{ -in=>$rs_ns }, ns=>'/' ] })->hashref;
    
    #$where->{id} = [{-in => Baseliner->model('Permissions')->user_projects_query( username=>$username )}] 
        #unless $c->is_root;
    my $from = { distinct=>1, select=>[qw(mid name ns nature active)]  };
    if( $c->is_root || $p->{include_root} ) {
        #push @{ $where->{id} }, { "=", undef };
    } else {
        $from->{join} = 'roleuser';
    }
    my $rs = $c->model('Baseliner::BaliProject')->search($where, $from)->hashref;
    my @ret;
    for( $rs->all ) {
        next if $query && $_->{ns} !~ $query;
        $_->{data}=_load($_->{data});
        #$_->{ns} = 'project/' . $_->{mid};
        $_->{description} //= $_->{name} // '';
        push @ret, $_;
    }

    $c->stash->{json} = { data => \@ret, totalCount=>scalar(@ret) };		
    $c->forward('View::JSON');
}

1;
