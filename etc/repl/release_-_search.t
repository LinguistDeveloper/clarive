for my $req ( $c->model('Baseliner::BaliRelease')->search->all ) {
    my $item = $c->model('Namespaces')->get( 'release/' . $req->name );
    my $app = $item->application;
    print "APP=$app, REL=" . $item->ns;
    next unless length( $app ) > 1 ;
    $c->model('Projects')->add_item( ns=>$item, project=>$app );
    for my $ns ( _array $item->contents ) {
        print $ns->name;
        print "\n";
    }
    print "\n" . '=' x 30 . "\n";
}
__END__
APP=application/GBP.0083, REL=release/R.0083.S0912919.JRF5355T
==============================
APP=/, REL=release/aaaaaaaaaAPP=application/GBP.0188, REL=release/R.0188.otra releaseH0188S0008921@01 - P08921PRTP10001001

==============================
APP=application/GBP.0000, REL=release/dfasdfadsfH0188S0008921@01 - P08921PRTP10001001

==============================
APP=application/GBP.0188, REL=release/R.0188.R.0188.TP16-Versión 8.39H0188I01440598@2
H0188S1000086@01 - Rivas - P1000086PRTP07080001

==============================
APP=application/GBP.8888, REL=release/R.8888.demo releaseH0000S9999999@02
H0188S0006717@01 - P06717PRTP05400001

==============================

--- ''

