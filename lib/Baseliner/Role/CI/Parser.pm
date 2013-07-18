package Baseliner::Role::CI::Parser;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/parser.png' }

sub process_item_tree {
    my ($self, $item, $tree ) = @_;    
    
    $tree = $self->tree_to_array( $tree ) unless ref $tree eq 'ARRAY';
    
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
        push @$tree => { module=>$module  };
    }
    return $tree;
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
