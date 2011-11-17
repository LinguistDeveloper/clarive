package BaselinerX::SQL::Utils;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Exporter::Tidy default => [qw/_folder_ora_data/];

sub _folder_ora_data {
  my ($cam, $carpeta, $entorno) = @_;
  my @folder = split(/\\+|\/+/, $carpeta);
  my $folder = "\\$folder[1]\\$folder[2]";
  my %instancias;
  my $i      = 2;
  my $har_db = BaselinerX::CA::Harvest::DB->db;
  $cam = uc($cam);
  do {
    my $query = qq{
      SELECT ora_instancia
        FROM bde_paquete_oracle
       WHERE UPPER (ora_prj) = '$cam'
         AND ora_entorno = '$entorno'
         AND ora_fullname = '$folder'
         AND ora_desplegar = 'Si'
    };
    _log $query;
    my @result = $har_db->array($query);
    _log Data::Dumper::Dumper \@result;
    for my $inst (@result) {
      my $oid = $1 if $inst =~ m/^.*\_.*\_(.*)$/;
      my $sql2 = qq{
        SELECT HOST
          FROM inf_instance
          WHERE OID = '$oid'
      };
      my $server = $har_db->value($sql2);
      _log "query:\n$sql2";
      _log "server:$server";
      $instancias{$inst} = $server;
    }
    ++$i;
    $folder .= "\\$folder[$i]" if ($i < scalar @folder);
  } while ($i < scalar @folder);
  \%instancias;
}

1;
