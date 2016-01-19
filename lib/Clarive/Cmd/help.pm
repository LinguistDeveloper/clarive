package Clarive::Cmd::help;
use Mouse;
use Path::Class;
use v5.10;

our $CAPTION = 'This help';

sub run {
    my ($self, %opts)=@_;
    print <<FIN;
Clarive - Copyright(C) 2010-2016 Clarive Software, Inc.

usage: cla [-h] [-v] [--config file] command <command-args>

FIN

    my $subcommand = ref $opts{''} ? $opts{''}->[0] : $opts{''};
    my @cmds;
    for my $lib ( @INC ) {
        push @cmds, glob "$lib/Clarive/Cmd/*";   
    } 
    my @cmd_msg;
    my $main_caption;
    for my $cmd ( sort { uc $a cmp uc $b } @cmds ) {
        next if -d $cmd;    
        my $pkg = $cmd =~ /Clarive\/Cmd\/(.*).pm$/ ? $1 : undef;
        next if $subcommand && $pkg ne $subcommand;
        if( $pkg ) {
            $pkg =~ s{\/+}{::}g;
            $pkg = 'Clarive::Cmd::' . $pkg;
            eval "require $pkg";
            push @cmd_msg => $@ if $@;;
        }
        no strict 'refs';
        my $fn = file($cmd)->basename =~ /^(.*)\.pm$/ ? $1 : $cmd; 
        if( $subcommand ) {
            $main_caption = ${$pkg . '::CAPTION'} // '??';
            for ( grep /^run_/, grep { defined &{"$pkg\::$_"} } keys %{"$pkg\::"} ) {
                s/^run_//g;
                s/_/-/g;
                push @cmd_msg => sprintf "    %s-%s", $fn, $_;
            }
        } else {
            my $caption = ${$pkg . '::CAPTION'} // '??';
            my $cmd_id = ${$pkg . '::CMD_ALIAS'} // $fn; 
            push @cmd_msg => sprintf "    %-12s %-80s", $cmd_id, $caption;
        }
    }
    if( $subcommand && !@cmd_msg ) {
        say "No subcommands available for $subcommand ($main_caption)";
    } else {
        say $subcommand ? "Subcommands available for $subcommand ($main_caption):" : 'Commands available:';
        say '';
        say for @cmd_msg;
        print <<FIN;
    
cla help <command> to get all subcommands.
cla <command> -h for command options.

FIN
    }
}

1;
__DATA__

