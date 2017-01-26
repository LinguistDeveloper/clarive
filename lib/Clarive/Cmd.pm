package Clarive::Cmd;
use Mouse;
use v5.10;

use Class::Load qw(is_class_loaded try_load_class load_class);
use List::MoreUtils qw(uniq);

has app => qw(is ro required 1),
            handles=>[qw/
                lang
                env
                home
                base
                debug
                trace
                verbose
                args
                argv
                pos
            /];

# command opts have the app opts + especific command opts from config
has opts   => qw(is ro isa HashRef required 1);
has help   => qw(is rw default 0);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p = @_;
    $p{help} //= 1 if exists $p{h};
    $self->$orig( %p );
};

sub BUILD {
    my $self = shift;

    # this runs when you do cla help <cmd>

    if( $self->help ) {
        print STDERR $self->help_header;
        print STDERR $self->cli_options;
        print STDERR $self->subcommands;
        print STDERR "\ntry: cla help <command> for command documentation\n";

        exit 0;
    }
};

sub show_cla_help {
    my $self = shift;

    print STDERR $self->help_header;
    my @commands = $self->locate_all_commands;
    print STDERR "Available commands:\n";
    for my $found ( @commands ) {
        my $cmd = $found->{cmd};
        if( my $caption = $found->{caption} ) {
            say STDERR sprintf '    %-20s %s', $cmd, $caption;
        } else {
            say STDERR "    $cmd";
        }
    }
    say STDERR "\ntry:\n    cla help <command> for command documentation";
    say STDERR "    cla <command> -h for command options";
}


sub show_help {
    my $self = shift;

    my $help_doc =
        $self->help_header
        . $self->help_doc( @_ )
        . "\n"
        . "try: cla <command> -h for command options\n";

    print STDERR $help_doc;
}

sub help_doc {
    my $self = shift;
    my (%opts) = @_;

    my $cmd = $self->command_name;
    my $lang = $opts{lang} // 'en';

    require Baseliner::Utils;
    my $home_dir =  $opts{docs_home} // $opts{home} // Clarive->home;
    my $filename = Util->_file( $home_dir, "docs/$lang/cmd/cla-$cmd.markdown" );

    open my $fm, '<', $filename
       or do {
           print STDERR "ERROR: no documentation for command $cmd (file: $filename)\nCommand options:";
           print STDERR $self->cli_options;
           exit 1;
       };
    my $markdown = do { local $/; <$fm> };

    return $self->_markdown_to_term( $markdown );
}

