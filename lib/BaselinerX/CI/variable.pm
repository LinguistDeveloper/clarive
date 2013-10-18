package BaselinerX::CI::variable;
use Baseliner::Moose;
use Baseliner::Utils;

has var_type             => qw(is rw isa Str);
has var_ci_class         => qw(is rw isa Maybe[Str]);
has var_ci_role          => qw(is rw isa Maybe[Str]);
has var_ci_mandatory     => qw(is rw isa BoolCheckbox coerce 1);
has var_ci_multiple      => qw(is rw isa BoolCheckbox coerce 1);
has var_combo_options    => qw(is rw isa ArrayRef), default=>sub{ [] };
has var_default          => qw(is rw isa Any);

with 'Baseliner::Role::CI::Variable';

sub icon { '/static/images/icons/element_copy.png' }

sub has_bl { 0 }

sub default_hash {
    my ($class, $bl)=@_;
    $bl //= '*';
    my %vars;
    my @all = BaselinerX::CI::variable->search_cis;
    for my $var ( @all ) {
        next unless ! length($var->bl) || $var->bl eq '*' || $var->bl eq $bl;
        if( $var->var_type eq 'ci' ) {
            my $def = $var->var_default;
            $vars{ $var->name } = $def; #Baseliner::CI->new( $def ) if length $def;   
        } else {
            $vars{ $var->name } = $var->var_default;
        }
    } 
    \%vars;
}

1;

