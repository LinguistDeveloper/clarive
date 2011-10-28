use Baseliner::Core::DBI;
my $dbh = Baseliner::Core::DBI->new({ model=>'Harvest' });
$dbh->do('begin inf_data_update; end;')

__END__
--- 1

