package BaselinerX::Service::ScanPackages;
use Baseliner::Moose;
BEGIN { extends 'Catalyst::Controller' }
no warnings 'redefine';
use utf8;
use v5.10;

service scan => {
    handler=>sub{
        my ($self,$c,$config) = @_;
    }
};

sub begin {
    my ($self,$c) = @_;
    $c->stash->{skip_auth} = 1;
}

sub scan {
    my ($self, %p)=@_;
    use Baseliner::Utils;
    
    # get project
    my $cam = substr($p{cam},0,3);
    _fail( 'falta el parámetro cam' ) unless $cam;
    
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

    # get items for each package  XXX better to do an aggregate on repo of top items
    while( my($name, $rev) = each %pkg_valid ) {
        my @items = $rev->items;
        for my $nat ( @natures ) {
            # should return/update nature accepted items
            $nat->scan( items=>\@items );   
        }
        _log( \@items );
    
        my $tag_relationship = 'topic_item';
        for my $it ( @items ) {
            $it->save;
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
                    _log( \@targets );
                    for my $mid ( @targets ) {
                        DB->BaliMasterRel->find_or_create({ to_mid=>$it->mid, from_mid=>$mid, rel_type=>$tag_relationship });
                    }
                }
                # item_item relationships
            }
        }
        
        _log( \@natures );
        $_->save for @natures;  # commit new items
        
    }
    
    # crear plan de pruebas
    my ($msg, $topic_mid, $status, $title) = Baseliner->model('Topic')->update({
            action => 'add',
            title => 'Plan 0001',
            description=>'',
            category => 5,
            username => 'internal',
            active => 1,
            #status => 83,
        });

    
    # asociar casos para las funcs afectadas
    _log( \@funcs );
    DB->BaliMaster->search({ mid=>\@funcs, 'parents.rel_type'=>'topic_topic' },
        { prefetch=>'parents' })->hashref->each(sub{
        my $func = shift;
        _log "Funcionalidad: " . $func->{name}; 
        _log $func;
        # detectar casos de prueba
        
        # copiar Caso de Prueba a Ejecución
        
        # asociar ejecución a plan
        
    });

    # asociar paquetes al plan
    
    
    # buscar planes de prueba activos para el mismo paquete y desactivarlos
    

    
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

=cut
