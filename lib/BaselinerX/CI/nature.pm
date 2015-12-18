package BaselinerX::CI::nature;
use Baseliner::Moose;
use Baseliner::Utils;
use namespace::autoclean;

with 'Baseliner::Role::CI::Nature';
with 'Baseliner::Role::CI::VariableStash';

sub icon { '/static/images/icons/nature.png' }
#sub icon { '/static/images/nature/nature.png' }



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

service scan => 'Scan Nature Items' => sub {
    my ($self,$c,$p) =@_;
    $self->scan;  # asssumes the nature already has items 
    return "ok scan: " . Util->_dump( $self );
};

sub has_bl { 0 }

# checks if an item belongs to this nature
sub item_match {
    my ($self, %p ) = @_;
    my $item = $p{item} // _fail _loc 'Missing parameter item';
    my @include = Util->_array( $self->include );
    my @exclude = Util->_array( $self->exclude );
    my $match = 0;
    IN: for my $in ( @include ) {
        next unless length $in;
        if( $item->{path} =~ /$in/ || ($item->{fullpath} && $item->{fullpath} =~ /$in/ )) {
            $match = 1; 
            last IN;
        }
    }
    for my $ex ( @exclude ) {
        next unless length $ex;
        if( $item->{path} =~ /$ex/ || ($item->{fullpath} && $item->{fullpath} =~ /$ex/ )) {
            return 0;
        }
    }
    return $match;
}

# add item to 'items' if it belongs here
sub push_item {
    my ($self, $item, %p ) = @_;
    $self->items([]) unless ref $self->items;
    if( $self->item_match( item=>$item, %p ) ) {
        # TODO make them items unique
        push @{ $self->items }, $item;
        return 1;
    } else {
        return 0;
    }
}

1;
