package BaselinerX::Service::ScanPackages;
use Baseliner::Moose;
BEGIN { extends 'Catalyst::Controller' }
no warnings 'redefine';
use utf8;
use v5.10;
use Try::Tiny;

__PACKAGE__->config->{namespace} = 'bde_scan';

service scan => {
    handler=>sub{
        my ($self,$c,$config) = @_;
        Util->_reload_dir( 'lib/BaselinerX/CI' );
        Util->_reload_dir( 'features/ca.harvest/lib', qr/CI/ );
        Util->_reload_dir( 'features/bde/lib', qr/Scan/ );
        $self->scan(
            cam=>'SCM',
            packages => ['SCM.N.0000002 modificaciones1']
        );
    }
};

sub begin : Private {
    my ($self,$c) = @_;
    $c->stash->{auth_skip} = 1;
}

sub run : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    
    try {
        my $plan = $self->scan(
           cam=> $p->{project},
           packages => $p->{packages},
           username => $p->{username},
           state => $p->{state},
           view => $p->{view},   # o bl
        );
        $c->res->body( _loc('Creado plan de pruebas %1', $plan ) );
    } catch {
        $c->res->status( 500 );
        $c->res->body( _loc('Error al crear plan de pruebas %1', shift() ) );
    };
}

sub scan {
    my ($self, %p)=@_;
    use Baseliner::Utils;
    
    my $username = $p{username} || 'baseliner';
    
    # get project
    my $cam = substr($p{cam},0,3);
    _fail( 'falta el parámetro cam' ) unless $cam;
    
    # bl
    my $bl = $p{bl} // 'ANTE';
    
    my $prj_mid = DB->BaliMaster->search({ name=>$cam }, { order_by=>'mid' })->first;
    _fail( "Proyecto $cam no encontrado" ) unless $prj_mid;
    $prj_mid = $prj_mid->mid;
    
    # get revisions
    my @packages = _array( $p{packages} );
    _fail('Falta el parámetro packages') unless @packages;
    
    # project load packages
    my $prj = _ci( $prj_mid );
    $_->load_revisions( name=>\@packages ) for _array( $prj->repositories );
    
    my %pkg_valid = map { $_ => 0 } _array( $p{packages} );
    my @pkgs = DB->BaliMaster->search({ name=>$p{packages} })->hashref->all;
    for my $pkg_row ( @pkgs ) {
        my $pkg_mid = $pkg_row->{mid};
        $pkg_valid{ $pkg_row->{name} } = _ci( $pkg_mid );
    }
    my @invalid = grep { ! ref $pkg_valid{$_} } keys %pkg_valid;
    _fail( 'Paquetes no encontrados: ' . join ',', @invalid ) if @invalid;
    
    # get natures
    my @natures;
    for my $natclass ( packages_that_do( 'Baseliner::Role::CI::Nature' ) ) {
        my $coll = $natclass->collection;
        DB->BaliMaster->search({ collection=>$coll })->each( sub {
            my ($row)=@_;
            _log( $row->mid );
            push @natures, _ci( $row->mid );
        });
    }
    
    my @funcs;

    my %top_ver;
    
    # get items for each package  XXX better to do an aggregate on repo of top items
    while( my($name, $rev) = each %pkg_valid ) {
        my @items = $rev->items;
        for my $nat ( @natures ) {
            # should return/update nature accepted items
            $nat->scan( items=>\@items );   
        }
        #_log( \@items );
    
        my $tag_relationship = 'topic_item';
        

        $_->save for @items;
        
        for my $it ( @items ) {
            
            # aggregate max version
            if( ! exists $top_ver{ $it->path } ) {
                $top_ver{ $it->path } = $it;
            } elsif( $top_ver{$it->path}->versionid < $it->versionid ) {
                $top_ver{ $it->path } = $it;
            }

# $it->tree_resolve
            # nature associations
            # parse_tree 
            for my $t ( _array( $it->{parse_tree} ) ) {
                # moniker should be module a modulename
                if( my $module = $t->{module} ) {
                    $it->moniker( $module ) ;
                    $it->save;
                }
                # tags for topics, etc
                if( my $tag = $t->{tag} ) {
                    my @targets =  map { $_->{mid} } DB->BaliMaster->search({ moniker=>$tag }, { select=>'mid' })->hashref->all;
                    push @funcs, @targets;
                    for my $mid ( @targets ) {
                        DB->BaliMasterRel->find_or_create({ to_mid=>$it->mid, from_mid=>$mid, rel_type=>$tag_relationship });
                    }
                }
                # item_item relationships
                if( my $tag = $t->{depend} ) {
                    my @targets =  map { $_->{mid} } DB->BaliMaster->search({ moniker=>$tag }, { select=>'mid' })->hashref->all;
                    for my $mid ( @targets ) {
                        DB->BaliMasterRel->find_or_create({ to_mid=>$it->mid, from_mid=>$mid, rel_type=>'item_item' });
                    }
                }
            }
        }
        
        _log( \@natures );
        $_->save for @natures;  # commit new items
        
    }
    
    my $categories = {
        pp => 5,
        cp => 122,
        ecp => 123,
    };
    
    my $statuses = {
        pp => 1, 
        cp => 83,  # para seleccionar, no crear
        ecp => 83,
    };
    
    # crear plan de pruebas
    my ($msg, $pp_topic_mid, $status, $pp_title) = Baseliner->model('Topic')->update({
            action => 'add',
            title => "Plan $cam-$bl " . Class::Date->now(),
            description=>'Plan de pruebas creado automáticamente desde CASCM',
            category => $categories->{pp},
            username => $username,
            Proyectos => $prj_mid,
            Proyecto => $prj_mid,
            active => 1,
            status_new => $statuses->{pp},
        });
    _log( "-----> Creado plan de pruebas " . $pp_topic_mid . " - " . $pp_title );
    
    # asociar casos para las funcs afectadas
    _log( \@funcs );
    my %casos;
    DB->BaliMaster->search({ mid=>\@funcs, 'parents.rel_type'=>'topic_topic' },
        { prefetch=>'parents' })->hashref->each(sub{
        my $func = shift;
        _log "Funcionalidad: " . $func->{name}; 
        _log $func;
        # detectar casos de prueba en estado OK (no definición)
        DB->BaliMasterRel->search(
            { from_mid=>$func->{mid}, rel_type=>'topic_topic', id_category=>122, id_category_status=>83 },
            { prefetch=>'topic_topic' }
        )->hashref->each(sub{
            my $cp = shift;
            $casos{ $cp->{topic_topic}{mid} } = $cp->{topic_topic};
        });
    });
    
    for my $caso_mid ( keys %casos ) {
        my $caso_data = $casos{ $caso_mid };
        # copiar Caso de Prueba a Ejecución
        my $meta = Baseliner->model('Topic')->get_meta( $caso_mid, $categories->{cp} );
        my $data = Baseliner->model('Topic')->get_data( $meta, $caso_mid );
        my ( $msg, $ecp_topic_mid, $status, $title ) = Baseliner->model('Topic')->update(
            {
                action         => 'add',
                title          => sprintf( 'PP %s - Ejecución %s', $pp_topic_mid, $caso_data->{title} ),
                description    => '',
                caso_de_prueba => $caso_mid,
                category       => $categories->{ecp},
                proyecto       => $prj_mid,
                pasos          => $data->{pasos},
                precondiciones => $data->{precondiciones},
                descripcion    => $data->{description},
                username       => $username,
                active         => 1,
                status_new     => $statuses->{ecp},
            }
        );

        # asociar ejecución a plan
        DB->BaliMasterRel->find_or_create({ from_mid=>$pp_topic_mid, to_mid=>$ecp_topic_mid, rel_type=>'topic_topic' });
    }
        
    # asociar paquetes al plan
    while( my($name, $rev) = each %pkg_valid ) {
        DB->BaliMasterRel->find_or_create({ from_mid=>$pp_topic_mid, to_mid=>$rev->mid, rel_type=>'topic_revision' });
        # TODO agregado
    }
    
    # asociar versiones al plan
    for my $it ( values %top_ver ) {
        DB->BaliMasterRel->find_or_create({ from_mid=>$pp_topic_mid, to_mid=>$it->mid, rel_type=>'topic_item' });
    }
    
    # asociar casos de prueba dependientes de otro caso de prueba (se deben de incluir en el plan de pruebas)
    #     dependencias automáticamente tienen que estar antes 
    
    # buscar planes de prueba activos para el mismo paquete y desactivarlos
    

    return $pp_title;    
}

