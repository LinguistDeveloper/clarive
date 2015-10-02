use strict;
use warnings;

use Test::More;
use Test::Fatal;

use File::Temp qw(tempfile);
use Baseliner::RequestRecorder::VarsLoader;

subtest 'throws an error when cannot load file' => sub {
    my $vars_loader = _build_vars_loader();

    like exception { $vars_loader->load_from_file('unknown-file') }, qr/Error loading vars from file 'unknown-file'/;
};

subtest 'loads vars from a hash reference' => sub {
    my $vars_loader = _build_vars_loader();

    my ( $fh, $filename ) = tempfile();
    print $fh q#{foo => 'bar'}#;
    close $fh;

    my $vars = $vars_loader->load_from_file($filename);

    is_deeply $vars, { foo => 'bar' };
};

subtest 'loads vars from a code reference' => sub {
    my $vars_loader = _build_vars_loader();

    my ( $fh, $filename ) = tempfile();
    print $fh q#sub {{foo => 'bar'}}#;
    close $fh;

    my $vars = $vars_loader->load_from_file($filename);

    is_deeply $vars, { foo => 'bar' };
};

subtest 'passes vars to code reference' => sub {
    my $vars_loader = _build_vars_loader();

    my ( $fh, $filename ) = tempfile();
    print $fh q#sub { $_[0] }#;
    close $fh;

    my $vars = $vars_loader->load_from_file( $filename, { foo => 'bar' } );

    is_deeply $vars, { foo => 'bar' };
};

sub _build_vars_loader {
    Baseliner::RequestRecorder::VarsLoader->new(@_);
}

done_testing;
