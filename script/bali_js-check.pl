use v5.10;
use strict;
use Path::Class;

my $dir = shift || 'root';
say "Javascript Checker. Running for $dir...";
die "Error: $dir does not exist\n" unless -e $dir;

dir($dir)->recurse(callback=>sub{
    my $f=shift;
    return unless $f =~ /\.js|\.mas$/;
    my $d = $f->slurp;

    for my $err ( $d =~ /(\n.*\n)(,\s+[\]|\}])/gsm ) {
        say "Leftover comma in $f: $err";
    }

});
