use Text::CSV;

my @rows;
my $csv = Text::CSV->new ({ sep_char=>';' })  # should set binary attribute.
                or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(utf-8)", $c->path_to("features/bde/etc/ecp1.csv") or die "$!";
my @cols;
my %cp;
use List::MoreUtils qw/zip/;
my $cnt=1;
my $errs = 0;
while ( my $row = <$fh> ) {
    $csv->parse( $row ) or do { warn "Linea $cnt: Error '" . $csv->error_diag . "' parseando: $row\n\n"; $errs++; next };
    $row = [ $csv->fields ];
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
#my $estatus = 9; # en curso
my $ecat = 26; # ECP
my $cstatus = 5; # disponible
my $ccat = 28; # Caso de Prueba
my $prj_mid = 58; # SCM
my $res = { 'correcto' => 14, ''=>15 };  # ECP Correcto / Incorrecto
my $estatus = 15; # en curso

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
    my $func = DB->BaliTopic->search({ 'lower(title)'=>{ -like=>'%'.lc($$r{funcionalidades}).'%'} },{ select=>'mid' })->first;        
    my @deps = DB->BaliTopic->search({ 'lower(title)'=>{ -like=>'%'.lc($$r{dependencias_cps}).'%'} },{ select=>'mid' })->hashref->all;
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
            username => $c->username || 'baseliner',
            pasos => _to_json([ map { delete $_->{salida_obtenida}; $_ } _array $pasos]),
            precondiciones => _to_json([ map { delete $_->{verificado}; $_ } _array $pre]),
            proyecto => $prj_mid,
            active => 1,
        });
    $func and DB->BaliMasterRel->find_or_create({ from_mid=>$cmid, to_mid=>$func->mid, rel_type=>'topic_topic', rel_field=>'funcionalidades' });        
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
            precondiciones => _to_json($pre),
            proyecto => $prj_mid,
            active => 1,
            status_new => $res->{$rcp} // $estatus,
        });
        
    $eexists ? $eup++ : $eadd++;
    $cexists ? $cup++ : $cadd++;
    #last if ++$i > 1;
}
say "Casos Nuevos: $cadd, Casos Act.: $cup, Ejecuciones Nuevas: $eadd, Ejecuciones Actualizadas: $eup";
say "Total: @{[$errs+$cnt-1]}, Ok: @{[$cnt-1]}, Errores: $errs";