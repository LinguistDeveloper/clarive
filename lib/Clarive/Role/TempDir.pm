package Clarive::Role::TempDir;
use Mouse::Role;
use v5.10;

has tmp_dir    => qw(is rw lazy 1 default), sub {
    # TMPDIR
    my $tmpdir = $ENV{BASELINER_TEMP} || join('/', , 'tmp' );
    unless( -d $tmpdir ) {
        require File::Path;
        File::Path::make_path( $tmpdir );
    }
    $tmpdir;
};


1;
