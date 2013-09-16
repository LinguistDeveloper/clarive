package Baseliner::AutoGroup;
use strict;
use warnings;
use v5.10;

#sub new {
#    my ($class, @contents) = @_;
#    bless \@contents => $class;
#}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my @args = @_;
    my $name = $AUTOLOAD;
    my @a = reverse(split(/::/, $name));
    my $method = $a[0];
    my @rets;
    my $found = 0;
    #return @$self;
    #Util->_debug( \$self );
    for my $con ( @$self ) {
        if ( Util->_blessed($con) && $con->can( $method ) ) {
            push @rets, $con->$method( @args );
        }
    }
    return @rets;
    #return bless \@rets => 'Baseliner::AutoGroup';
    #return @rets ? __PACKAGE__->new( @rets ) : [];
}

1;
