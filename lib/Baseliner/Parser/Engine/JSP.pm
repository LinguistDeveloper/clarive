package Baseliner::Parser::Engine::JSP;
use Baseliner::Moose;

sub parse {
    my ($self,%p) =@_;
    my $f = "$p{file}";
    my $s = $p{source};
    
    my @tree;
    while( $s =~  m{<jsp:include page="(.+?)"(?:.*?)\/>}gms ) {
        push @tree, { depends=>$1, line=>pos($s) };  
    }
    while( $s =~ m{<%@\s+page\s+import\s*=\s*"(.+?)"\s*%>}gms ) {
        my $m = $1;
        $m =~ s{[\r\n\s]*}{}g;
        $m = split/,+/, $m;  
        push @tree, { depends=>$m, line=>pos($s) };  
    }
    while( $s =~ m{<script.*src="(.*?)"></script>}g ) {
        my $m = $1;
        $m =~ s{<%.*%>}{}g;
        push @tree, { depends=>$m, line=>pos($s) };  
    }
    return \@tree;
}

1;
