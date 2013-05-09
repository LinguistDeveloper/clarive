package Clarive::App;
use Mouse;

has env     => qw(is rw required 1);
has home    => qw(is rw required 1);
has lang    => qw(is ro required 1);
has debug   => qw(is rw default 0);
has verbose => qw(is rw default 0);
has trace   => qw(is ro default 0);

has argv   => qw(is ro isa ArrayRef required 1);  # original command line ARGV
has args   => qw(is ro isa HashRef required 1);  # original command line args
has config => qw(is rw isa HashRef required 1);  # full config file (clarive.yml + $env.yml)
has opts   => qw(is ro isa HashRef required 1);  # merged config + args

has db => qw(is rw lazy 1 default), sub {
    require Clarive::DB;
    Clarive::DB->new;
};

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;
    my %args = ref $_[0] ? %{ $_[0] } : @_;
    
    # home and env need to be setup first
    $args{env}  //= $ENV{CLA_ENV} // $ENV{CLARIVE_ENV} // 'local';
    $args{home} //= $ENV{CLARIVE_HOME} // '.';
    
    require Clarive::Config;
    my $config = Clarive::Config->config_load( %args );
    
    $args{args} = { %args };

    # merge config and args
    %args = ( %$config, %args );

    $args{config} = $config;
    $args{opts} = \%args;
    $args{argv} = \@ARGV;
    $args{lang} //= $ENV{CLARIVE_LANG};
    
    warn $self->yaml( \%args ) if $args{v};

    $self->$orig( %args ); 
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

    $Clarive::app = $self;  
}

sub yaml {
    my $self=shift;
    require YAML::XS;
    YAML::XS::Dump( @_ );
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

sub do_cmd {
    my ($self, %p)=@_;
    my ($cmd,$altcmd,$altrun,$cmd_pkg) = @p{ qw/cmd altcmd altrun cmd_pkg/ };
    $cmd or die "ERROR: missing or invalid command"; 
    
    my %args   = %{ $self->args };
    my %config = %{ $self->config };
    # merge config, args and specific cmd config
    my %opts = ( %config, %{ ref $config{$cmd} eq 'HASH' ? $config{$cmd} : {} }, %args ); 
    
    if( $cmd =~ /\./ ) {
        $cmd_pkg = 'bali';   
        $opts{service_name} = $cmd;
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

    # check if method is available
    if( ! $cmd_package->can( $runsub ) ) {
        die "ERROR: command $cmd not available (${cmd_package}::${runsub})\n";
    }
    
    # run command
    if( $cmd_package->can('new') ) {
        my $instance = $cmd_package->new( app=>$self, opts=>\%opts, %opts );
        $instance->$runsub( %opts );
    } else {
        $cmd_package->$runsub( app=>$self, opts=>\%opts );
    }
}

1;
