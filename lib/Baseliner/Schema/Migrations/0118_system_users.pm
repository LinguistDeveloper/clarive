package Baseliner::Schema::Migrations::0118_system_users;
use Moose;

sub upgrade {
    my $self = shift;

    mdb->master->update( { collection => 'user' },
        { '$set' => { account_type => 'regular' } }, { safe => 1, multiple => 1 } );

    mdb->master_doc->update( { collection => 'user' },
        { '$set' => { account_type => 'regular' } }, { safe => 1, multiple => 1 } );
}

sub downgrade {
}

1;
