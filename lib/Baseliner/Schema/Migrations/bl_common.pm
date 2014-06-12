package Baseliner::Schema::Migrations::bl_common 1;
use Mouse;

sub upgrade {
    if( ! ci->bl->find_one({ name=>'root' }) ) {
        ci->bl->new({
            name    => 'Common',
            moniker => '*',
            bl      => '*',
        })->save;
    }
}

sub downgrade {
}

1;





