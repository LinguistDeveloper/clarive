use v5.10;
use Baseliner::Utils;
use Digest::MD5;
die qq{
Baseliner md5 digest

usage:

    bali md5 <string>

} unless @ARGV;
say Digest::MD5::md5_hex( shift() );
