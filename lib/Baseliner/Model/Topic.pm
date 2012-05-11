package Baseliner::Model::Topic;
use Moose;
use Baseliner::Utils;
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
    my @rsptime = {};
    my @deadline = {};
    
    if( length $p->{priority} ) {
        @rsptime = split('#', $p->{txt_rsptime_expr_min});
        @deadline = split('#', $p->{txt_deadline_expr_min});
    }
    given ( $action ) {
        when ( 'add' ) {
            try {
                my $topic = Baseliner->model( 'Baseliner::BaliTopic' )->create(
                    {
                        title       => $p->{title},
                        description => $p->{description},
                        created_by  => $p->{username},
                        id_category  => $p->{category},
                        id_category_status => $p->{status},
                        id_priority => $p->{priority},
                        response_time_min => $rsptime[1],
                        expr_response_time => $rsptime[0],
                        deadline_min => $deadline[1],
                        expr_deadline => $deadline[0]

                    }
                );
                $id     = $topic->id;
                $return = _loc( 'Topic added' );
            } ## end try
            catch {

                _throw _loc( 'Error adding Topic: %1', shift() );
            }
        } ## end when ( 'add' )
        when ( 'update' ) {
            try {
                my $id_topic = $p->{id};
                my $topic    = Baseliner->model( 'Baseliner::BaliTopic' )->find( $id_topic );
                $topic->title( $p->{title} );
                $topic->description( $p->{description} );
                $topic->id_category( $p->{category} );
                $topic->id_category_status( $p->{status} );
                $topic->id_priority( $p->{priority} );
                $topic->response_time_min( $rsptime[1] );
                $topic->expr_response_time( $rsptime[0] );
                $topic->deadline_min( $deadline[1] );
                $topic->expr_deadline( $deadline[0] );
                
                
                $topic->update();
                $id     = $id_topic;
                $return = _loc( 'Topic modified' );
            } ## end try
            catch {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            }
        } ## end when ( 'update' )
        when ( 'delete' ) {
            my $id_topic = $p->{id};

            try {

                my $row = Baseliner->model( 'Baseliner::BaliTopic' )->find( $id_topic );
                $row->delete;

                $id     = $id_topic;
                $return = _loc( 'Topic deleted' );
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
                $return = _loc( 'Topic closed' );
            } ## end try
            catch {
                _throw _loc( 'Error closing Topic: %1', shift() );
            }
        } ## end when ( 'close' )
    } ## end given
    return ( $return, $id );
} ## end sub update

