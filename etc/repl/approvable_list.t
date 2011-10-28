my $list = Baseliner->model('Namespaces')->list(
     does => ['Baseliner::Role::Approvable'],
     bl   => 'PREP',
);
for my $ns ( grep {
   $_->provider =~ /release/

} _array $list->{data} ) {
print $ns->ns, "\n";

}

__END__
release/R.0188.S091201.la de prep

2010-05-05 18:39:50 [ 6067] [BX::Release::Provider::Release:31] - provider list started...
2010-05-05 18:39:50 [ 6067] [BX::Release::Provider::Release:95] - provider list finished (records=1/1).
2010-05-05 18:39:50 [ 6067] [BX::CA::Endevor::Provider::Packages:58] - provider list started...
2010-05-05 18:39:51 [ 6067] [BX::CA::Endevor:73] - Running rexx...
2010-05-05 18:39:57 [ 6067] [BX::CA::Endevor:75] - Parsed 203 lines.
2010-05-05 18:39:57 [ 6067] [BX::CA::Endevor:77] - CSV of 48 elements.
2010-05-05 18:39:58 [ 6067] [BX::CA::Endevor::Provider::Packages:139] - provider list finished (records=1/1).
2010-05-05 18:39:58 [ 6067] [BX::CA::Harvest::Provider::PackageGroup:34] - provider list started...
2010-05-05 18:39:58 [ 6067] [BX::CA::Harvest::Provider::PackageGroup:102] - provider list finished (records=2/2).
2010-05-05 18:39:58 [ 6067] [BX::CA::Harvest::Provider::Package:32] - provider list started...
2010-05-05 18:40:00 [ 6067] [BX::CA::Harvest::Provider::Package:112] - provider list finished (records=31/31).
2010-05-05 18:40:00 [ 6067] [B::Model::Namespaces:155] - ----------------TOTAL: 35



