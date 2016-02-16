use strict;
use warnings;
use lib 't/lib';

use Test::More;

use TestEnv;

use Cwd ();
my $root;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );

    TestEnv->setup();
}

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

done_testing;
