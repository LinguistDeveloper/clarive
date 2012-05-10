package Baseliner::Model::Issue;
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
    
    if($p->{priority} || $p->{priority} eq '0'){
        @rsptime = split('#', $p->{txt_rsptime_expr_min});
        @deadline = split('#', $p->{txt_deadline_expr_min});
    }

    given ( $action ) {
        when ( 'add' ) {
            try {
                my $issue = Baseliner->model( 'Baseliner::BaliIssue' )->create(
                    {
                        title       => $p->{title},
                        description => $p->{description},
                        created_by  => $p->{username},
                        id_category  => $p->{category},
                        id_category_status => $p->{status},
                        id_priority => $p->{id_priority},
                        response_time_min => $rsptime[1],
                        expr_response_time => $rsptime[0],
                        deadline_min => $deadline[1],
                        expr_deadline => $deadline[0]

                    }
                );
                $id     = $issue->id;
                $return = _loc( 'Issue added' );
            } ## end try
            catch {

                _throw _loc( 'Error adding Issue: %1', shift() );
            }
        } ## end when ( 'add' )
        when ( 'update' ) {
            try {
                my $id_issue = $p->{id};
                my $issue    = Baseliner->model( 'Baseliner::BaliIssue' )->find( $id_issue );
                $issue->title( $p->{title} );
                $issue->description( $p->{description} );
                $issue->id_category( $p->{category} );
                $issue->update();
                $id     = $id_issue;
                $return = _loc( 'Issue modified' );
            } ## end try
            catch {
                _throw _loc( 'Error modifying Issue: %1', shift() );
            }
        } ## end when ( 'update' )
        when ( 'delete' ) {
            my $id_issue = $p->{id};

            try {

                my $row = Baseliner->model( 'Baseliner::BaliIssue' )->find( $id_issue );
                $row->delete;

                $id     = $id_issue;
                $return = _loc( 'Issue deleted' );
            } ## end try
            catch {
                _throw _loc( 'Error deleting issue: %1', shift() );
            }
        } ## end when ( 'delete' )
        when ( 'close' ) {
            try {
                my $id_issue = $p->{id};
                my $issue    = Baseliner->model( 'Baseliner::BaliIssue' )->find( $id_issue );
                $issue->status( 'C' );
                $issue->update();

                $id     = $id_issue;
                $return = _loc( 'Issue closed' );
            } ## end try
            catch {
                _throw _loc( 'Error closing Issue: %1', shift() );
            }
        } ## end when ( 'close' )
    } ## end given
    return ( $return, $id );
} ## end sub update

