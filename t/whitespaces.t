use strict;
use warnings;

use Test::Whitespaces {
    dirs   => [ 'bin', 'lib', 't' ],
    ignore => [
        qr/\.sample$/,   qr/\.markdown$/, qr/\.po$/,  qr/\.git\//,
        qr/\/realpath$/, qr/\/cpanm/,     qr/\/stew/, qr/\/cla-worker/,
        qr/\.swp$/,
    ],
};
