my $r = $c->model('Baseliner::BaliJob')->find(1260);
my $now = _dt();
my $today = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day ) ;
$today = $today + DateTime::Duration->new( days=>1 );
print $today;
my $grouping='';
my $day;
my $dur =  $today - $r->starttime ;
my $sdt = $r->starttime;
        $sdt->{locale} = DateTime::Locale->load( $c->languages->[0] || 'en' );
print _dump $dur;
        $day =
            $dur->{months} > 3 ? [ 90, _loc('Older') ]
          : $dur->{months} > 2 ? [ 80, _loc( '%1 Months', 3 ) ]
          : $dur->{months} > 1 ? [ 70, _loc( '%1 Months', 2 ) ]
          : $dur->{months} > 0 ? [ 60, _loc( '%1 Month',  1 ) ]
          : $dur->{days} >= 21  ? [ 50, _loc( '%1 Weeks',  3 ) ]
          : $dur->{days} >= 14  ? [ 40, _loc( '%1 Weeks',  2 ) ]
          : $dur->{days} >= 7   ? [ 30, _loc( '%1 Week',   1 ) ]
          : $dur->{days} == 6   ? [ 7,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 5   ? [ 6,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 4   ? [ 5,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 3   ? [ 4,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 2   ? [ 3,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 1    ? [ 2,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 0  ? [ 1,  _loc('Today') ]
          :                      [ 0,  _loc('Upcoming') ];
 $grouping = $day->[0];
print _dump($day)
 

__END__
2010-06-02T00:00:00--- !!perl/hash:DateTime::Duration 
days: 1
end_of_month: wrap
minutes: 774
months: 0
nanoseconds: 0
seconds: 0
--- 
- 2
- lunes

1
