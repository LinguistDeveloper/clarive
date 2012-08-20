my $ns_list = $c->model('Namespaces')->list(
		can_job  => 1,
		does     => 'Baseliner::Role::JobItem',
		start    => 0,
		limit    => 5,
		username => 'ROG2833Z',
		bl       => 'PROD',
		#states   => $p->{states},
		job_type => 'promote',
		query    => 'H0083S0912919@13'
	);
__END__
2010-05-26 18:29:46[651370] [BX::Release::Provider::Release:33] provider list started...
2010-05-26 18:29:47[651370] [BX::Release::Provider::Release:97] provider list finished (records=0/0).
2010-05-26 18:29:47[651370] [BX::CA::Endevor::Provider::Packages:60] provider list started...
Use of uninitialized value in addition (+) at /opt/ca/distribuidor/script/../lib/Baseliner/Model/Namespaces.pm line 159.
Use of uninitialized value in addition (+) at /opt/ca/distribuidor/script/../lib/Baseliner/Model/Namespaces.pm line 160.
2010-05-26 18:29:47[651370] [BX::CA::Harvest::Provider::PackageGroup:36] provider list started...
Use of uninitialized value $value in concatenation (.) or string at /opt/ca/distribuidor/script/../lib/BaselinerX/Type/Model/ConfigStore.pm line 147.
2010-05-26 18:29:47[651370] [BX::CA::Harvest::Provider::PackageGroup:109] provider list finished (records=0/0).
2010-05-26 18:29:47[651370] [BX::CA::Harvest::Provider::Package:34] provider list started...
2010-05-26 18:29:47[651370] [BX::CA::Harvest::Provider::Package:114] provider list finished (records=0/0).
2010-05-26 18:29:47[651370] [B::Model::Namespaces:167] ----------------TOTAL: 0


--- !!perl/hash:Baseliner::Core::NamespaceCollection 
count: 0
data: []

total: 0

