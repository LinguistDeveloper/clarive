package Baseliner::Schema::Migrations::0124_set_clax_connection_to_0_in_old_generic_servers;
use Moose;

sub upgrade {
    my $servers_cursor = mdb->master_doc->find( { collection => 'generic_server' } );

    while ( my $generic_server = $servers_cursor->next ) {
        next if defined $generic_server->{connect_clax};
        $generic_server->{connect_clax} = '0';
        my $yaml = Util->_dump($generic_server);

        mdb->master_doc->update( { mid => $generic_server->{mid} }, $generic_server, { safe => 1 } );
        mdb->master->update( { mid => $generic_server->{mid} }, { '$set' => { yaml => $yaml } }, { safe => 1 } );
    }
}

sub downgrade {
}

1;
