package Baseliner::Role::CI::Parser;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/parser.png' }

has token_case => qw(is rw isa Any default case-sensitive);

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
    my $module;
    for my $entry ( Util->_array( $tree ) ) {
        $module //= $entry->{module}; 
    }
    my $ext = $item->extension;
    
    # determine module name 
    if( ! defined $module ) {
        $module = $item->basename;
        if( my $fb = $self->path_capture ) {
            $module = $+{module} if $item->path =~ qr/$fb/ && length $+{module};
        } else {
            $module = $item->moniker // $item->basename;
        }
        $module = $self->change_case( $module );
        push @$tree => { module=>$module  };
    }
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
