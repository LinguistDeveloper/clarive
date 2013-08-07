package Baseliner::Role::CI::Parser;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/parser.png' }

has token_case => qw(is rw isa Any default case-sensitive);

=head2 process_item_tree

Turns a hash tree into array.
Ensures that moniker (module) is found.

Sets moniker and find.

=cut
sub process_item_tree {
    my ($self, $item, $tree ) = @_;    
    
    $tree = $self->tree_to_array( $tree ) unless ref $tree eq 'ARRAY';
    
    my @tree_entries;

    for my $entry ( Util->_array( $tree ) ) {
        if( ref $entry eq 'HASH' ) {
            for my $k ( keys %$entry ) {
                my $v = $entry->{$k};
                next if ref $v;
                $entry->{$k} = $self->change_case( $v ); # to upper, lower or same
            }
        }
        push @tree_entries, $entry;
    }

    $tree = \@tree_entries;  # updated with lower/upper, etc

    # make sure we have our module name
    #   last is more important
    my $module;
    for my $entry ( Util->_array( $tree ) ) {
        if( length $entry->{module} ) {
            $entry->{module} = $self->change_case( $entry->{module} );
            $module //= $entry->{module}; 
        }

        # make sure dependencies go with correct case
        for( qw/depend depends/ ) {
            if( length $entry->{$_} ) {
                $entry->{$_} = $self->change_case( $entry->{$_} );
            }
        }
    }
    my $ext = $item->extension;
    
    # set moniker 
    $item->moniker( $module ) if length $module;

    return $tree;
}

sub change_case {
    my($self, $v) = @_;
    my $tc = $self->token_case;
    return $v unless $tc;
    return $tc eq 'lowercase' ? lc( $v ) : $tc eq 'uppercase' ? uc($v) : $v;
}

sub tree_to_array {
    my ($self, $tree, $key, $ret ) = @_;    
    $ret //= [];
    my $r = ref $tree;
    if( $r eq 'HASH' ) {
        while( my($k,$v) = each %$tree ) {
            $self->tree_to_array( $v, $k, $ret );
        }
        return $ret;
    }
    elsif( $r eq 'ARRAY' ) {
        for my $v ( @$tree ) {
            $self->tree_to_array( $v, $key, $ret );
        }
        return $ret;
    }
    else {
        push @$ret, { $key => $tree };
    }
    return [];
}

1;
