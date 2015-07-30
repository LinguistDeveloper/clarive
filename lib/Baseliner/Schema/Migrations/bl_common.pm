package Baseliner::Schema::Migrations::bl_common 1;
use Moose;

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

no Moose;
__PACKAGE__->meta->make_immutable;

1;





