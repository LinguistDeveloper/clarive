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
1;
