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
            my $data = YAML::XS::Load( join '', <$fcfg> );
            close $fcfg;
            %ret = ( %ret, %$data ) if ref $data;
        }
    }
    return \%ret;
}

1;
