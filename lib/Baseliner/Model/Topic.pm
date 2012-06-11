package Baseliner::Model::Topic;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

sub update {
    my ( $self, $p ) = @_;
    my $action = $p->{action};

    _log "====================== \n" . _dump $p;

    my $return;
    my $id;
    my $mid;
    my $status;
    my @rsptime = ();
    my @deadline = ();
    
    if( length $p->{priority} ) {
        @rsptime = split('#', $p->{txt_rsptime_expr_min});
        @deadline = split('#', $p->{txt_deadline_expr_min});
    }
    given ( $action ) {
        when ( 'add' ) {
            try {
                my $topic = master_new 'bali_topic' => sub {
                    my $mid = shift;    
                    Baseliner->model('Baseliner::BaliTopic')->create(
                        {   title              => $p->{title},
                            description        => $p->{description},
                            created_by         => $p->{username},
                            mid                => $mid,
                            id_category        => $p->{category},
                            id_category_status => $p->{status_new},
                            id_priority        => $p->{priority},
                            response_time_min  => $rsptime[1],
                            expr_response_time => $rsptime[0],
                            deadline_min       => $deadline[1],
                            expr_deadline      => $deadline[0]

                        }
                    );
                };
                
                my @projects = _array( $p->{projects} );
                
                if (@projects) {
                    my $project;
                    my $rs_projects = Baseliner->model('Baseliner::BaliProject')->search({id =>\@projects});
                    while($project = $rs_projects->next){
                        my $mid;
                        if($project->mid){
                            $mid = $project->mid
                        }
                        else{
                            my $project_mid = master_new 'bali_project' => sub {
                                my $mid = shift;
                                $project->mid($mid);
                                $project->update();
                            };
                        }
                        $topic->add_to_projects($project, { rel_type=>'topic_project'});
                    }

                }
                
                my @users = _array( $p->{users});
                
                if (@users){
                    my $user;
                    my $rs_users = Baseliner->model('Baseliner::BaliUser')->search({id =>\@users});
                    while($user = $rs_users->next){
                        my $mid;
                        if($user->mid){
                            $mid = $user->mid
                        }
                        else{
                        	my $user_mid = master_new 'bali_user' => sub {
                                my $mid = shift;
                                $user->mid($mid);
                                $user->update();
                            };
                        }
                        $topic->add_to_users( $user, { rel_type=>'topic_users' });
                    }
                }
                
                $id     = $topic->id;
                $mid    = $topic->mid;
                $status = $topic->id_category_status;
                $return = 'Topic added';
            } ## end try
            catch {
                _throw _loc( 'Error adding Topic: %1', shift() );
            };
        } ## end when ( 'add' )
        when ( 'update' ) {
            try {
                my $id_topic = $p->{id};
                my $topic    = Baseliner->model( 'Baseliner::BaliTopic' )->find( $id_topic );
                $topic->title( $p->{title} );
                $topic->description( $p->{description} );
                $topic->id_category( $p->{category} ) if is_number( $p->{category} ) ;
                $topic->id_category_status( $p->{status_new} ) if is_number( $p->{status_new} );
                $topic->id_priority( $p->{priority} ) if is_number( $p->{priority} );
                $topic->response_time_min( $rsptime[1] );
                $topic->expr_response_time( $rsptime[0] );
                $topic->deadline_min( $deadline[1] );
                $topic->expr_deadline( $deadline[0] );

                my $projects = Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => $p->{mid}, rel_type => 'topic_project'})->delete;
                my @projects = _array( $p->{projects} );
                if (@projects){
                    my $project;
                    my $rs_projects = Baseliner->model('Baseliner::BaliProject')->search({id =>\@projects});
                    while($project = $rs_projects->next){
                        my $mid;
                        if($project->mid){
                            $mid = $project->mid
                        }
                        else{
                            my $project_mid = master_new 'bali_project' => sub {
                                my $mid = shift;
                                $project->mid($mid);
                                $project->update();
                            }
                        }
                        $topic->add_to_projects( $project, { rel_type=>'topic_project' } );
                    }
                }
                
                my $users =  Baseliner->model('Baseliner::BaliMasterRel')->search( {from_mid => $p->{mid}, rel_type => 'topic_users'})->delete;
                my @users = _array( $p->{users} );
                if (@users){
                    #my $users =  Baseliner->model('Baseliner::BaliMasterRel')->search( {from_mid => $p->{mid}, rel_type => 'topic_users'})->delete;
                    my $user;
                    my $rs_users = Baseliner->model('Baseliner::BaliUser')->search({id =>\@users});
                    while($user = $rs_users->next){
                        my $mid;
                        if($user->mid){
                            $mid = $user->mid
                        }
                        else{
                        	my $user_mid = master_new 'bali_user' => sub {
                                my $mid = shift;
                                $user->mid($mid);
                                $user->update();
                            };
                        }
                        $topic->add_to_users( $user, { rel_type=>'topic_users' });
                    }                    
                }
                
                $topic->update();
                $id     = $id_topic;
                $mid    = $topic->mid;
                $status = $topic->id_category_status;
                $return = 'Topic modified';
            } ## end try
            catch {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            }
        } ## end when ( 'update' )
        when ( 'delete' ) {
            my $id_topic = $p->{id};
            try {
                my $row = Baseliner->model( 'Baseliner::BaliTopic' )->find( $id_topic );
                $mid    = $row->mid;
                #my $row2 = Baseliner->model( 'Baseliner::BaliMaster' )->find( $row->mid );
                $row->delete;

                $id     = $id_topic;
                
                $return = 'Topic deleted';
            } ## end try
            catch {
                _throw _loc( 'Error deleting topic: %1', shift() );
            }
        } ## end when ( 'delete' )
        when ( 'close' ) {
            try {
                my $id_topic = $p->{id};
                my $topic    = Baseliner->model( 'Baseliner::BaliTopic' )->find( $id_topic );
                $topic->status( 'C' );
                $topic->update();

                $id     = $id_topic;
                $mid    = $topic->mid;
                $return = 'Topic closed'
            } ## end try
            catch {
                _throw _loc( 'Error closing Topic: %1', shift() );
            }
        } ## end when ( 'close' )
    } ## end given
    return ( $return, $id, $mid, $status );
} ## end sub update

