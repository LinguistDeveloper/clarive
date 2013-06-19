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
    
    # match each file pos with file line
    my @lines;
    my $i = 0;
    while ( $d =~ /(\r?\n)/gsm ) {
        push @lines, [ ++$i, $+[1] ];
    }
    
    my $find_line = sub {
        my $pos = shift;
        # find which line
        [
            map { $_->[0] } grep { $pos >= $_->[1] } reverse @lines
        ]->[0];
    };

    while ( $d =~ /(\n.*\n)?(,\s*\n*[\]\}])/gsm ) {
        my $err = $2;
        my $lin = $find_line->( $+[2] );
        say "*** Leftover comma in $f (line $lin): $err";
        $cnt++;
    }

    while ( $d =~ /( (?:default\s*\:)|(?:\.default[\W\s]) )/xgsm ) {
        my $err = $1;
        my $lin = $find_line->( $+[1] );
        say "*** IE keyword default in $f (line $lin): $err";
    }
    # jslint ?
    #system qw/jsl -process /, $f;

});

say ">> Found $cnt leftover commas.";
