use v5.10;
use Baseliner::Utils;
use BaselinerX::Comm::Balix;

my %args = _get_options( @ARGV );
#my $b = BaselinerX::Comm::Balix->new( host=>$args{host}, port=>$args{port}, key=>$args{key}, os=>$args{ );
my $b = BaselinerX::Comm::Balix->new( %args );
my ($rc, $ret ) = $b->execute( $args{cmd} || 'ls' );
$b->close;
say "RC=$rc";
say $ret;
