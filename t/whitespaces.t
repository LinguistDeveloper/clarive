use strict;
use warnings;

use Test::Whitespaces {
    dirs   => [ map { "$ENV{CLARIVE_HOME}/$_" } 'bin', 'lib', 't' ],
    ignore => [
        qr/\.sample$/,   qr/\.markdown$/, qr/\.po$/,  qr/\.git\//,
        qr/\/realpath$/, qr/\/cpanm/,     qr/\/stew/, qr/\/cla-worker/,
        qr/\.sw(?:p|o)$/,
    ],
};
