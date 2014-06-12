package Clarive::Config;
use strict;

sub new {
    my $class = shift;
    my $data = shift;
    bless $data => $class;
}

sub config_load {
    my ($self, $args) = @_;
    my %ret ;
    
    my $env = $$args{env} or exists $$args{v} and warn "warn: env is not defined\n";
    my @files = ( 'config/clarive.yml', "$$args{base}/config/clarive.yml", 'config/global.yml', "$$args{base}/config/global.yml" );
    if( length $env ) {
        if( $env =~ m{[/\\](\w+)\.} ) {
            # looks like a dir
            my $env_code = $1;
            push @files, $env;
            $$args{env} = $env_code;
        } else {
            push( @files, "config/$env.yml", "$$args{base}/config/$env.yml") if length $env;
        }
    }
    
    push @files, $$args{config};  # config is a free config file that goes last and precedes the environment
    my @loaded_config_files; 
    
    my $found = 0;
    # clarive.yml has product defaults, global.yml is a User Defined base config
    for my $file ( @files ) {   # most important last
        next unless $file;
        if( -e $file ) {
            require YAML::XS;
            $found = 1;
            open my $fcfg, '<', $file or die "Error opening config file '$file':$!";
            push @loaded_config_files, $file;
            ## TODO consider allowing variables in yaml, such as {{port}}
            ##         which would get replaced before parsing with values from $ret{port} and/or $p{port}
            ##      -- but remember YAML already has the &1 - *1 pair functionality which can come in handy
            my $data = YAML::XS::Load( join '', <$fcfg> );
            close $fcfg;
            %ret = $self->merge_2level( \%ret, $data ) if ref $data eq 'HASH';
        }
    }
    $ret{loaded_config_files} = \@loaded_config_files;
    die "Error: Could not find suitable config file for environment `$env`\n" unless $found;
    return \%ret;
}

# merges 2 hashes down to the second level, so that config entries
#   like baseliner: { ... } gets merged with another baseliner: { ... }
sub merge_2level {
    my ($self, $h1, $h2 ) = @_;
    my %ret ;
    for my $k1 ( keys %$h1 ) {
        if( ref $h1->{$k1} eq 'HASH' && ref $h2->{$k1} eq 'HASH' ) {
            my $v2 = delete $h2->{$k1}; 
            $ret{ $k1 } = +{ %{ $h1->{$k1} }, %$v2 };
        } else {
           $ret{ $k1 } = $h1->{$k1}; 
        }
    }
    for my $k2 ( keys %$h2 ) {
        $ret{ $k2 } = $h2->{$k2};
    }
    return %ret;
}

1;
