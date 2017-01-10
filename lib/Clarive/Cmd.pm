package Clarive::Cmd;
use Mouse;
use v5.10;

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
has help => qw(is rw default 0);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p = @_;
    $p{help} //= 1 if exists $p{h};
    $self->$orig( %p );
};

sub BUILD {
    my $self = shift;
    # placeholder for role hooks
    if( $self->help ) {
        $self->show_help;
        exit 0;
    }
};

sub show_help {
    my $self = shift;
    require Pod::Text::Termcap;
    my $pkg = ref $self;
    $self->_pod_for_package( $pkg );
    for my $role( $self->meta->calculate_all_roles ) {
        $self->_pod_for_package( $role->name );
    }
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

sub _pod_for_package {
    my ($self, $pkg) = @_;
    $pkg =~ s/::/\//g;
    $pkg = "$pkg.pm";
    if( -e(  my $file = $INC{ $pkg } ) ) {
        my $parser = Pod::Text::Termcap->new( indent=>2, sentence=>0 );
        #my $output;
        #$parser->output_string( \$output );
        $parser->parse_from_file( $file );
        #print "OUT=$output";
    } else {
        die "ERROR: file for $pkg not found\n";
    }
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
        $cmd_long = 'service';
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
        die "ERROR: command `$cmd` not found\n";
    }

    # check if method is available
    if( ! $cmd_package->can( $runsub ) ) {
        die "ERROR: command `$cmd` not available (${cmd_package}::${runsub})\n";
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

    my @subcommands;

    if( ! is_class_loaded( $class ) ) {
        try_load_class( $class );
    }

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

1;
