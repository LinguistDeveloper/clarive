package Baseliner::Schema::Migrations::0115_update_mongo_index;
use Moose;

sub upgrade {
    my %topic_weights      = %{ Clarive->config->{index}{weights}{topic} };
    my %master_doc_weights = %{ Clarive->config->{index}{weights}{master_doc} };

    foreach my $key ( keys %topic_weights ) {
        $topic_weights{$key} = int $topic_weights{$key};
    }

    foreach my $key ( keys %master_doc_weights ) {
        $master_doc_weights{$key} = int $master_doc_weights{$key};
    }

    mdb->activity->ensure_index( { mid => 1, event_key => 1 } );
    mdb->event->ensure_index( { ts => 1, event_key => 1, event_status => 1 } );
    mdb->event_log->ensure_index( { 'id' => 1 } );
    mdb->job_log->ensure_index( { mid => 1, ts => 1, t => 1, exec => 1 } );
    mdb->job_log->ensure_index( { ts=>1, t=>1 } );
    mdb->master_doc->ensure_index( { '$**' => "text" },
        { %topic_weights ? ( weights => \%master_doc_weights ) : (), language_override => '_lang', background => 1 } );
    mdb->master_doc->ensure_index( { collection => 1, starttime  => -1 } );
    mdb->master_doc->ensure_index( { projects   => 1, collection => 1 } );
    mdb->master_doc->ensure_index( { step       => 1, status     => 1, now => 1, collection => 1, host => 1 } );
    mdb->master_doc->ensure_index(
        { step => 1, status => 1, schedtime => 1, maxstarttime => 1, collection => 1, host => 1 } );
    mdb->rule->ensure_index( { rule_seq=>1, _id=>-1 } );
    mdb->rule->ensure_index( { rule_seq=>1, ts=>-1 } );
    mdb->rule_status->ensure_index( { id => 1, type => 1, status => 1 } );
    mdb->rule_status->ensure_index( { id => 1, status => 1 } );
    mdb->topic->ensure_index( { '$**' => "text" },
        { %topic_weights ? ( weights => \%topic_weights ) : (), language_override => '_lang', background => 1 } );
    mdb->topic->ensure_index( { '_project_security.project' => 1, category_name => 1 } );
    mdb->topic->ensure_index( { 'category.id' => 1, 'category_status.type' => 1, _project_security => 1 } );
}

sub downgrade {
}

1;
