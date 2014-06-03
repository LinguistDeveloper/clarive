package Baseliner::Schema::Migrations::mid;
use Mouse;

sub upgrade {
    my $mid = Util->_dbis->query('select max(mid) from bali_master')->array->[0];
    my $mmid = mdb->seq('mid');
    mdb->seq('mid',$mid+1) if $mmid < $mid;
}

sub downgrade {
    
}

1;

