package Clarive::Config;
use strict;

sub new {
    my $class = shift;
    my $data = shift;
    bless $data => $class;
}

sub config_load {
    my ($self, %p) = @_;
    my %ret ;
    
    my $env = $p{env} or exists $p{v} and warn "warn: env is not defined\n";
    my @files = ( 'config/global.yml' );
    length $env && push @files, "config/$env.yml";
    push @files, $p{config};
    # global.yml is the base config
    for my $file ( @files ) {   # most important last
        next unless $file;
        if( -e $file ) {
            require YAML::XS;
            open my $fcfg, '<', $file or die "Error opening config file '$file':$!";
            ## TODO consider allowing variables in yaml, such as {{port}}
            ##         which would get replaced before parsing with values from $ret{port} and/or $p{port}
            ##      -- but remember YAML already has the &1 - *1 pair functionality which can come in handy
            my $data = YAML::XS::Load( join '', <$fcfg> );
            close $fcfg;
            %ret = $self->merge_2level( \%ret, $data ) if ref $data eq 'HASH';
        }
    }
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
