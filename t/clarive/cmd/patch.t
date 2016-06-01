use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Clarive::Cmd::patch;

subtest 'run_create: creates patch distribution' => sub {
    _setup();

    my $tempdir = tempdir();
    TestUtils->write_file( 'some-patch',  "$tempdir/my.patch" );
    TestUtils->write_file( 'some-patch2', "$tempdir/my2.patch" );

    my $cmd = _build_cmd();
    $cmd->run_create(
        'quiet'  => 1,
        'old'    => '1.0',
        'new'    => '2.0',
        'diff'   => [ "$tempdir/my.patch", "$tempdir/my2.patch" ],
        'output' => "$tempdir/patch.tar.gz"
    );

    my $files = `tar tvf $tempdir/patch.tar.gz`;

    like $files, qr/VERSION\.old/;
    like $files, qr/VERSION\.new/;
    like $files, qr/0001\.patch/;
    like $files, qr/0002\.patch/;
};

subtest 'run_apply: throws when cannot open patch' => sub {
    _setup();

    my $tempdir = tempdir();
    my $app     = _build_app($tempdir);
    my $cmd     = _build_cmd( app => $app );

    like exception { $cmd->run_apply( patch => "$tempdir/unknown" ) }, qr/Can't open.*unknown/;
};

subtest 'run_apply: throws when cannot detect current version' => sub {
    _setup();

    my $tempdir = tempdir();
    my $app     = _build_app($tempdir);
    my $cmd     = _build_cmd( app => $app );

    TestUtils->write_file( 'some-patch2', "$tempdir/patch.tar.gz" );

    like exception { $cmd->run_apply( patch => "$tempdir/patch.tar.gz" ) }, qr/Can't open.*VERSION/;
};

subtest 'run_apply: apply patches' => sub {
    _setup();

    my $tempdir = tempdir();
    my $app     = _build_app($tempdir);
    my $cmd     = _build_cmd( app => $app );

    mkdir "$tempdir/clarive";
    TestUtils->write_file( 'content1', "$tempdir/clarive/file1" );
    TestUtils->write_file( 'content2', "$tempdir/clarive/file2" );
    TestUtils->write_file( '1.0',      "$tempdir/clarive/VERSION" );

    TestUtils->write_file( 'update', "$tempdir/file1.new" );
    my $diff = `cd $tempdir; diff -Naur clarive/file1 file1.new`;
    $diff =~ s{--- clarive/}{--- a/};
    $diff =~ s{\+\+\+ file1.new}{+++ b/file1};
    TestUtils->write_file( $diff, "$tempdir/file1.new.patch" );

    $cmd->run_create(
        'quiet'  => 1,
        'old'    => '1.0',
        'new'    => '2.0',
        'diff'   => ["$tempdir/file1.new.patch"],
        'output' => "$tempdir/patch.tar.gz"
    );

    $cmd->run_apply( quiet => 1, patch => "$tempdir/patch.tar.gz" );

    like( TestUtils->slurp_file("$tempdir/clarive/file1"),   qr/update/ );
    like( TestUtils->slurp_file("$tempdir/clarive/VERSION"), qr/2\.0/ );

    ok -f "$tempdir/clarive/file1.orig";
    ok -f "$tempdir/clarive/VERSION.orig";
};

subtest 'run_apply: does not apply in dry-run mode' => sub {
    _setup();

    my $tempdir = tempdir();
    my $app     = _build_app($tempdir);
    my $cmd     = _build_cmd( app => $app );

    mkdir "$tempdir/clarive";
    TestUtils->write_file( 'content1', "$tempdir/clarive/file1" );
    TestUtils->write_file( 'content2', "$tempdir/clarive/file2" );
    TestUtils->write_file( '1.0',      "$tempdir/clarive/VERSION" );

    TestUtils->write_file( 'update', "$tempdir/file1.new" );
    my $diff = `cd $tempdir; diff -Naur clarive/file1 file1.new`;
    $diff =~ s{--- clarive/}{--- a/};
    $diff =~ s{\+\+\+ file1.new}{+++ b/file1};
    TestUtils->write_file( $diff, "$tempdir/file1.new.patch" );

    $cmd->run_create(
        'quiet'  => 1,
        'old'    => '1.0',
        'new'    => '2.0',
        'diff'   => ["$tempdir/file1.new.patch"],
        'output' => "$tempdir/patch.tar.gz",
    );

    $cmd->run_apply( quiet => 1, patch => "$tempdir/patch.tar.gz", 'dry-run' => 1 );

    like( TestUtils->slurp_file("$tempdir/clarive/file1"),   qr/content1/ );
    like( TestUtils->slurp_file("$tempdir/clarive/VERSION"), qr/1\.0/ );
};

