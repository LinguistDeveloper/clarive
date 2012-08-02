use v5.10;
use strict;
use Path::Class;

my $dir = shift || './root';
say "Javascript Checker. Running for $dir...";
die "Error: $dir does not exist\n" unless -e $dir;

my $cnt = 0;

dir($dir)->recurse(callback=>sub{
    my $f=shift;
    return unless $f =~ /(\.js|\.mas)$/i;
    #say $f->basename;
    my $d = $f->slurp;

    for my $err ( $d =~ /(\n.*\n)?(,\s*\n*[\]\}])/gsm ) {
        say "Leftover comma in $f: $err";
        $cnt++;
    }

    # jslint ?
    #system qw/jsl -process /, $f;

});

say ">> Found $cnt leftover commas.";
