package Clarive::App;
use Mouse;
use v5.10;
use Try::Tiny;

has env          => qw(is rw required 0);
has home         => qw(is rw required 1);
has base         => qw(is rw required 1);
has lang         => qw(is ro required 1);
has debug        => qw(is rw default 0);
has migrate      => qw(is rw default 0);
has verbose      => qw(is rw default 0);
has trace        => qw(is ro default 0);
has carp_always  => qw(is ro default 0);
has enable_plugins => qw(is rw default 1);
has plugins_home => qw(is rw default), sub { shift->base . '/plugins' };

has argv   => qw(is ro isa ArrayRef required 1);  # original command line ARGV
has args   => qw(is ro isa HashRef required 1);  # original command line args
has pos    => qw(is ro isa ArrayRef required 1);  # positional cmd line arguments
has config => qw(is rw isa HashRef required 1);  # full config file (config/global.yml + $env.yml)
has opts   => qw(is rw isa HashRef required 1);  # merged config + args

has version => qw(is ro isa Str lazy 1), default => sub{
    my $self = shift;
    my $vfile = $self->path_to( 'VERSION' );
    if( -e $vfile ) {
        open my $ff, '<', $vfile;
        my ($ver) = <$ff>;
        chomp $ver;
        close $ff;
        return $ver;
    }
    # determine version with a GIT DESCRIBE
    my $FULL_VERSION = do {
        my $v = eval {
            my $branch = `git rev-parse --abbrev-ref HEAD`;
            chomp $branch;
            my @x = `cd $ENV{CLARIVE_HOME}; git describe --always --tags --candidates 1`;
            my $version = $x[0];
            chomp $version;
            if( $version=~ /^(?<ver>.*)-(?<cnt>\d+)-g(?<sha>\w*)$/ ) {
                ["release: $branch, patch: $+{ver}+$+{cnt}, sha: $+{sha}" , "${branch}_$+{ver}_$+{sha}", $+{sha} ]
            } else {
                [ "r$branch v$version", "${branch}_${version}", ''];
            }
        };
        !$v ?  ['r6','??'] : $v;
    };
    $FULL_VERSION->[0];
};

has db => qw(is rw lazy 1 default), sub {
    require Clarive::DB;
    Clarive::DB->new;
};

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;
    my %args = ref $_[0] ? %{ $_[0] } : @_;

    # save orig
    my $arg_orig = $self->clone(\%args);

    # home and env need to be setup first
    $args{env}  //= $ENV{CLA_ENV} // $ENV{CLARIVE_ENV}; # // 'local';

    $args{home} //= $ENV{CLARIVE_HOME} // '.';
    $args{base} //= $ENV{CLARIVE_BASE} // ( $ENV{CLARIVE_HOME} ? "$ENV{CLARIVE_HOME}/.." : '..' );

    require Cwd;
    $args{home} = Cwd::realpath( $args{home} );
    $args{base} = Cwd::realpath( $args{base} );

    chdir $args{home};

    require Clarive::Config;   # needs to be chdir in directory
    my $config = Clarive::Config->config_load( \%args );

    $config //= {} unless ref $config eq 'HASH';

    require Clarive::Util::TLC;
    if( my $site = $config->{join '', qw(l i c e n s e) } ) {
        my $lic = Clarive::Util::TLC::check( $site );
    }

    $args{argv} = \@ARGV;
    $args{lang} //= $ENV{CLARIVE_LANG};
    $args{args} = $arg_orig;
    $args{pos} = defined $args{''} ? [ ref $args{''} ? @{ $args{''} } : $args{''} ] : [];

    #Force legacy ENVs to $args{env}
    $ENV{BASELINER_ENV} = $args{env};
    $ENV{BASELINER_CONFIG_LOCAL_SUFFIX} = $args{env};

    # make sure forked processes (dispatcher) will get ENV somehow
    $ENV{CLARIVE_ENV} //= $args{env};
    $ENV{CLARIVE_TRACE} //= 0;
    $ENV{CLARIVE_CACHE_TRACE} //= 0;

    # resolve variables
    my $parsed_config = $self->parse_vars( $config, { %ENV, %$config, %args } );
    my $parsed_args   = $self->parse_vars( \%args, { %ENV, %$config, %args } );

    # merge config and args
    my %opts = ( %$parsed_config, %$parsed_args );
    $opts{config} = \%opts;    # this becomes Clarive->config later
    $opts{opts}   = $self->clone( \%opts );

    warn "app args: " . $self->yaml( \%opts ) if $args{v};

    $self->$orig( \%opts );
};

