package BaselinerX::CI::engine;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Parser';

sub collection { 'engine' }
sub has_bl { 0 }

has timeout          => qw(is rw isa Num default 10);
has path_capture     => qw(is rw isa Str);
has engine_package   => qw(is rw isa Str required 1);

service 'parse' => 'Parse a file' => \&parse;

sub parse {
    my ($self,$item) = @_; 
    my $file = $item->path; 
    my $source = $item->source; 
    my $tmout = $self->timeout;
    my $pkg = $self->engine_package;
   
    eval "require $pkg";
    return { success=>0, msg=>Util->_loc("Could not require package %1: %2", $pkg, $@) } if $@;
    
    my $tree = $pkg->parse( file=>$file, source=>$source );
    
    $tree = $self->process_item_tree( $item, $tree ); 
    $item->add_parse_tree( $tree );
    #my $ret = {};
    #$self->collect_vars( $tree, $ret );
    return $tree // {};
}

1;

