package Baseliner::Role::CI::Nature;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/nature.gif' }

sub scan {
    my ($self, %p )=@_;
    my $stash = {};
    my @includes = map { qr/$_/i } Util->_array( $self->include );
    my @excludes = map { qr/$_/i } Util->_array( $self->exclude );
    #my %nature_items = map { $_->mid => $_ } Util->_array( $self->items );
    my @nature_items = Util->_array( $self->items );
    for my $parser ( Util->_array( $self->parsers ) ) {
        ITEM: for my $item ( Util->_array( $p{items} ) ) {
            my $inc_flag = 0;
            # continue on first include matched ok
            for my $i ( @includes ) {
                if( $item->path =~ $i ) {
                    $inc_flag = 1;
                    my $captures = \%+;
                    if( keys %$captures ) {
                        $item->variables({ %{ $item->variables }, %$captures });
                    }
                    last;
                }
            }
            next ITEM unless $inc_flag;
            # next on first exclude matched
            for my $i ( @excludes ) {
                next ITEM if $item->path =~ $i;
            }

            Util->_debug( "parsing item " . $item->path . " with parser " . $parser->name );

            my $res = $parser->parse( $item );
            
            push @nature_items, $item ; 
        }
    }
    # keep track of my items -- but no save
    $self->items( \@nature_items );

}

1;

