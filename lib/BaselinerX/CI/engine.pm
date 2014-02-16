package BaselinerX::CI::engine;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Parser';

sub collection { 'engine' }
sub has_bl { 0 }

has timeout          => qw(is rw isa Num default 10);
has engine_package   => qw(is rw isa Str required 1);
has engine_options   => qw(is rw isa HashRef), default=>sub{+{}};

service 'parse' => 'Parse a file' => sub{ 
    my($self,$c,$config)=@_;
    $self->parse( ci->item->new($config) );
};

sub parse {
    my ($self,$item) = @_; 
    my $file = $item->path; 
    my $source = $item->source; 
    my $tmout = $self->timeout;
    my $pkg = $self->engine_package;
   
    eval "require $pkg";
    return { success=>0, msg=>Util->_loc("Could not require package %1: %2", $pkg, $@) } if $@;
    
    my $tree = $pkg->new($self->engine_options)->parse( file=>$file, source=>$source );
    $tree = $self->process_item_tree( $item, $tree ); 
    $item->add_parse_tree( $tree );
    return $tree // {};
}

1;

