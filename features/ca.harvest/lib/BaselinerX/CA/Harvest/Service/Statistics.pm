package BaselinerX::CA::Harvest::Service::Statistics;
use Baseliner::Plug;
use Baseliner::Utils;

sub compute_stats {
	my ($self)=@_;
	my $db = Baseliner::Core::DBI->new( model=>'Harvest' );
	$db->do(q{ANALYZE TABLE HARITEMS COMPUTE STATISTICS;});
	$db->do(q{ANALYZE TABLE HARVERSIONS COMPUTE STATISTICS;});
	$db->do(q{ANALYZE TABLE HARVERSIONINVIEW COMPUTE STATISTICS;});
}

sub delete_stats {
	my ($self)=@_;
	my $db = Baseliner::Core::DBI->new( model=>'Harvest' );
	$db->do(q{exec dbms_utility.analyze_schema('UHARVEST','DELETE');});
	$db->do(q{exec dbms_stats.delete_schema_stats('UHARVEST')});
}

1;
