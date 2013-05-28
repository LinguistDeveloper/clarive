package Clarive::Role::TempDir;
use Mouse::Role;
use v5.10;

requires 'home';

has tmp_dir    => qw(is rw lazy 1 default), sub {
    my $self = shift;
    # TMPDIR
    my $tmpdir = $ENV{CLARIVE_TEMP} || join('/', $self->home, 'tmp' );
    unless( -d $tmpdir ) {
        require File::Path;
        File::Path::make_path( $tmpdir );
    }
    $tmpdir;
};


1;
