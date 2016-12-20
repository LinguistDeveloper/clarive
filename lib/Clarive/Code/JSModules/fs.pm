package Clarive::Code::JSModules::fs;
use strict;
use warnings;

use File::Spec;
use Encode ();
use Baseliner::Utils qw(_fail);
use Clarive::Code::JSUtils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        slurp => js_sub {
            my ( $file, $encoding ) = @_;

            _fail 'file required' unless $file;

            $file = Encode::encode( 'UTF-8', $file );

            local $/;
            my $layer = $class->_encoding_to_layer($encoding);
            open my $fh, "<$layer", $file or _fail "Cannot open file $file: $!";
            my $data = <$fh>;
            close $fh; # checking for close error is not needed, since it is ro

            return $data if $layer;

            return bless( \$data, 'JavaScript::Duktape::Buffer' );
        },
        openFile => js_sub {
            my ( $file, $mode, $encoding ) = @_;

            _fail 'file required' unless $file;

            $mode ||= 'r';

            _fail 'Unknown mode' unless $mode =~ m/^(?:r|w)$/;

            $file = Encode::encode( 'UTF-8', $file );

            my $perl_mode = $mode eq 'r' ? '<' : '>';

            my $layer = $class->_encoding_to_layer($encoding);
            open my $fh, "$perl_mode$layer", $file or _fail "Cannot open file $file: $!";

            return {
                write => js_sub {
                    my ($data) = @_;

                    print $fh $data;
                },
                readChunk => js_sub {
                    my ($length) = @_;

                    local $/ = \$length;

                    my $chunk = <$fh>;

                    return bless( \$chunk, 'JavaScript::Duktape::Buffer' );
                },
                readLine => js_sub {
                    my $line = <$fh>;

                    return $line if $layer;

                    return bless( \$line, 'JavaScript::Duktape::Buffer' );
                },
                eof => js_sub {
                    to_duk_bool( eof($fh) );
                },
                fileno => js_sub {
                    return fileno($fh);
                },
                close => js_sub {
                    close $fh or _fail "Cannot close file $file: $!";
                }
            };
        },
        stat => js_sub {
            my ($file) = @_;
            my @st = stat $file;

            return {
                file => $file,
                ( map { $_ => shift(@st) } qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks) )
            };
        },
        iterateDir => js_sub {
            my ( $dir, $cb ) = @_;

            _fail 'directory required'          unless $dir;
            _fail 'callback required'           unless $cb;
            _fail 'callback must be a function' unless ref $cb eq 'CODE';

            $dir = Encode::encode( 'UTF-8', $dir );

            opendir my $dh, $dir or _fail "Cannot open directory $dir: $!";
            foreach my $f ( readdir $dh ) {
                $f = Encode::decode( 'UTF-8', $f );

                $cb->( $f, File::Spec->catfile( $dir, $f ) );
            }
            closedir $dh;
        },
        isDir      => js_sub { to_duk_bool( !!-d $_[0] ) },
        isFile     => js_sub { to_duk_bool( !!-f $_[0] ) },
        createFile => js_sub {
            my ( $file, $content ) = @_;

            $file    = Encode::encode( 'UTF-8', $file );
            $content = Encode::encode( 'UTF-8', $content );

            open my $fh, '>', $file or die "Cannot create file $file: $!";
            print $fh $content if defined $content;
            close $fh or _fail "Cannot close file $file: $!";

            to_duk_bool(1);
        },
        createDir => js_sub {
            my ($dir) = @_;

            $dir = Encode::encode( 'UTF-8', $dir );

            to_duk_bool( mkdir($dir) );
        },
        createPath => js_sub {
            my ($dir) = @_;

            $dir = Encode::encode( 'UTF-8', $dir );

            to_duk_bool( Util->_mkpath($dir) );
        },
        deleteFile => js_sub {
            to_duk_bool( unlink $_[0] );
        },
        deleteDir => js_sub {
            to_duk_bool( rmdir $_[0] );
        },
    };
}

sub _encoding_to_layer {
    my $class = shift;
    my ($encoding) = @_;

    $encoding ||= 'UTF-8';

    my $layer;
    if ( uc($encoding) eq 'UTF-8') {
        $layer = ':encoding(UTF-8)';
    }
    elsif ( $encoding eq 'raw' ) {
        $layer = '';
    }
    else {
        die "Unknown file encoding '$encoding'\n";
    }

    return $layer;

}

1;