sub GetTopics {
    my ( $self, $p, $labels, $categories, $projects ) = @_;
    my $orderby = $p->{orderby} || 'ID ASC';
    my $SQL;
    my $ids_categories;
    my @labels = _array $labels;
    my @categories = _array $categories;
    my @projects = _array $projects;
    my $ids_projects;
    
    if (@projects){
        $ids_projects =  '(BALI_TOPIC_PROJECT.ID_PROJECT = ' . join (' OR BALI_TOPIC_PROJECT.ID_PROJECT = ', @projects) . ')';
    }
    else{
        $ids_projects = '1 = 0';
    }
    
    if (@categories){
        $ids_categories =  '(F.ID = ' . join (' OR F.ID = ', @categories) . ')';
    }else{
        $ids_categories = '1 = 1';
    }
    
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    if (@labels){
        my $ids_labels =  '(BALI_TOPIC_LABEL.ID_LABEL = ' . join (' OR BALI_TOPIC_LABEL.ID_LABEL = ', @labels) . ')';

        #$SQL = "SELECT BALI_TOPIC.ID AS ID, TITLE, BALI_TOPIC.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY
        #                FROM  (BALI_TOPIC INNER JOIN BALI_TOPIC_LABEL ON BALI_TOPIC.ID = BALI_TOPIC_LABEL.ID_TOPIC)  LEFT JOIN BALI_TOPIC_CATEGORIES F ON ID_CATEGORY = F.ID
        #                LEFT JOIN
        #                    (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_TOPIC A, BALI_TOPIC_MSG B WHERE A.ID = B.ID_TOPIC GROUP BY A.ID) D
        #                ON BALI_TOPIC.ID = D.ID WHERE $ids_labels AND $ids_categories";
          
        $SQL = "SELECT BALI_TOPIC.ID AS ID, TITLE, BALI_TOPIC.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY,
                        ID_CATEGORY_STATUS, ID_PRIORITY, RESPONSE_TIME_MIN, EXPR_RESPONSE_TIME, DEADLINE_MIN, EXPR_DEADLINE
                        FROM  ((BALI_TOPIC INNER JOIN BALI_TOPIC_PROJECT ON BALI_TOPIC.ID = BALI_TOPIC_PROJECT.ID_TOPIC AND $ids_projects ) INNER JOIN BALI_TOPIC_LABEL ON BALI_TOPIC.ID = BALI_TOPIC_LABEL.ID_TOPIC)  LEFT JOIN BALI_TOPIC_CATEGORIES F ON ID_CATEGORY = F.ID
                        LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_TOPIC A, BALI_TOPIC_MSG B WHERE A.ID = B.ID_TOPIC GROUP BY A.ID) D
                        ON BALI_TOPIC.ID = D.ID WHERE $ids_labels AND $ids_categories
                        
                UNION ALL        
                        
                SELECT BALI_TOPIC.ID AS ID, TITLE, BALI_TOPIC.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY,
                        ID_CATEGORY_STATUS, ID_PRIORITY, RESPONSE_TIME_MIN, EXPR_RESPONSE_TIME, DEADLINE_MIN, EXPR_DEADLINE
                        FROM  ((BALI_TOPIC LEFT JOIN BALI_TOPIC_PROJECT ON BALI_TOPIC.ID = BALI_TOPIC_PROJECT.ID_TOPIC ) INNER JOIN BALI_TOPIC_LABEL ON BALI_TOPIC.ID = BALI_TOPIC_LABEL.ID_TOPIC)  LEFT JOIN BALI_TOPIC_CATEGORIES F ON ID_CATEGORY = F.ID
                        LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_TOPIC A, BALI_TOPIC_MSG B WHERE A.ID = B.ID_TOPIC GROUP BY A.ID) D
                        ON BALI_TOPIC.ID = D.ID WHERE $ids_labels AND $ids_categories AND ID_PROJECT IS NULL ";
                       
    }else{
        #$SQL = "SELECT C.ID AS ID, TITLE, C.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY
        #                FROM  (BALI_TOPIC C LEFT JOIN BALI_TOPIC_CATEGORIES F ON C.ID_CATEGORY = F.ID)
        #                LEFT JOIN
        #                    (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_TOPIC A, BALI_TOPIC_MSG B WHERE A.ID = B.ID_TOPIC GROUP BY A.ID) D
        #                ON C.ID = D.ID WHERE $ids_categories ORDER BY $orderby ";
        
        $SQL = "SELECT BALI_TOPIC.ID AS ID, TITLE, BALI_TOPIC.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY,
                        ID_CATEGORY_STATUS, ID_PRIORITY, RESPONSE_TIME_MIN, EXPR_RESPONSE_TIME, DEADLINE_MIN, EXPR_DEADLINE
                        FROM  ((BALI_TOPIC INNER JOIN BALI_TOPIC_PROJECT ON BALI_TOPIC.ID = BALI_TOPIC_PROJECT.ID_TOPIC AND $ids_projects ) LEFT JOIN BALI_TOPIC_CATEGORIES F ON BALI_TOPIC.ID_CATEGORY = F.ID)
                        LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_TOPIC A, BALI_TOPIC_MSG B WHERE A.ID = B.ID_TOPIC GROUP BY A.ID) D
                        ON BALI_TOPIC.ID = D.ID WHERE $ids_categories
                        
                UNION ALL
                
                SELECT BALI_TOPIC.ID AS ID, TITLE, BALI_TOPIC.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY,
                        ID_CATEGORY_STATUS, ID_PRIORITY, RESPONSE_TIME_MIN, EXPR_RESPONSE_TIME, DEADLINE_MIN, EXPR_DEADLINE
                        FROM  ((BALI_TOPIC LEFT JOIN BALI_TOPIC_PROJECT ON BALI_TOPIC.ID = BALI_TOPIC_PROJECT.ID_TOPIC ) LEFT JOIN BALI_TOPIC_CATEGORIES F ON BALI_TOPIC.ID_CATEGORY = F.ID)
                        LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_TOPIC A, BALI_TOPIC_MSG B WHERE A.ID = B.ID_TOPIC GROUP BY A.ID) D
                        ON BALI_TOPIC.ID = D.ID WHERE $ids_categories AND ID_PROJECT IS NULL
                        
                ORDER BY $orderby ";        
    }
   
    return $db->array_hash( $SQL );
}

1;
