package Baseliner::Controller::Calendar;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use DateTime;
use Try::Tiny;
use Baseliner::Sugar;

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
            my $id = mdb->seq('master_cal');
            mdb->master_cal->insert({ id=>$id, mid=>$mid, start_date=>$start_date, end_date=>$end_date, allday=>$allday, slotname=>$slotname });
        }
    }
    $c->stash->{json} = { success=>\1, msg=>'' };
    $c->forward('View::JSON');
}

sub events : Local {
   my ($self,$c)=@_;
   my $p = $c->req->params;
   my @events;
   my $mode = $p->{mode} // 'activity';
   my $calstart = $p->{start};
   my $calend = $p->{end};
   my $cleant = sub{
       $_[0] =~ s/T/ /g;
       ($_[0], my $tz) = split(/\+/, $_[0] );
   };
   $cleant->($calstart);
   $cleant->($calend);
   # topics
   push @events, map {
       my $start = $$_{created_on};
       my $end = $$_{ts};
       { title=>sprintf('%s #%s %s', $_->{category}{name}, $_->{mid}, $_->{title}), color=>$_->{category}{color}, 
           start=>$start, end=>$end, allDay=>\0, 
       }
   } mdb->topic->find({ 'category.name'=>mdb->in('Release','Project','Changeset'), created_on=>{ '$lt'=>$calend }, ts=>{'$gt'=>$calstart} })->all;

   # jobs
   push @events, map {
       # TODO consider multiplying job into different steps PRE and RUN
       my $title = sprintf('%s %s', $$_{name},join(',',_array($$_{job_contents}{list_apps})) );
       { title=>$title, color=>'#111', start=>$$_{schedtime}, end=>$$_{endtime}, allDay=>\0 }
      
   } ci->job->find({ schedtime=>{ '$lt'=>$calend }, endtime=>{'$gt'=>$calstart} })->all;
   $c->stash->{json} = { success=>\1, events=>\@events };
   $c->forward('View::JSON');
}

1;
