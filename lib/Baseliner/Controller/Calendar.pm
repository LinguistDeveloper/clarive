package Baseliner::Controller::Calendar;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

sub event : Local {
    my ($self, $c, $action)= @_;
    my $p = $c->req->params;
    my $mid = $p->{mid};
    if( length $mid ) {
        my $start_date = $p->{start_date};
        $start_date = $p->{date} unless length $start_date;
        my $end_date = $p->{end_date};
        my $allday = $p->{allday} eq 'true' ? 1 : 0;
        my $slotname = $p->{slotname} || 'plan';
        $end_date = $start_date if( $allday ) ;
        $start_date =~ s{T}{ }g;
        $end_date =~ s{T}{ }g;
        if( $action eq 'add' ) {
            $c->model('Baseliner::BaliMasterCal')->create({ mid=>$mid, start_date=>$start_date, end_date=>$end_date, allday=>$allday, slotname=>$slotname });
        }
    }
    $c->stash->{json} = { success=>\1, msg=>'' };
    $c->forward('View::JSON');
}

1;
