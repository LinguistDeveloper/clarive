package Baseliner::Schema::Migrations::topic_admin;
use Mouse;

our $VERSION = 3;

sub upgrade {
    my $max_wf=0;
    for my $wf ( Util->_dbis->query('select * from bali_topic_categories_admin')->hashes ) {
        $$wf{id} = 0+$$wf{id};
        mdb->workflow->insert( $wf ) unless mdb->workflow->find_one({ id=>$$wf{id} });
        $max_wf = $$wf{id} if $$wf{id} > $max_wf;
    }
    mdb->seq('workflow', $max_wf ) if $max_wf;
    
}

sub downgrade {
    
}

1;