sub BUILD {
    my ($self)=@_;

    # LANG to UTF-8
    $ENV{LANG} = $self->lang;

    # verbose ?
    if( defined $self->opts->{v} ) {
        $self->verbose(1);
    }
    # debug ?
    if( defined $self->opts->{d} || $ENV{CLARIVE_DEBUG} ) {
        $self->debug(1);
    }
    # carp_always ?
    if( my $carpa = $self->carp_always ) {
        require Carp::Always;
        $ENV{CARP_TIDY_OFF} = 1 if $carpa > 1; # turn off Carp::Tidy filtering
    }

    $Clarive::app = $self;
}

sub yaml {
    my $self=shift;
    require YAML::XS;
    YAML::XS::Dump( @_ );
}

sub yaml_load {
    my $self=shift;
    require YAML::XS;
    YAML::XS::Load( @_ );
}

sub json {
    my ($self, $data) = @_;
    require JSON::XS;
    my $json = JSON::XS->new;
    $json->convert_blessed( 1 );
    $json->encode( $data );
}

around 'dump' => sub {
    my ($orig, $self, $data) = @_;
    $data ? warn $self->yaml( $data ) : $self->$orig();
};

sub options {
    my $self = shift;
    my ($cmd) = @_;
    # merge config, args and specific cmd config: cmd config needs to come in between
    my %args   = %{ $self->args };
    my %config = %{ $self->opts };  # use opts since it's resolved fully
    return { %config, %{ ref $config{$cmd} eq 'HASH' ? $config{$cmd} : {} }, %args };
}

