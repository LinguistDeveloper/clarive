package BaselinerX::CI::nature;
use Baseliner::Moose;
use Baseliner::Utils;
use namespace::autoclean;

with 'Baseliner::Role::CI::Nature';
sub icon { '/static/images/icons/nature.gif' }


has include => qw(is rw isa Any);
has exclude => qw(is rw isa Any);
has_cis 'parsers';
has_cis 'items';

sub rel_type {
    { 
        items => [ from_mid => 'nature_item' ] ,
        parsers => [ from_mid => 'nature_parser' ] ,
    };
}

service scan => 'Scan files' => sub {
    my ($self,$c,$p) =@_;
    return "ok scan: " . Util->_dump( $self );
};

sub has_bl { 0 }

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
            _debug( "parsing item " . $item->path . " with parser " . $parser->name );
            my $res = $parser->parse( $item );
            
            push @nature_items, $item ; 
        }
    }
    $self->items( \@nature_items );
}

1;
