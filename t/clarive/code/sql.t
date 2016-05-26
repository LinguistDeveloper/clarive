use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

BEGIN {
    plan skip_all => 'DBD::SQLite is required to run this tests' unless eval { require DBD::SQLite };
}

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

require DBIx::Simple;

use_ok 'Clarive::Code::SQL';

my $tempdir = tempdir();
my $db      = "$tempdir/test.db";
my $dbix    = DBIx::Simple->connect("dbi:SQLite:dbname=$db") or die DBIx::Simple->error;

subtest 'eval_code: throws when no connection line is found' => sub {
    my $code = _build_code();

    like exception { $code->eval_code('SELECT * FROM `table`') }, qr/Missing first line DBI connect string/;
};

subtest 'eval_code: returns sql execution' => sub {
    _setup();

    my $code = _build_code();

    my $ret = $code->eval_code(<<"EOF");
DBI:SQLite:dbname=$db;host=;port=,,

INSERT INTO `table` (`foo`) VALUES ('bar');
EOF

    is_deeply $ret,
      [
        {
            'Statement'     => 'INSERT INTO `table` (`foo`) VALUES (\'bar\')',
            'Error Code'    => undef,
            'Rows'          => 1,
            'Error Message' => undef
        }
      ];
};

subtest 'eval_code: returns sql selection' => sub {
    _setup();

    my $code = _build_code();

    $dbix->dbh->do("INSERT INTO `table` (`foo`) VALUES ('bar')");

    my $ret = $code->eval_code(<<"EOF");
DBI:SQLite:dbname=$db;host=;port=,,

SELECT `foo` FROM `table`;
EOF

    is_deeply $ret, [ { foo => 'bar' } ];
};

done_testing;

sub _setup {
    $dbix->dbh->do(<<'EOF') || die $!;
DROP TABLE IF EXISTS `table`;
EOF
    $dbix->dbh->do(<<'EOF') || die $!;
CREATE TABLE `table` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `foo` varchar(40)
);
EOF
}

sub _build_code {
    Clarive::Code::SQL->new(@_);
}
