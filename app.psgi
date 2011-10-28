use lib './lib';
use Baseliner;

Baseliner->setup_engine('PSGI');
my $app = sub { Baseliner->run(@_) };
