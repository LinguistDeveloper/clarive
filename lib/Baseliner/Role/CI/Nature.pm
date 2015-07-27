package Baseliner::Role::CI::Nature;
use Moose::Role;
with 'Baseliner::Role::CI';

has only_parsed => qw(is rw isa BoolCheckbox coerce 1 default 0);

sub icon { '/static/images/icons/nature.png' }
=sub icon { '/static/images/nature/nature.png' }

head2 filter_items

From a list of items, filter the ones that belong to this
nature.

Params:

    items => array of items
    callback => sub {} for each item, return false to prevent item from being added
    save => bool - commit items to CI

=cut
sub filter_items {
    my ($self, %p )=@_;
    my @includes = map { qr/$_/i } Util->_array( $self->include );
    my @excludes = map { qr/$_/i } Util->_array( $self->exclude );

    my %nature_items;

    ITEM: for my $item ( Util->_array( $p{items} ) ) {
        my $inc_flag = 0;
        # continue on first include matched ok
        INCLUDES: for my $i ( @includes ) {
            if( $item->path =~ $i ) {
                $inc_flag = 1;
                # if nature path has capture matches, include it in item variables
                my $captures = { %+ };
                if( keys %$captures ) {
                    $item->variables({ %{ $item->variables }, %$captures });
                }
                last INCLUDES;
            }
        }
        next ITEM unless $inc_flag;
        # next on first exclude matched
        for my $i ( @excludes ) {
            next ITEM if $item->path =~ $i;
        }
        
        if( ref $p{callback} eq 'CODE' ) {
            next unless $p{callback}->( $item );
        }

        $nature_items{ $item->ns // ( $item->path .';'. $item->version ) } = $item; # avoid duplicates, mid is not good, it could be blank
    }

    # keep track of my items -- but no save
    my $nat_items = [ values %nature_items ];

    # now finish up on the item
    for my $item ( @$nat_items ) {
        # make sure we have a moniker
        $item->moniker_from_tree_or_name unless length $item->moniker;
    }

    $self->items( $nat_items );
    $self->save if $p{save};
    $nat_items;
}

sub scan {
    my ($self, %p )=@_;
   
    my $nat_items = $self->filter_items( %p ); 
    my $nat_items_after_parse = [];
    
    for my $parser ( Util->_array( $self->parsers ) ) {
        ITEM: for my $item ( @$nat_items ) {
            Util->_debug( "parsing item " . $item->path . " with parser " . $parser->name );
            my $res = $parser->parse( $item );
            Util->_debug( "PARSER $parser->{name} (" . ref($parser) . "): " . Util->_dump( $res ) );
            
            # TODO this is the place to take or reject items based on parse results and a flag
            #   only_parsed goes here
            push @$nat_items_after_parse, $item;
        }
    }

    # now finish up on the item
    for my $item ( @$nat_items_after_parse ) {
        # make sure we have a moniker
        $item->moniker_from_tree_or_name unless length $item->moniker;
    }

    $self->items( @$nat_items_after_parse );
    $self->save if $p{save};  # commit to nature CI, for feeding the graph
    $nat_items_after_parse;
}

1;

