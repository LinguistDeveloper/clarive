use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Baseliner::Tail';

subtest 'read: returns file' => sub {
    my $tempdir = tempdir();

    TestUtils->write_file( "hello\nthere", "$tempdir/file.txt" );

    my $tail = _build_tail( file => "$tempdir/file.txt" );

    my $buf = $tail->read;

    is $buf, "hello\nthere";
};

subtest 'read: returns empty buf on eof' => sub {
    my $tempdir  = tempdir();
    my $filepath = "$tempdir/file.txt";

    TestUtils->write_file( "hello\nthere", $filepath );

    my $tail = _build_tail( file => $filepath );

    $tail->read;

    is $tail->read, '';
};

subtest 'read: throws when file is gone' => sub {
    my $tempdir  = tempdir();
    my $filepath = "$tempdir/file.txt";

    TestUtils->write_file( "hello\nthere", $filepath );

    my $tail = _build_tail( file => $filepath );

    unlink $filepath;

    is $tail->read, "hello\nthere";

    ok !defined $tail->read;
};

subtest 'read: returns tail' => sub {
    my $tempdir  = tempdir();
    my $filepath = "$tempdir/file.txt";

    TestUtils->write_file( "hello\nthere", $filepath );

    open my $fh, '>', $filepath;
    autoflush $fh 1;

    print $fh 'hel';

    my $tail = _build_tail( file => $filepath );

    is $tail->read, 'hel';

    print $fh 'lo';

    is $tail->read, 'lo';

    print $fh "\nthere!";

    is $tail->read, "\nthere!";

    is $tail->read, '';

    print $fh 'again';

    is $tail->read, 'again';
};

subtest 'read: buffers escape seqs' => sub {
    my $tempdir  = tempdir();
    my $filepath = "$tempdir/file.txt";

    TestUtils->write_file( "hello\nthere", $filepath );

    open my $fh, '>', $filepath;
    autoflush $fh 1;

    print $fh "\033[0;31mbetween\033\[";

    my $tail = _build_tail( file => $filepath );

    is $tail->read, "\033[0;31mbetween";

    print $fh "0";

    is $tail->read, '';

    print $fh "mlalala\033[0;31";

    is $tail->read, "\033\[0mlalala";

    print $fh 'mend';

    is $tail->read, "\033\[0;31mend";
};

done_testing;

sub _build_tail {
    Baseliner::Tail->new(@_);
}
