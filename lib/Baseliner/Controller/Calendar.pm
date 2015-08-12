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

our $all_colors = [
    '8E44AD', '30BED0', 'A01515', 'A83030', '003366', '000080', '333399', '333333',
    '800000', 'FF6600', '808000', '008000', '008080', '0000FF', '666699', '808080',
    'FF0000', 'FF9900', '99CC00', '339966', '33CCCC', '3366FF', '800080', '969696',
    'FF00FF', 'FFCC00', 'F1C40F', '00ACFF', '20BCFF', '00CCFF', '993366', 'C0C0C0',
    'FF99CC', 'DDAA55', 'BBBB77', '88CC88', 'D35400', '99CCFF', 'CC99FF', '11B411',
    '1ABC9C', '16A085', '2ECC71', '27AE60', '3498DB', '2980B9', 'E74C3C', 'C0392B'
];

sub events : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my @events;
    my $mode = $p->{mode} // 'activity';
    my $calstart = $p->{start};
    my $calend = $p->{end};

    my $categories = $p->{categories};
    my $condition = length $p->{condition} ? Util->_decode_json("{" . $p->{condition} . "}") : {};
    my $id_project = $p->{project_id};
    my $topic_mid = $p->{topic_mid};
    my $show_jobs = length $p->{show_jobs} ? _bool($p->{show_jobs}) : 1;
    my $query_type = $p->{query_type};
    my $id_fieldlet = $p->{id_fieldlet};
    my $not_in_category = $p->{not_in_category} // 0;

    my $default_mask = '${category.acronym}#${topic.mid} ${topic.title}';
    my $label_mask = $p->{label_mask} || $default_mask;

    my $cleant = sub{
        $_[0] =~ s/T/ /g;
        ($_[0], my $tz) = split(/\+/, $_[0] );
    };
    $cleant->($calstart);
    $cleant->($calend);

    my %cats = map{ $$_{id}=>$_ } mdb->category->find({ ( $categories ? (id=>mdb->in($categories)) : () ) })->fields({ workflow=>0, fieldlets=>0 })->all;
    my $where_cat = $not_in_category ? { 'category.id'=>mdb->nin(keys %cats) } : { 'category.id'=>mdb->in(keys %cats) };
    my $where = { %$where_cat, %$condition };
    if( length $topic_mid){
        # topic and children
        $where->{mid} = mdb->in( $topic_mid, map{ $$_{to_mid} } mdb->master_rel->find({ from_mid=>$topic_mid })->fields({ to_mid=>1 })->all );
    } elsif( $id_project ){
        my @mids_in = ();
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{project_id}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        $where->{mid} = mdb->in(@mids_in) if @mids_in;
    }

    my @topics;
    my %master_cal;
    if( $query_type eq 'cal_field' ) {
        _fail _loc 'Missing calendar field(s)' unless $id_fieldlet;
        @topics = mdb->topic->find($where)->fields({ _txt=>0 })->all;
        map { push @{ $master_cal{$$_{mid}} } => $_ } 
            mdb->master_cal->find({ mid=>mdb->in(map{$$_{mid}}@topics), rel_field=>mdb->in( ref $id_fieldlet ? $id_fieldlet : split /,/,$id_fieldlet) })->all;
    } elsif( $query_type eq 'open_topics' ) {
        @topics = mdb->topic->find({ %$where,
                '$or'=>[ 
                        { created_on=>{ '$lt'=>$calend } }, 
                        { closed_on=>{'$gt'=>$calstart} }, 
                        { '$and'=>[{ created_on=>{'$gte'=>$calstart} },{ closed_on=>{'$lte'=>$calend} } ] },
                        { created_on=>{ '$lte'=>$calend }, closed_on=>{'$exists'=>0} },
                    ] })
                ->fields({ _txt=>0 })->all;
    } else {
        # start_end
        @topics = mdb->topic->find({ %$where,
                '$or'=>[ { created_on=>{ '$lt'=>$calend } }, { ts=>{'$gt'=>$calstart} }, { '$and'=>[{ created_on=>{'$gte'=>$calstart} },{ ts=>{'$lte'=>$calend} } ] } ] })
                ->fields({ _txt=>0 })->all;
    }

    my $color_index = 0;
    my %topic_colors; 

    # topics
    for my $topic ( @topics ) {
        my $cat = $cats{ $topic->{category}{id} };
        my $label = Util->parse_vars( $label_mask, { topic=>$topic, category=>$cat });
        $label = Util->parse_vars( $default_mask, { topic=>$topic, category=>$cat }) if $label eq $label_mask; ## oops, the parse didn't parse anything, so use the default

        if( $query_type eq 'cal_field' ) {
            my $cals = $master_cal{ $topic->{mid} } || next;
            for my $cal ( _array $cals ) {
                my $start = $cal->{plan_start_date};
                my $end   = $cal->{plan_end_date};
                next if $start lt $calstart && $end lt $calend;
                my $color = ( $topic_colors{ $topic->{mid} . $cal->{slotname} } //= $all_colors->[$color_index++] ); 
                push @events, {
                    title       => "$label [$cal->{slotname}]",
                    start       => $start,
                    end         => $end,
                    color       => '#' . $color,
                    allDay      => \1,
                    mid         => $topic->{mid},
                    acronym     => $cat->{acronym} || $cat->{name},
                    topic_color => $cat->{color},
                  };
            }
        } elsif( $query_type eq 'open_topics' ) {
            my $start = $topic->{created_on};
            my $end = $topic->{closed_on} || mdb->now;
            push @events, {
                title       => $label,
                color       => $cat->{color},
                start       => $start,
                end         => $end,
                allDay      => \0,
                mid         => $topic->{mid},
                acronym     => $cat->{acronym} || $cat->{name},
                topic_color => $cat->{color},
              };
        } else {
            my $start = $topic->{created_on};
            my $end = $topic->{ts};
            push @events, {
                title       => $label,
                color       => $cat->{color},
                start       => $start,
                end         => $end,
                allDay      => \0,
                mid         => $topic->{mid},
                acronym     => $cat->{acronym} || $cat->{name},
                topic_color => $cat->{color},
              };
        }
    }

   # jobs
   if( $show_jobs ) {
       push @events, map {
           # TODO consider multiplying job into different steps PRE and RUN
           my $title = sprintf('%s %s', $$_{name},join(',',_array($$_{job_contents}{list_apps})) );
           { title=>$title, color=>'#111', start=>$$_{schedtime}, end=>$$_{endtime}, allDay=>\0 }
          
       } ci->job->find({ schedtime=>{ '$lt'=>$calend }, endtime=>{'$gt'=>$calstart} })->all;
   }
   my @warnings;
   if( length $id_fieldlet && $query_type eq 'cal_field' ) {
       for my $id (_array $id_fieldlet ) {
           next if mdb->topic->find({ %$where_cat, $id=>{'$exists'=>1} })->count;
           push @warnings, _loc('Fieldlet `%1` not in the database for any of the selected topic categories. Removed or misspelled?', $id);
       }
   }
   $c->stash->{json} = { success=>\1, events=>\@events, warnings=>\@warnings };
   $c->forward('View::JSON');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
