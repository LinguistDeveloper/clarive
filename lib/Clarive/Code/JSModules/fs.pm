package Clarive::Code::JSModules::fs;
use strict;
use warnings;

use File::Spec;

use Baseliner::Utils qw(_fail);
use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js = shift;

    +{
        slurp => js_sub {
            my ($file) = @_;

            local $/;
            my $data;
            open my $fh, '<', $file or _fail "Cannot open file $file: $!";
            $data = <$fh>;
            close $fh or _fail "Cannot close $file: $!";

            return $data;
        },
        openFile => js_sub {
            my ( $file, $mode ) = @_;

            _fail 'file required' unless $file;

            $mode = 'r' unless $mode && $mode =~ m/^r|w$/;
            my $perl_mode = $mode eq 'r' ? '<' : '>';

            open my $fh, $perl_mode, $file or _fail "Cannot open file $file: $!";

            return {
                write => js_sub {
                    my ($data) = @_;

                    print $fh $data;
                },
                binMode => js_sub {
                    binmode($fh);
                },
                readChunk => js_sub {
                    my ($length) = @_;
                    local $/ = \$length;
                    <$fh>;
                },
                readLine => js_sub {
                    <$fh>;
                },
                eof => js_sub {
                    eof( $fh );
                },
                fileno => js_sub {
                    fileno($fh);
                },
                close => js_sub {
                    close $fh or _fail "Cannot close $file: $!";
                }
            };
        },
        stat => js_sub {
            my ($file) = @_;
            my @st = stat $file;
            +{
                file => $file,
                ( map { $_ => shift(@st) } qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks) )
            }
        },
        iterateDir => js_sub {
            my ($dir, $cb) = @_;

            opendir my $dh, $dir or _fail "Cannot open dir $dir: $!";
            foreach my $f ( readdir $dh ) {
                $cb->($f, File::Spec->catfile($dir,$f) );
            }
            closedir $dh;
        },
        isDir  => js_sub { !!-d $_[0] },
        isFile => js_sub { !!-f $_[0] },
        createFile => js_sub {
            my ( $file, $content ) = @_;

            open my $fh, '>', $file or die "Cannot create file $file: $!";
            print $fh $content if defined $content;
            close $fh;
        },
        deleteFile => js_sub {
            to_duk_bool( unlink $_[0] );
        },
        deleteDir => js_sub {
            to_duk_bool( rmdir $_[0] );
        },
        createDir => js_sub {
            my ($dir) = @_;

            mkdir $dir;
        },
        createPath => js_sub {
            my ($dir) = @_;

            to_duk_bool( Util->_mkpath( $dir ) );
        },
    }
}

1;
