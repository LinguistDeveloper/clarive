package Baseliner::Schema::Migrations::0100_default_field;
use Moose;

sub upgrade {
    for my $cat ( mdb->category->find->all ) {
        mdb->category->update(
            { id => $cat->{id} },
            {
                '$set'   => { default_form  => $cat->{default_field} },
                '$unset' => { default_field => 1 }
            }
        );
    }
}

sub downgrade {
    
}

1;

