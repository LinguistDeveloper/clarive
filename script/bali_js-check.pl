use v5.10;
use strict;
use Path::Class;

say "Javascript Checker. Running...";

dir("root")->recurse(callback=>sub{
    my $f=shift;
    return unless $f =~ /\.js$/;
    my $d = $f->slurp;

    for my $err ( $d =~ /(\n.*\n)(,\s+[\]|\}])/gsm ) {
        say "Leftover comma in $f: $err";
    }

});
