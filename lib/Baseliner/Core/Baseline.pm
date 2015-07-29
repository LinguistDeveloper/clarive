package Baseliner::Core::Baseline;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;

# not being used:
has 'bl' => ( is=>'rw', isa=>'Str', required=>1 ); 
has 'bl_name' => ( is=>'rw', isa=>'Str', required=>1 ); 
has 'bl_type' => ( is=>'rw', isa=>'Str', required=>1 ); 

no Moose;
## ----- static methods

register 'config.baseline' => {
    name => _loc('Config global baselines'),
    array => 1,
    metadata => [
        { id=>'id', label=>_loc('Baseline Identifier'), },
        { id=>'name', label=>_loc('Baseline Name'), },
    ],
};

=head2 find_text 

Finds a descriptive representation for the Namespace. Heavly used, heavly memoized.

=cut
our %bl_text_cache;
sub name {
    my $self = shift; 
    my $bl = shift;
    return $bl_text_cache{$bl} if defined $bl_text_cache{$bl}; 
    my $r = ci->find( moniker=>$bl );
    return $bl unless ref $r;
    return $bl_text_cache{$bl} = _loc($r->name) || $bl;
}

sub baselines {
    my $self = shift; 
    return sort { $a->seq <=> $b->seq } ci->search_cis( collection=>'bl' );
}

sub baselines_no_root {
    my $self = shift;
    my @arr = $self->baselines();
    shift @arr if $arr[0]->{bl} eq '*';
    return @arr;
}
1;

