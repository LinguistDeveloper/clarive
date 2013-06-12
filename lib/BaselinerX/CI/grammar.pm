package BaselinerX::CI::grammar;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Parser';

sub collection { 'grammar' }
sub has_bl { 0 }

has grammar          => qw(is rw isa Str);
has regex_options    => qw(is rw isa Str default xmsi);
has timeout          => qw(is rw isa Num default 10);
has module_fallback => qw(is rw isa Str);

service 'parse' => 'Parse a file' => \&parse;

sub parse {
    my ($self,$item) = @_; 
    my $file = $item->path; 
    my $source = $item->source; 
    my $tmout = $self->timeout;
    my $grammar = $self->grammar; 
    $grammar =~ s{\r\n}{\n}g;
    Util->_fail( 'Grammar not found' ) unless $grammar;
    my $rg = do {
        use Regexp::Grammars;
        eval "qr{
        <timeout: $tmout>
        $grammar}" . $self->regex_options;
    };
    
    if( $source =~ $rg ) {
        my $tree = { %/ };    
        if( my $root = [ keys %$tree ]->[0] ) {
            $tree = $tree->{$root}; # delete root node 'grammar name'
            # make sure we have our module name
            my $module;
            for my $entry ( Util->_array( $tree ) ) {
                $module //= $entry->{module}; 
            }
            my $ext = $item->extension;
            # determine module name 
            if( ! defined $module ) {
                $module = $item->basename;
                if( my $fb = $self->module_fallback ) {
                    $module = $+{module} if $item->path =~ qr/$fb/ && length $+{module};
                } else {
                    $module = $item->moniker // $item->basename;
                }
                push @$tree => { module=>$module  };
            }
            $item->{parse_tree} = $tree;
            #my $ret = {};
            #$self->collect_vars( $tree, $ret );
            return $tree;
        }
    } else {
        return { msg=>'not found' };
    }
}

1;
