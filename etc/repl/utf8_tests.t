my $r = $c->model('Baseliner::BaliConfig')->find(1465);
Encode::is_utf8( $r->value );
my $r2 = $c->model('Baseliner::BaliTPMenuCPT')->find(15000);
"ENCODED=" . Encode::is_utf8( $r2->nom_es );
#utf8::downgrade( $r2->nom_es )
__END__
ENCODED=1
