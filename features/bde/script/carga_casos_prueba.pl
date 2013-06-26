use Text::CSV;
 
my @rows;
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                or die "Cannot use CSV: ".Text::CSV->error_diag ();
 
open my $fh, "<:encoding(iso-8859-15)", "/Users/rod/work/BdE/QA-Pruebas-2013/SCMSGPDI - Matriz de Casos de Prueba.csv" or die "$!";
my @cols;
my %cp;
use List::MoreUtils qw/zip/;
while ( my $row = $csv->getline( $fh ) ) {
    #$row->[2] =~ m/pattern/ or next; # 3rd field should match
    if( !@cols ) {
       @cols = map { Util->_name_to_id($_) } @$row;
       next;
    }
    my @data = map { Util->_to_utf8($_) } @$row;
    my $h = { zip( @cols, @data ) };
    push @rows, $h;
}
my $i=0;
for( @rows ) {
    my ($msg, $pp_topic_mid, $status, $pp_title) = Baseliner->model('Topic')->update({
            action => 'add',
            title => "$_->{id} $_->{titulo}",
            description=>'Plan de pruebas creado automáticamente desde CASCM',
            category => 122,
            username => 'clarive',
            #Proyectos => ,
            #Proyecto => $prj_mid,
            active => 1,
            status_new => 83,
        });
    last if ++$i > 5;
}