sub _markdown_to_term {
    my $self = shift;
    my ($str) = @_;

    my $BOLD = "\e[1m";
    my $UNDL = "\e[4m";
    my $NORM = "\e[m";

    my ( $yaml, $body ) = $str =~ m{^(---.*?)---(.*)$}s;
    my $title = eval { Util->_load( $yaml )->{title} } // '';

    $body =~ s{`([^`]+)`}{$BOLD$1$NORM}g;
    $body =~ s{\*\*([^\*]+)\*\*}{$BOLD$1$NORM}g;
    $body =~ s{\n#+\s+([^\n]+)}{\n$UNDL$1$NORM\n}g;

    my $final = "\n$UNDL$title$NORM\n$body";

    $final =~ s{\n\n\n+}{\n\n}g;  # limit to 1 empty line
    $final =~ s{\n+$}{\n}g;  # no ending in >1 newline
    return $final;
}

sub check_cli_options {
    my $self = shift;
    my %params = @_;

    my @missing;

    my %attributes =
        map { $_->name => $_ }
        ( $self->_get_cli_attributes, Clarive::App->meta->get_all_attributes );

    for my $arg ( grep { length } keys %{ $params{args} || {} } ) {
        if( !exists $attributes{$arg} ) {
            push @missing, $arg;
        }
    }

    return @missing;
}

sub cli_options {
    my $self = shift;

    my $txt = "Available options:\n";
    for my $attr ( $self->_get_cli_attributes ) {
        my $tc = !$attr->type_constraint ? ''
            : do {
                my $tc_name = lc $attr->type_constraint->name;
                $tc_name = '0|1' if $tc_name eq 'bool';
                "<$tc_name>";
            };
        $txt .= sprintf "    --%s %s\n", $attr->name , $tc;
    }

    return $txt;
}

sub command_name {
    my $self = shift;

    ( $self->meta->name =~ /::([^:]*?)$/ )[0];
}

sub _get_cli_attributes {
    my $self = shift;
    return sort { uc( $a->name ) cmp uc( $b->name ) }
           grep { $_->name !~ /^(opts|app)$/ }
           $self->meta->get_all_attributes;
}

sub load_command {
    my $self = shift;
    my ($app, $cmd, $opts) = @_;

    $cmd //= $self->command_name;
    $app //= Clarive->app;

    my ( $cmd_package, $runsub );

    # special command processing?
    my ($altrun, $altcmd, $cmd_long);
    if( $cmd =~ /\./ ) {
        $cmd_long = 'bali';
        $opts->{service_name} = $cmd;
    }
    elsif( my @cmds = split '-', $cmd  ) {
        $cmd_long = join '::', @cmds;
        if( @cmds > 1 ) {
            $altcmd = $cmds[0];
            $altrun = join '_', @cmds[1..$#cmds];
        }
    }

    # try to find cmd in plugins
    if( $app ) {
        ( $cmd_package, $runsub ) = $app->plugins->load_command( $cmd );
    }

    # load package
    if( ! $cmd_package ) {
        $cmd_package = $self->load_package_for_command( $cmd_long, $altcmd );

        $runsub = $altrun ? "run_$altrun" : 'run';
    }

    if( ! $cmd_package ) {
        die "ERROR: command $cmd not found\n";
    }

    # check if method is available
    if( ! $cmd_package->can( $runsub ) ) {
        die "ERROR: command $cmd not available (${cmd_package}::${runsub})\n";
    }

    if( $app && $app->verbose ) {
        say STDERR "cmd_package: $cmd_package";
        say STDERR "cmd opts: " . $app->yaml( $opts );
    }

    # check if option exists
    if( $cmd_package->is_strict && ( my @missing = $cmd_package->check_cli_options( args=>$opts->{args} ) ) ){
        for my $arg ( @missing ) {
            print STDERR "[ERROR] $cmd: invalid option `$arg`\n";
        }
        print STDERR "For more help try:\n    cla help $cmd\n    cla $cmd -h\n";
        exit 80;
    }

    return ( $cmd_package, $runsub );
}

sub is_strict {
    my $self = shift;
    return $self->meta->does_role('Clarive::CmdStrict');
}

sub help_header {
    my $year = ( localtime() )[5] + 1900;
    $year = 2016 if $year < 2016; # something is wrong with the machine, let's be coherent

    <<FIN;
Clarive - Copyright(C) 2010-$year Clarive Software, Inc.

usage: cla [-h] [-v] [--config file] command <command-options>

FIN
}

sub locate_all_commands {
    my $self = shift;
    my (%opts) = @_;

    my @commands;

    # locate all the command files available in @INC
    my @cmd_files;
    for my $lib ( @INC ) {
        push @cmd_files, glob "$lib/Clarive/Cmd/*";
    }

    for my $cmd_file ( sort { uc $a cmp uc $b } uniq @cmd_files ) {
        next if -d $cmd_file;

        my ($cmd) = $cmd_file =~ /Clarive\/Cmd\/(.*).pm$/;

        if( my $pkg = $self->load_package_for_command( $cmd ) ) {
            push @commands, { cmd=>$cmd, caption=>$pkg->command_caption };
        }
    }

    return @commands;
}

sub command_caption {
    my $self = shift;

    my $class = ref $self || $self;
    my $main_caption;

    {
        no strict 'refs';
        $main_caption = ${$class . '::CAPTION'} // '';
    }

    return $main_caption;
}

sub list_subcommands {
    my $self = shift;
    my ($cmd, %opts) = @_;

    my $class = ref $self || $self;

    $cmd //= $self->command_name;

    try_load_class( $class );

    my @subcommands;

    {
        no strict 'refs';

        my @subs = sort grep { defined &{"$class\::$_"} } keys %{"$class\::"};

        for ( grep /^run_/, @subs ) {
            s/^run_//g;
            s/_/-/g;
            push @subcommands, "$cmd-$_";
        }
    }

    return @subcommands;
}

sub load_package_for_command {
    my $self = shift;
    my @cmds = @_;

    my $package;

    for my $cmd ( grep { length } @cmds ) {
        my $pkg = $cmd // $self->command_name;
        $pkg =~ s{\/+}{::}g;
        $pkg = 'Clarive::Cmd::' . $pkg;

        my ($ok, $error) = try_load_class( $pkg );

        if(  $ok ) {
            $package = $pkg;
        } else {
            if( $error =~ /^Can't locate Clarive\/Cmd\// ) {
                next;
            } else {
                die "ERROR: loading command $cmd ($pkg):\n$error\n";
            }
        }
    }

    return $package;
}

sub subcommands {
    my $self = shift;
    my ($cmd, %opts) = @_;

    $cmd //= $self->command_name;

    my $txt = '';

    # foreach command, print some info
    my @subcommands = $self->list_subcommands( $cmd, %opts );

    my $main_caption = $self->command_caption;
    $main_caption = $main_caption ? " ($main_caption)" : '';

    if( !@subcommands ) {
        $txt = "\nNo subcommands available for cla $cmd$main_caption";
    } else {
        $txt .= "\nSubcommands available for cla $cmd$main_caption:\n";
        $txt .= "    cla $_\n" for @subcommands;
    }

    return $txt;
}

1;
