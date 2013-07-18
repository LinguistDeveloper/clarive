package Baseliner::Parser::Engine::C;
use Baseliner::Moose;

sub parse {
    my ($self,%p) =@_;
    my $f = "$p{file}";
    my $s = $p{source};
    
    my $t = { depends=>[] };
    my @tree;
    while( $s =~  m{#include [<"]([^">]*?)[<"]}gms ) {
        push @tree, { depends=>$1, line=>pos($s) };  
        #push $t->{depends}, $1;
    }
    return \@tree;
}

1;
