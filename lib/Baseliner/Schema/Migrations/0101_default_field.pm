package Baseliner::Schema::Migrations::0101_default_field;
use Moose;

sub upgrade {
    for my $cat ( mdb->category->find->all ) {
        mdb->category->update(
            { id => $cat->{id}, default_form=>{ '$exists'=>0 } },
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

