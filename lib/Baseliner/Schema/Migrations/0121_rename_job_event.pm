package Baseliner::Schema::Migrations::0121_rename_job_event;
use Moose;

sub upgrade {
    mdb->notification->update(
        { event_key => 'event.rule.trap' },
        { '$set'    => { event_key => 'event.job.trapped' } },
        { multiple  => 1 }
    );

    mdb->rule->update(
        { rule_event => 'event.rule.trap' },
        { '$set'     => { rule_event => 'event.job.trapped' } },
        { multiple   => 1 }
    );
}

sub downgrade {
}

1;
