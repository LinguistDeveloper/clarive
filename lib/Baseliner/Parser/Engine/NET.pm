package Baseliner::Parser::Engine::NET;
use Baseliner::Moose;

sub parse {
    my ($self,%p) =@_;
    my $f = "$p{file}";
    my $s = $p{source};
    
    my @tree;
    while( $s =~  m{Imports\s+([^\r\n]*)}gms ) {
        push @tree, { depends=>$1, line=>pos($s) };  
    }
    while( $s =~  m{Include="([^"]*?)"}gms ) {
        my $m = $1;
        if( $m =~ /^([^\s,]+),\s*(Version=(?<version>[0-9\.]+))?,\s*.*$/ ) {
            $m = $1;
            push @tree, { depends=>$m, line=>pos($s), version=>$+{version} };  
        } else {
            push @tree, { depends=>$m, line=>pos($s) };  
        }
    }
    my $module;
    while( $s =~  m{Module\s+([^\r\n]+)}gms ) {
        $module = $1;  # only keep last
    }
    push @tree, { module => $module };
    return \@tree;
}

1;

