use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;

use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );

    TestEnv->setup();
}
use TestUtils;
use TestGit;

use_ok 'Clarive::App';

subtest 'merges args with config' => sub {
    my $app = Clarive::App->new( config => "$root/../data/acmetest.yml", foo=>'bar' );
    is $app->args->{foo}, 'bar';
    is $app->config->{foo}, 'bar';
};

subtest 'config resolves variables' => sub {
    my $app = Clarive::App->new( config => "$root/../data/acmetest.yml", foo=>'bar', foo2=>'{{foo}}' );
    is $app->config->{foo2}, 'bar';
};

subtest 'features: returns available features' => sub {
    my $app = Clarive::App->new(
        config => "$root/../data/acmetest.yml",
        base   => "$root/../data/app-base",
        home   => "$root/../data/app-base/app-home"
    );

    my @features = $app->features->list;

    is scalar @features, 1;
    like $features[0]->path_to(''), qr{app-base/features/testfeature};
};

subtest 'path_to: returns path relative to home' => sub {
    my $app = Clarive::App->new(
        config => "$root/../data/acmetest.yml",
        base   => "$root/../data/app-base",
        home   => "$root/../data/app-base/app-home"
    );

    my $file = $app->path_to('docs/en/test.markdown');

    ok $file->isa('Path::Class::File');
    like $file, qr{app-base/app-home/docs/en/test.markdown};
};

subtest 'path_to: returns directory object when pointing to a directory' => sub {
    my $app = Clarive::App->new(
        config => "$root/../data/acmetest.yml",
        base   => "$root/../data/app-base",
        home   => "$root/../data/app-base/app-home"
    );

    my $file = $app->path_to('docs/en');

    ok $file->isa('Path::Class::Dir');
};

subtest 'path_to: looks through features too' => sub {
    my $app = Clarive::App->new(
        config => "$root/../data/acmetest.yml",
        base   => "$root/../data/app-base",
        home   => "$root/../data/app-base/app-home"
    );

    my $file = $app->path_to('docs/en/test_feature.markdown');

    like $file, qr{app-base/features/testfeature/docs/en/test_feature.markdown};
};

subtest 'paths_to: returns all available paths' => sub {
    my $app = Clarive::App->new(
        config => "$root/../data/acmetest.yml",
        base   => "$root/../data/app-base",
        home   => "$root/../data/app-base/app-home"
    );

    my @paths = map { "$_" } $app->paths_to('docs/en');

    cmp_deeply \@paths, [ re('plugins/my-plugin/docs/en'), re('app-base/features/testfeature/docs/en'), re('app-home/docs/en') ];
};

subtest 'paths_to: returns all available existings files' => sub {
    my $app = Clarive::App->new(
        config => "$root/../data/acmetest.yml",
        base   => "$root/../data/app-base",
        home   => "$root/../data/app-base/app-home"
    );

    my @paths = $app->paths_to('docs/en/test_feature.markdown');

    is scalar @paths, 1;
    like $paths[0], qr{app-base/features/testfeature/docs/en};
};

subtest 'version: detects version from VERSION file' => sub {
    my $cwd = Cwd::getcwd();

    my $tempdir = tempdir();

    mkdir "$tempdir/config";
    mkdir "$tempdir/clarive";

    TestUtils->write_file("---\n", "$tempdir/config/acmetest.yml");
    TestUtils->write_file("1.2.3", "$tempdir/clarive/VERSION");

    my $app = Clarive::App->new(
        base   => "$tempdir",
        home   => "$tempdir/clarive"
    );

    is $app->version, '1.2.3';

    chdir $cwd;
};

subtest 'version: detects version from .git' => sub {
    my $cwd = Cwd::getcwd();

    my $tempdir = tempdir();

    my $repo = TestGit->create_repo(dir => "$tempdir/clarive");
    TestGit->commit($repo);
    TestGit->tag($repo);

    mkdir "$tempdir/config";
    mkdir "$tempdir/clarive";

    TestUtils->write_file("---\n", "$tempdir/config/acmetest.yml");

    my $app = Clarive::App->new(
        base   => "$tempdir",
        home   => "$tempdir/clarive"
    );

    ok $app->version;

    chdir $cwd;
};

subtest 'version: returns nothing when cannot detect version' => sub {
    my $cwd = Cwd::getcwd();

    my $tempdir = tempdir();

    mkdir "$tempdir/config";
    mkdir "$tempdir/clarive";

    TestUtils->write_file("---\n", "$tempdir/config/acmetest.yml");

    chdir "$tempdir/clarive";

    my $app = Clarive::App->new(
        base   => "$tempdir",
        home   => "$tempdir/clarive"
    );

    is $app->version, '';

    chdir $cwd;
};

done_testing;