sub GetTopics {
    ##my ( $self, $p, $labels, $categories, $projects, $statuses, $priorities ) = @_;
    my ( $self, $p ) = @_;
    my $orderby = $p->{orderby} || 'ID ASC';
    my $username = $p->{username};
    my $hoy = $p->{hoy} eq 'true' ? 1:0;;
    my $asignadas = $p->{asignadas} eq 'true' ? 1:0;
    my @labels = _array $p->{labels};
    my @categories = _array $p->{categories};
    my @statuses = _array $p->{statuses};
    my @priorities = _array $p->{priorities};
    
    my $SQL;
    
    ##my $ids_categories;
    ##my @labels = _array $labels;
    ##my @categories = _array $categories;
    ##my @projects = _array $projects;
    ##my @statuses = _array $statuses;
    ##my @priorities = _array $priorities;
    ##my $ids_projects;
    
    ##if (@projects){
    ##    $ids_projects =  '(BALI_TOPIC_PROJECT.ID_PROJECT = ' . join (' OR BALI_TOPIC_PROJECT.ID_PROJECT = ', @projects) . ')';
    ##}
    ##else{
    ##    $ids_projects = '1 = 0';
    ##}
    ##
    ##if (@categories){
    ##    $ids_categories =  '(F.ID = ' . join (' OR F.ID = ', @categories) . ')';
    ##}else{
    ##    $ids_categories = '1 = 1';
    ##}
    
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    $SQL = "SELECT BALI_TOPIC.MID AS MID, BALI_TOPIC.ID AS ID, TITLE,
                    CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY,
                    ID_CATEGORY_STATUS, ID_PRIORITY, RESPONSE_TIME_MIN, EXPR_RESPONSE_TIME, DEADLINE_MIN, EXPR_DEADLINE, F.COLOR CATEGORY_COLOR
                    FROM  BALI_TOPIC LEFT JOIN BALI_TOPIC_CATEGORIES F ON ID_CATEGORY = F.ID
                      LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.MID 
                                FROM BALI_TOPIC A, BALI_MASTER_REL REL, BALI_POST B
                                WHERE A.MID = REL.FROM_MID
                                AND REL.TO_MID = B.MID
                                AND REL.REL_TYPE = 'topic_post'
                                GROUP BY A.MID) D
                      ON BALI_TOPIC.MID = D.MID ORDER BY ?";
    
    my @datas = $db->array_hash( $SQL, $orderby);
    
    my @temp =();
    my %seen   = ();
    
    if($hoy){
        my $Hoy = DateTime->now->ymd;
        foreach my $data (@datas){
            my $created_on = parse_date( 'dd/mm/Y', $data->{created_on})->ymd;
            push @temp, $data if $Hoy eq $created_on;
        }
        @datas = @temp;
    }
    
    @temp =();
    
    if($asignadas){
        my $rs_user = Baseliner->model('Baseliner::BaliUser')->search( username => $username )->first;
        if($rs_user){
            my $topics = Baseliner->model('Baseliner::BaliMasterRel')->search({to_mid => $rs_user->mid, rel_type => 'topic_users'}, { select=>[qw(from_mid)]});
            while( my $topic = $topics->next ) {
                push @temp, grep { $_->{mid} =~ $topic->from_mid  } @datas if $topic;
            }
            @datas = @temp;
        }        
    }
    
    @temp =();
    
    if(@labels){
        my @f_labels;
        my $labels;
        
        foreach my $label (@labels){
            push @f_labels, $label;
        }
        
        $labels = Baseliner->model('Baseliner::BaliTopicLabel')->search({id_label => \@f_labels});
        while( my $label = $labels->next ) {
            push @temp, grep { $_->{id} =~ $label->id_topic && ! $seen{ $_->{id} }++ } @datas if $label;
        }
        @datas = @temp;
        
    }
    
    
    @temp =();
    %seen   = ();
    
    if(@categories){
        foreach my $category (@categories){
            push @temp, grep { $_->{category} =~ $category && ! $seen{ $_->{id} }++ } @datas if $category;    
        }
        @datas = @temp;
    }
    
    @temp =();
    %seen   = ();
    
    if(@statuses){
        foreach my $status (@statuses){
            push @temp, grep { $_->{id_category_status} =~ $status && ! $seen{ $_->{id} }++ } @datas if $status;    
        }
        @datas = @temp;
    }        

    @temp =();
    %seen   = ();
    
    if(@priorities){
        foreach my $priority (@priorities){
            push @temp, grep { $_->{id_priority} =~ $priority && ! $seen{ $_->{id} }++ } @datas if $priority;
        }
        @datas = @temp;            
    }    
    
    return @datas;
}

1;
