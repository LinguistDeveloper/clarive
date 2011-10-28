package BaselinerX::SQL::Utils;
use strict;
use warnings;
use Baseliner::Utils;
use 5.010;
use Exporter::Tidy default => [qw/ _folder_ora_data /];

sub _folder_ora_data {
  my ($cam, $carpeta, $entorno) = @_;
  my @folder = split(/\\+|\/+/, $carpeta);
  my $folder = "\\$folder[1]\\$folder[2]";
  my %instancias;
  my $i = 2;
  my $har_db = BaselinerX::CA::Harvest::DB->db;
  do {
    my $query = "SELECT ORA_INSTANCIA FROM BDE_PAQUETE_ORACLE WHERE UPPER(ORA_PRJ) = '" . uc($cam) . "' AND ORA_ENTORNO = '$entorno' AND ORA_FULLNAME = '$folder' AND ORA_DESPLEGAR = 'Si'";
    my @result = $har_db->array($query);
    for my $inst (@result) {
      my $oid = $1 if $inst =~ m/^.*\_.*\_(.*)$/;
      my $server = $har_db->value("select host from inf_instance where oid = '$oid'");
      $instancias{$inst} = $server;
    }
    ++$i;
    $folder .= "\\$folder[$i]" if ($i < scalar @folder);
  } while ($i < scalar @folder);
  \%instancias;
}

1;
