package BaselinerX::CI::group;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Group';

sub icon { '/static/images/icons/group.gif' }

has rollback  => qw(is rw isa BoolCheckbox default 0);
has_cis 'contents';

sub rel_type {
    { 
        contents => [ from_mid => 'group_contents' ] ,
    };
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my @args = @_;
    my $name = $AUTOLOAD;
    my @a = reverse(split(/::/, $name));
    my $method = $a[0];
    return $self->$method( @args ) unless ref $self;
    my @contents = $self->children( rel_type=>'group_contents' );
    require Baseliner::AutoGroup;
    my @rets;
    my $found = 0;
    for my $ci ( @contents ) {
        if( $ci->can( $method ) ) {
            push @rets, $ci->$method( @args );
            $found = 1;
        }
    }
    return $self->$method( @args ) if !$found;
    return bless \@rets => 'Baseliner::AutoGroup';
    #return Baseliner::AutoGroup->new( @rets );
}


1;
