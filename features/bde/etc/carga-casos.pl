use Text::CSV;

my @rows;
my $csv = Text::CSV->new ({ sep_char=>';', binary=>1 })  # should set binary attribute.
                or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf-8)", $c->path_to("features/bde/etc/ecp2.csv") or die "$!";
my @cols;
my %cp;
use List::MoreUtils qw/zip/;
my $cnt=1;
my $errs = 0;
while ( my $row = $csv->getline($fh) ) {
    #$csv->parse( $row ) or do { warn "Linea $cnt: Error '" . $csv->error_diag . "' parseando: $row\n\n"; $errs++; next };
    #$row = [ $csv->fields ];
    #$row->[2] =~ m/pattern/ or next; # 3rd field should match
    if( !@cols ) {
       @cols = map { Util->_name_to_id($_) } @$row;
       next;
    }
    #my @data = map { Util->_to_utf8($_) } @$row;
    my $h = { zip( @cols, @$row ) };
    push @rows, $h;
    $cnt++;
}
close $fh;
#die _dump( \@rows );
#my $estatus = 9; # en curso
my $ecat = 26; # ECP
my $cstatus = 5; # disponible
my $ccat = 28; # Caso de Prueba
my $func_cat = 2;
my $prj_mid = 58; # SCM
my $res = { 'correcto' => 14, 'incorrecto'=>15 };  # ECP Correcto / Incorrecto
my $estatus = 8; # no iniciado
my $ppcat = 29;
my $ppstatus = 12; # Finalizado
my $now = Class::Date->now;

my ($ppmsg, $ppmid, $ppstatus, $pptitle) = Baseliner->model('Topic')->update({
            action=>'add',
            title => "Importación $now",
            description=>'plan importado desde el Excel',
            category => $ppcat,
            status_new => $ppstatus,
            username => $c->username || 'baseliner',
            aplicacion => $prj_mid,
            active => 1,
});

my $i=0;
my $cup = my $eup = my $cadd = my $eadd = 0;
for my $r ( @rows ) {
	#_to_utf8( $r->{description} );
    #utf8::encode( $r->{descripcion} );
    #_log _dump( $r );
    my $pre = [
       grep {  length join '', values %$_ }
       map { 
          +{  
            descripcion=> $$r{"descripcion_pc$_"}, 
            verificado =>$$r{"verificado_pc$_"}, 
           }
       } 1..3
    ];
    my $pasos = [  
       grep {  length join '', values %$_ }
       map { 
           $$r{"salida_obtenida_p$_"} =~ s{
               (\\\\cntdat.*\.\w{3})
            }
            {
                my $link=$1;
                $link=~s{\\}{/}g;
                my $n = ($link=~m{/.*/([^/]+?)\.}) ? $1 : substr( $link, 0, -10) . '...';
                #$link = URI::Escape::uri_escape( "file:$link" );
                qq{<a href="file:$link" target="_blank" onclick="javascript:window.open('file:$link');return false">$n</a>}
            }xei;
          +{  
            descripcion=> $$r{"descripcion_p$_"}, 
            datos_de_entrada=>$$r{"entrada_manual_p$_"}, 
            juego_de_pruebas => $$r{"sct_test_p$_"}, 
            resultado_esperado=>$$r{"resultado_esperado_p$_"},
            salida_obtenida => $$r{"salida_obtenida_p$_"}
           }
       } 1..3
    ];
    my $title = "$r->{id} $r->{titulo}";
    # CASO 
    my $func = DB->BaliTopic->search({ 'lower(title)'=>{ -like=>'%'.lc($$r{funcionalidades}).'%'}, id_category=>$func_cat },{ select=>'mid' })->first
    	if length $$r{funcionalidades};    
    my @deps = DB->BaliTopic->search({ 'lower(title)'=>{ -like=>'%'.lc($$r{dependencias_cps}).'%'}, id_category=>$ccat },{ select=>'mid' })->hashref->all
    	if length $$r{dependencias_cps};
    my $cexists = DB->BaliTopic->search({ title=>$title, id_category=>$ccat })->first;
    my ($cmsg, $cmid, $cstatus, $ctitle) = Baseliner->model('Topic')->update({
            ( $cexists 
                ? ( action=>'update', topic_mid=>$cexists->mid )
                : ( action=>'add' ) 
            ),
            title => $title,
            description=>$r->{descripcion} // '',
            category => $ccat,
            status_new => $cstatus,
            dependencias => [ map { $_->{mid} } @deps ],
            ( $func ? ( funcionalidades => [ $func->mid ] ) : () ),
            username => $c->username || 'baseliner',
            pasos => _to_json([ map { delete $_->{salida_obtenida}; $_ } _array $pasos]),
            precondiciones => _to_json([ map { delete $_->{verificado}; $_ } _array $pre]),
            aplicacion => $prj_mid,
            active => 1,
        });
    #$func and DB->BaliMasterRel->find_or_create({ from_mid=>$cmid, to_mid=>$func->mid, rel_type=>'topic_topic', rel_field=>'funcionalidades' });        
    for my $dep ( @deps ) {
        #DB->BaliMasterRel->find_or_create({ from_mid=>$cmid, to_mid=>$dep->{mid}, rel_type=>'topic_topic', rel_field=>'dependencias' });
    }

    # EJECUCION
    my $rcp= Util->_trim(lc($$r{resultado_cp}.''));
    my $eexists = DB->BaliTopic->search({ title=>$title, id_category=>$ecat })->first;
    my ($emsg, $emid, $estatus, $etitle) = Baseliner->model('Topic')->update({
            ( $eexists 
                ? ( action=>'update', topic_mid=>$eexists->mid )
                : ( action=>'add' ) 
            ),
            title => $title,
            description=>$r->{descripcion} // '',
            category => $ecat,
            username => $c->username || 'baseliner',
            pasos => _to_json($pasos),
            caso_de_prueba => [$cmid],
            precondiciones => _to_json($pre),
            proyecto => $prj_mid,
            active => 1,
            status_new => $res->{$rcp} // $estatus,
        });
    
    # añadir al plan de pruebas de importacion
    DB->BaliMasterRel->find_or_create({ from_mid=>$ppmid, to_mid=>$emid, rel_type=>'topic_topic', rel_field=>'casos_de_prueba' });    
    $eexists ? $eup++ : $eadd++;
    $cexists ? $cup++ : $cadd++;
    last if ++$i > 10;
}
say "Casos Nuevos: $cadd, Casos Act.: $cup, Ejecuciones Nuevas: $eadd, Ejecuciones Actualizadas: $eup";
say "Total: @{[$errs+$cnt-1]}, Ok: @{[$cnt-1]}, Errores: $errs";