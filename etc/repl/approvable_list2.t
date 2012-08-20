my $list = Baseliner->model('Namespaces')->list(
     does => ['Baseliner::Role::Approvable'],
     bl   => 'PREP',
);
for my $ns ( $list->search( provider=>'harvest' )->sort( on=>'ns_name') ) {
print $ns->ns, "\n";

}

__END__
harvest.package/Ficheros Comunes PREP
harvest.package/H0000S9999999@01
harvest.package/H0083S0912919@01 carga baseliner
harvest.package/H0188I01424518@1 - VMPA176A
harvest.package/H0188I01444959@1
harvest.package/H0188I01445483@1 - VMPA176A
harvest.package/H0188I01447637@1 I1447637PRTI00150001
harvest.package/H0188I01450120@1  JAD5906B  22-02-10  I1450120PRTI00002001
harvest.package/H0188I01454307@1 - VMPA176A
harvest.package/H0188I01457434@1  JAD5906B  02-03-10  I1457434PRTI07750001
harvest.package/H0188S0003303@01 - P3303PRTP10001_01
harvest.package/H0188S0950055@04
harvest.package/H0188S0950557@01 - VMM7190Q 2010-02-18
harvest.package/H0188S0950945@02 - P0950945PRTP10001002
harvest.package/H0188S0951104@03  JAD5906B  24-02-10  P0951104PRTP02501002
harvest.package/H0188S0951187@01 - VMM7190Q 2010-02-26
harvest.package/H0188S0951345@03 TAREA 16 P0951345PRTP10001003
harvest.package/H0188S0951345@04 - VMM7190Q 2010-02-25
harvest.package/H0188S0951358@01 - VMPA176A - P0950945PRTP10001002
harvest.package/H0188S0951358@02 TAREA 12 P0951358PRTP10001001
harvest.package/H0188S0951358@03 - VMPA176A - P0951358PRTP10001002
harvest.package/H0188S0951518@03 - GRJ8121J - 2010-02-04
harvest.package/H0188S1000008@01 - VMM7190Q 2010-01-28
harvest.package/H0188S1000015@02 - VMM7190Q 2010-01-26
harvest.package/H0188S1000067@01 TAREA 7 P1000067PRTP21000001
harvest.package/H0188S1000087@01 - Rivas - P0951474PRTP07080001
harvest.package/H0188S1000169@02 TAREA 11 P1000169PRTP01001001
harvest.package/H0188S1000414@01 -  SCG1531L - 20100217
harvest.package/H0188S1000433@01 TAREA 3 P1000433PRTP10001001
harvest.package/H0188S1000435@01 TAREA 03 P1000435PRTP10001001
harvest.packagegroup/PG.0188.Version 8.31
harvest.package/PVCS DESA
harvest.packagegroup/TARJETAS SOLRED

2010-05-05 20:15:29 [10680] [BX::Release::Provider::Release:31] - provider list started...
2010-05-05 20:15:29 [10680] [BX::Release::Provider::Release:95] - provider list finished (records=1/1).
2010-05-05 20:15:29 [10680] [BX::CA::Endevor::Provider::Packages:58] - provider list started...
2010-05-05 20:15:30 [10680] [BX::CA::Endevor:73] - Running rexx...
2010-05-05 20:15:37 [10680] [BX::CA::Endevor:75] - Parsed 203 lines.
2010-05-05 20:15:37 [10680] [BX::CA::Endevor:77] - CSV of 48 elements.
2010-05-05 20:15:38 [10680] [BX::CA::Endevor::Provider::Packages:139] - provider list finished (records=1/1).
2010-05-05 20:15:38 [10680] [BX::CA::Harvest::Provider::PackageGroup:34] - provider list started...
2010-05-05 20:15:38 [10680] [BX::CA::Harvest::Provider::PackageGroup:102] - provider list finished (records=2/2).
2010-05-05 20:15:38 [10680] [BX::CA::Harvest::Provider::Package:32] - provider list started...
2010-05-05 20:15:40 [10680] [BX::CA::Harvest::Provider::Package:112] - provider list finished (records=31/31).
2010-05-05 20:15:40 [10680] [B::Model::Namespaces:156] - ----------------TOTAL: 35