subtest 'run_rollback: rollbacks patches' => sub {
    _setup();

    my $tempdir = tempdir();
    my $app     = _build_app($tempdir);
    my $cmd     = _build_cmd( app => $app );

    mkdir "$tempdir/clarive";
    TestUtils->write_file( 'content1', "$tempdir/clarive/file1" );
    TestUtils->write_file( 'content2', "$tempdir/clarive/file2" );
    TestUtils->write_file( '1.0',      "$tempdir/clarive/VERSION" );

    TestUtils->write_file( 'update', "$tempdir/file1.new" );
    my $diff = `cd $tempdir; diff -Naur clarive/file1 file1.new`;
    $diff =~ s{--- clarive/}{--- a/};
    $diff =~ s{\+\+\+ file1.new}{+++ b/file1};
    TestUtils->write_file( $diff, "$tempdir/file1.new.patch" );

    $cmd->run_create(
        'quiet'  => 1,
        'old'    => '1.0',
        'new'    => '2.0',
        'diff'   => ["$tempdir/file1.new.patch"],
        'output' => "$tempdir/patch.tar.gz"
    );

    $cmd->run_apply( quiet => 1, patch => "$tempdir/patch.tar.gz" );

    $cmd->run_rollback( quiet => 1, patch => "$tempdir/patch.tar.gz" );

    like( TestUtils->slurp_file("$tempdir/clarive/file1"),   qr/content1/ );
    like( TestUtils->slurp_file("$tempdir/clarive/VERSION"), qr/1\.0/ );
};

subtest 'run_rollback: does not rollback when dry-run mode' => sub {
    _setup();

    my $tempdir = tempdir();
    my $app     = _build_app($tempdir);
    my $cmd     = _build_cmd( app => $app );

    mkdir "$tempdir/clarive";
    TestUtils->write_file( 'content1', "$tempdir/clarive/file1" );
    TestUtils->write_file( 'content2', "$tempdir/clarive/file2" );
    TestUtils->write_file( '1.0',      "$tempdir/clarive/VERSION" );

    TestUtils->write_file( 'update', "$tempdir/file1.new" );
    my $diff = `cd $tempdir; diff -Naur clarive/file1 file1.new`;
    $diff =~ s{--- clarive/}{--- a/};
    $diff =~ s{\+\+\+ file1.new}{+++ b/file1};
    TestUtils->write_file( $diff, "$tempdir/file1.new.patch" );

    $cmd->run_create(
        'quiet'  => 1,
        'old'    => '1.0',
        'new'    => '2.0',
        'diff'   => ["$tempdir/file1.new.patch"],
        'output' => "$tempdir/patch.tar.gz"
    );

    $cmd->run_apply( quiet => 1, patch => "$tempdir/patch.tar.gz" );

    $cmd->run_rollback( quiet => 1, patch => "$tempdir/patch.tar.gz", 'dry-run' => 1 );

    like( TestUtils->slurp_file("$tempdir/clarive/file1"),   qr/update/ );
    like( TestUtils->slurp_file("$tempdir/clarive/VERSION"), qr/2\.0/ );
};

done_testing;

sub _setup {
    TestUtils->setup_registry;
}

sub _build_cmd {
    my (%params) = @_;

    return Clarive::Cmd::patch->new( app => $Clarive::app, opts => {}, @_ );
}

sub _build_app {
    my ($base) = @_;

    return Clarive::App->new(
        env    => 'acmetest',
        home   => "$base/clarive",
        base   => $base,
        config => 't/data/acmetest.yml'
    );
}