sub do_cmd {
    my ($self, %p)=@_;
    my ($cmd,$altcmd,$altrun,$cmd_pkg) = @p{ qw/cmd altcmd altrun cmd_pkg/ };
    $cmd or die "ERROR: missing or invalid command";

    my $opts = $self->options($cmd);

    if( $cmd =~ /\./ ) {
        $cmd_pkg = 'bali';
        $opts->{service_name} = $cmd;
    }
    elsif( my @cmds = split '-', $cmd  ) {
        $cmd_pkg = join '::', @cmds;
        if( @cmds > 1 ) {
            $altcmd = $cmds[0];
            $altrun = join '_', @cmds[1..$#cmds];
        }
    }

    my $cmd_package = "Clarive::Cmd::$cmd_pkg";
    my $runsub = 'run';

    # run cmd from plugins?
    for my $lang ( qw(js pl) ) {
        if( my $first = $self->plugins->locate_first( "cmd/$cmd.$lang" ) ) {
            require Clarive::Code;
            my $stash = {};
            try {
                Clarive::Code->new( lang=>$lang, app=>$self, options=>$opts )->run_file( $first->{path}, $stash );
            } catch {
                my $err = shift;
                die $err;
            };
            exit 0;
        }
    }

    # load package
    my $second = 0;
    while( 1 ) {
        eval "require $cmd_package";
        if( $@ ) {
            if( $@ =~ /^Can't locate Clarive\/Cmd\// ) {
                if( $altcmd && !$second) {
                    $cmd_package = "Clarive::Cmd::$altcmd";
                    $runsub = "run_$altrun";
                    $second = 1;
                    next;
                } else {
                    die "ERROR: command not found: $cmd (${cmd_package}::${runsub})\n";
                }
            } else {
                die "ERROR: loading command $cmd (${cmd_package}::${runsub}):\n$@\n";
            }
        }
        last;
    }

    if( $self->verbose ) {
        say "cmd_package: $cmd_package";
        say "cmd opts: " . $self->yaml( $opts );
    }

    # check if method is available
    if( ! $cmd_package->can( $runsub ) ) {
        die "ERROR: command $cmd not available (${cmd_package}::${runsub})\n";
    }

    # run command
    if( $cmd_package->can('new') ) {
        # moose class command
        my $instance = $cmd_package->new( app=>$self, opts=>$opts, %$opts );
        $instance->$runsub( %$opts );
    } else {
        # plain perl package, not a class
        $cmd_package->$runsub( app=>$self, opts=>$opts );
    }
}

sub parse_vars {
    my ( $self, $data, $vars, %args ) = @_;
    my $ret;

    # flatten keys
    $vars = $self->hash_flatten($vars);

    $ret = $self->parse_vars_raw( data => $data, vars => $vars, throw => $args{throw} );
    return $ret;
}

our $hf_scope;
sub merge_pushing {
    my ($self, $h1, $h2 ) = @_;
    my %merged;
    while( my($k2,$v2) = each %$h2 ) {
        $merged{ $k2 } = $v2;
    }
    while( my($k1,$v1) = each %$h1 ) {
        if( exists $merged{$k1} ) {
            my $v2 = delete $merged{$k1};
            if( !defined $v2 ) {
                $merged{$k1}=$v1;
            }
            elsif( !defined $v1 ) {
                $merged{$k1}=$v2;
            }
            elsif( $v1 eq $v2 ) {
                $merged{$k1} = $v2;
            }
            else {
                push @{$merged{$k1}}, $v2 eq $v1 ? $v2 : ( $v2, $v1 );
            }
        }
        else {
            $merged{ $k1 } = $v1;
        }
    }
    %merged;
}
sub hash_flatten {
    my ( $self, $stash, $prefix ) = @_;
    no warnings;
    $prefix ||= '';
    my %flat;
    $hf_scope or local $hf_scope = {};
    my $refstash = ref $stash;
    return () if $refstash && exists $hf_scope->{"$stash"};
    $hf_scope->{"$stash"}=() if $refstash;
    if( $refstash eq 'HASH' ) {
        while( my ($k,$v) = each %$stash ) {
            %flat = $self->merge_pushing( \%flat, scalar $self->hash_flatten($v, $prefix ? "$prefix.$k" : $k ) );
        }
    }
    elsif( $refstash eq 'ARRAY' ) {
        my $cnt=0;
        for my $v ( @$stash ) {
            %flat = $self->merge_pushing( \%flat, scalar $self->hash_flatten($v, "$prefix" ) );
        }
    }
    elsif( $refstash && $refstash !~ /CODE|GLOB|SCALAR/ ) {
        #$stash = _damn( $stash );
        %flat = $self->merge_pushing( \%flat, scalar $self->hash_flatten ( $stash, "$prefix" ) );
    }
    else {
        $flat{ "$prefix" } = "$stash";
    }
    if( !$prefix ) {
        for my $k ( keys %flat ) {
            my $v = $flat{$k};
            if( ref $v eq 'ARRAY' ) {
                $flat{$k}=join ',', @$v;
            }
        }
    }
    return wantarray ? %flat : \%flat;
}

our $parse_vars_raw_scope;
sub parse_vars_raw {
    my $self = shift;
    my %args = @_;
    my ( $data, $vars, $throw, $cleanup ) = @args{ qw/data vars throw cleanup/ };
    my $ref = ref $data;
    # block recursion
    $parse_vars_raw_scope or local $parse_vars_raw_scope={};
    return () if $ref && exists $parse_vars_raw_scope->{"$data"};
    $parse_vars_raw_scope->{"$data"}=() if $ref;

    if( $ref eq 'HASH' ) {
        my %ret;
        for my $k ( keys %$data ) {
            my $v = $data->{$k};
            $ret{$k} = $self->parse_vars_raw( data=>$v, vars=>$vars, throw=>$throw );
        }
        return \%ret;
    } elsif( $ref =~ /Clarive/ ) {
        my $class = $ref;
        my %ret;
        for my $k ( keys %$data ) {
            my $v = $data->{$k};
            $ret{$k} = $self->parse_vars_raw( data=>$v, vars=>$vars, throw=>$throw );
        }
        return bless \%ret => $class;
    } elsif( $ref eq 'ARRAY' ) {
        my @tmp;
        for my $i ( @$data ) {
            push @tmp, $self->parse_vars_raw( data=>$i, vars=>$vars, throw=>$throw );
        }
        return \@tmp;
    } elsif($ref) {
        return $self->parse_vars_raw( data=>_damn( $data ), vars=>$vars, throw=>$throw );
    } else {
        # string
        return $data unless $data && $data =~ m/\{\{.+?\}\}/;
        my $str = "$data";
        for my $k ( keys %$vars ) {
            my $v = $vars->{$k};
            $str =~ s/\{\{$k\}\}/$v/g;
        }
        # cleanup or throw unresolved vars
        if( $throw ) {
            if( my @unresolved = $str =~ m/\{\{(.+?)\}\}/gs ) {
                die( sprintf "Unresolved vars: '%s' in %s", join( "', '", @unresolved ), $str );
            }
        } elsif( $cleanup ) {
            $str =~ s/\{\{.+?\}\}//g;
        }
        return $str;
    }
}

sub load_class {
    my ($self,$class) = @_;
    ( my $pkg = "$class.pm" ) =~ s{::}{\/}g;
    if( !exists $INC{$pkg} ) { # check if it's loaded
        #warn "LOAD=$pkg";
        eval "use $class";
        die $@ if $@;
    }
    return 1;
}

sub clone {
    my ($self,$obj) = @_;
    require Storable;
    return Storable::thaw(Storable::freeze($obj));
}

sub config {
   my $self = shift;
   return $self->config;
}

sub path_to {
    my $self = shift;
    my (@args) = @_;

    require Path::Class;

    my $file;
    foreach my $feature ( $self->features->list ) {
        my $path_to = $feature->path_to(@args);
        if (-e $path_to) {
            $file = $path_to;
            last;
        }
    }

    $file //= Path::Class::file( $self->home, @args );

    return -d "$file" ? Path::Class::dir("$file") : $file;
}

sub paths_to {
    my $self = shift;
    my (@args) = @_;

    require Path::Class;

    my @paths;

    foreach my $plugin ( $self->plugins->all_plugins ) {
        my $path_to = Path::Class::dir( $plugin, @args);
        if (-e $path_to) {
            push @paths, $path_to;
        }
    }

    foreach my $feature ( $self->features->list ) {
        my $path_to = $feature->path_to(@args);
        if (-e $path_to) {
            push @paths, $path_to;
        }
    }

    my $app_file = Path::Class::file( $self->home, @args );
    push @paths, $app_file if -e $app_file;

    foreach my $path (@paths) {
        if (-d "$path") {
            $path = Path::Class::dir("$path");
        }
    }

    return @paths;
}

sub features {
    my $self = shift;
    require Clarive::Features;
    return Clarive::Features->new(app=>$self);
}

sub plugins {
    my $self = shift;
    require Clarive::Plugins;
    return Clarive::Plugins->new(app=>$self);
}

# singleton Clarive package
package Clarive {
    our $AUTOLOAD;
    sub app {
        return $Clarive::app;
    }
    sub AUTOLOAD {
        my $self = shift;
        my $name = $AUTOLOAD;
        my @a = reverse( split(/::/, $name));
        my $app = $Clarive::app;
        my $class = ref $app;
        my $method = $class . '::' . $a[0];
        @_ = ( $app, @_ );
        goto &$method;
    }
}

# placeholders, to avoid warnings
package mdb;
package cache;
package queue;
package ci;
package model;

1;
