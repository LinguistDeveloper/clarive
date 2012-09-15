package Baseliner::Model::Events;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

with 'Baseliner::Role::Service';

register 'service.event.daemon' => {
    daemon => 1,
    handler => sub {
        my ($self, $c, $config ) = @_;
        for( 1..1000 ) {
            $self->run_once;
            sleep( $config->{frequency} // 15 );
        }
    }
};

register 'service.event.run_once' => {
    handler=> \&run_once,
};

sub run_once {
    my ($self, $c, $data ) = @_;
    my $rs = DB->BaliEvent->search({ event_status => 'new' }, { order_by =>{ -asc => 'id' } });
    while( my $ev = $rs->next ) {
        my $stash = $ev->event_data ? _load( $ev->event_data ) : {};
        try {
            # run rules for this event
            my $ret = Baseliner->model('Rules')->run_rules( event=>$ev->event_key, when=>'post-offline', stash=>$stash );
            # save log
            for my $rule ( _array( $ret->{rule_log} ) ) {
                my $rulerow = DB->BaliEventRules->create({
                    id_event=> $ev->id, id_rule=> $rule->{id}, stash_data=> _dump( $rule->{ret} ),
                });
                $rulerow->dsl( $rule->{dsl} );
                $rulerow->update;
            }
            $ev->update({ event_status=>'ok' });
        } catch {
            my $err = shift;
            # TODO global error or a rule by rule 
            $ev->update({ event_status=>'ko' });
        };
    }
}

1;