sub GetIssues {
    my ( $self, $p, $labels, $categories, $projects ) = @_;
    my $orderby = $p->{orderby} || 'ID ASC';
    my $SQL;
    my $ids_categories;
    my @labels = _array $labels;
    my @categories = _array $categories;
    my @projects = _array $projects;
    my $ids_projects;
    
    if (@projects){
        $ids_projects =  '(BALI_ISSUE_PROJECT.ID_PROJECT = ' . join (' OR BALI_ISSUE_PROJECT.ID_PROJECT = ', @projects) . ')';
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
        my $ids_labels =  '(BALI_ISSUE_LABEL.ID_LABEL = ' . join (' OR BALI_ISSUE_LABEL.ID_LABEL = ', @labels) . ')';

        #$SQL = "SELECT BALI_ISSUE.ID AS ID, TITLE, BALI_ISSUE.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY
        #                FROM  (BALI_ISSUE INNER JOIN BALI_ISSUE_LABEL ON BALI_ISSUE.ID = BALI_ISSUE_LABEL.ID_ISSUE)  LEFT JOIN BALI_ISSUE_CATEGORIES F ON ID_CATEGORY = F.ID
        #                LEFT JOIN
        #                    (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_ISSUE A, BALI_ISSUE_MSG B WHERE A.ID = B.ID_ISSUE GROUP BY A.ID) D
        #                ON BALI_ISSUE.ID = D.ID WHERE $ids_labels AND $ids_categories";
          
        $SQL = "SELECT BALI_ISSUE.ID AS ID, TITLE, BALI_ISSUE.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY
                        FROM  ((BALI_ISSUE INNER JOIN BALI_ISSUE_PROJECT ON BALI_ISSUE.ID = BALI_ISSUE_PROJECT.ID_ISSUE AND $ids_projects ) INNER JOIN BALI_ISSUE_LABEL ON BALI_ISSUE.ID = BALI_ISSUE_LABEL.ID_ISSUE)  LEFT JOIN BALI_ISSUE_CATEGORIES F ON ID_CATEGORY = F.ID
                        LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_ISSUE A, BALI_ISSUE_MSG B WHERE A.ID = B.ID_ISSUE GROUP BY A.ID) D
                        ON BALI_ISSUE.ID = D.ID WHERE $ids_labels AND $ids_categories
                        
                UNION ALL        
                        
                SELECT BALI_ISSUE.ID AS ID, TITLE, BALI_ISSUE.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY
                        FROM  ((BALI_ISSUE LEFT JOIN BALI_ISSUE_PROJECT ON BALI_ISSUE.ID = BALI_ISSUE_PROJECT.ID_ISSUE ) INNER JOIN BALI_ISSUE_LABEL ON BALI_ISSUE.ID = BALI_ISSUE_LABEL.ID_ISSUE)  LEFT JOIN BALI_ISSUE_CATEGORIES F ON ID_CATEGORY = F.ID
                        LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_ISSUE A, BALI_ISSUE_MSG B WHERE A.ID = B.ID_ISSUE GROUP BY A.ID) D
                        ON BALI_ISSUE.ID = D.ID WHERE $ids_labels AND $ids_categories AND ID_PROJECT IS NULL ";
                       
    }else{
        #$SQL = "SELECT C.ID AS ID, TITLE, C.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY
        #                FROM  (BALI_ISSUE C LEFT JOIN BALI_ISSUE_CATEGORIES F ON C.ID_CATEGORY = F.ID)
        #                LEFT JOIN
        #                    (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_ISSUE A, BALI_ISSUE_MSG B WHERE A.ID = B.ID_ISSUE GROUP BY A.ID) D
        #                ON C.ID = D.ID WHERE $ids_categories ORDER BY $orderby ";
        
        $SQL = "SELECT BALI_ISSUE.ID AS ID, TITLE, BALI_ISSUE.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY
                        FROM  ((BALI_ISSUE INNER JOIN BALI_ISSUE_PROJECT ON BALI_ISSUE.ID = BALI_ISSUE_PROJECT.ID_ISSUE AND $ids_projects ) LEFT JOIN BALI_ISSUE_CATEGORIES F ON BALI_ISSUE.ID_CATEGORY = F.ID)
                        LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_ISSUE A, BALI_ISSUE_MSG B WHERE A.ID = B.ID_ISSUE GROUP BY A.ID) D
                        ON BALI_ISSUE.ID = D.ID WHERE $ids_categories
                        
                UNION ALL
                
                SELECT BALI_ISSUE.ID AS ID, TITLE, BALI_ISSUE.DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY
                        FROM  ((BALI_ISSUE LEFT JOIN BALI_ISSUE_PROJECT ON BALI_ISSUE.ID = BALI_ISSUE_PROJECT.ID_ISSUE ) LEFT JOIN BALI_ISSUE_CATEGORIES F ON BALI_ISSUE.ID_CATEGORY = F.ID)
                        LEFT JOIN
                            (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_ISSUE A, BALI_ISSUE_MSG B WHERE A.ID = B.ID_ISSUE GROUP BY A.ID) D
                        ON BALI_ISSUE.ID = D.ID WHERE $ids_categories AND ID_PROJECT IS NULL
                        
                ORDER BY $orderby ";        
    }
   
    return $db->array_hash( $SQL );
}

1;
