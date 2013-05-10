package Clarive::Cmd::help;
use Mouse;
use Path::Class;
use v5.10;

our $CAPTION = 'This help';

sub run {
    my ($self, %opts)=@_;
    print <<FIN;
CLARIV\N{U+0404} | software - Copyright (c) 2013 VASSLabs 

usage: cla [-h] [-v] [--config file] command <command-args>

FIN

    my $subcommand = ref $opts{''} ? $opts{''}->[0] : $opts{''};
    my @cmds;
    for my $lib ( @INC ) {
        push @cmds, glob "$lib/Clarive/Cmd/*";   
    } 
    say $subcommand ? "Subcommands available for $subcommand" : 'Commands available:';
    say '';
    for my $cmd ( sort { uc $a cmp uc $b } @cmds ) {
        next if -d $cmd;    
        my $pkg = $cmd =~ /Clarive\/Cmd\/(.*).pm$/ ? $1 : undef;
        next if $subcommand && $pkg ne $subcommand;
        if( $pkg ) {
            $pkg =~ s{\/+}{::}g;
            $pkg = 'Clarive::Cmd::' . $pkg;
            eval "require $pkg";
            say $@ if $@;;
        }
        no strict 'refs';
        my $fn = file($cmd)->basename =~ /^(.*)\.pm$/ ? $1 : $cmd; 
        if( $subcommand ) {
            for ( grep /^run_/, grep { defined &{"$pkg\::$_"} } keys %{"$pkg\::"} ) {
                s/^run_//g;
                s/_/-/g;
                say sprintf "    %s-%s", $fn, $_;
            }
        } else {
            my $caption = ${$pkg . '::CAPTION'} // '??';
            say sprintf "    %-12s %-80s", $fn, $caption;
        }
    }
    print <<FIN;
    
Use cla help <command> to get all subcommands.
FIN
}

1;
__DATA__