1;

=pod 

.-------------------------------------+--------------------------------------.
| Parameter                           | Value                                |
+-------------------------------------+--------------------------------------+
| Proyectos                           | 255                                  |
| _cis                                | []                                   |
| action                              | update                               |
| category                            | 23                                   |
| ci                                  |                                      |
| description                         | NAT:BIZTALK                          |
| form                                |                                      |
| items                               | 6648                                 |
| moniker                             | nat_biz                              |
| priority                            |                                      |
| progress                            | 0                                    |
| status                              | 83                                   |
| status_new                          | 83                                   |
| title                               | NAT:BIZTALK                          |
| topic_mid                           | 6606                                 |
| txt_deadline_expr_min               | -1                                   |
| txt_rsptime_expr_min                | -1                                   |
| txtcategory_old                     |                                      |
| txtdeadline                         |                                      |
| txtrsptime                          |                                      |
'-------------------------------------+--------------------------------------'

.-------------------------------------+--------------------------------------.
| Parameter                           | Value                                |
+-------------------------------------+--------------------------------------+
| _cis                                | []                                   |
| action                              | add                                  |
| caso_de_prueba                      |                                      |
| category                            | 123                                  |
| comentarios                         |                                      |
| description                         |                                      |
| form                                |                                      |
| moniker                             |                                      |
| pasos                               |                                      |
| priority                            |                                      |
| progress                            |                                      |
| status                              |                                      |
| status_new                          | 86                                   |
| title                               | dfasdfs                              |
| topic_mid                           | -1                                   |
| txt_deadline_expr_min               | -1                                   |
| txt_rsptime_expr_min                | -1                                   |
| txtcategory_old                     |                                      |
| txtdeadline                         |                                      |
| txtrsptime                          |                                      |
'-------------------------------------+--------------------------------------'

=cut
