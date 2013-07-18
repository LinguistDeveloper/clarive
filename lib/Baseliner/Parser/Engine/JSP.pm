package Baseliner::Parser::Engine::JSP;
use Baseliner::Moose;

sub parse {
    my ($self,%p) =@_;
    my $f = "$p{file}";
    my $s = $p{source};
    
    my $t = { depends=>[] };
    while( $s =~  m{<jsp:include page="(.+?)"(?:.*?)\/>}gms ) {
        push $t->{depends}, $1;
    }
    while( $s =~ m{<%@\s+page\s+import\s*=\s*"(.+?)"\s*%>}gms ) {
        my $m = $1;
        $m =~ s{[\r\n\s]*}{}g;
        push $t->{depends}, split/,+/, $m;  
    }
    while( $s =~ m{<script.*src="(.*?)"></script>}g ) {
        my $m = $1;
        $m =~ s{<%.*%>}{}g;
        push $t->{depends}, $m;
    }
    return $t; 
}

1;
