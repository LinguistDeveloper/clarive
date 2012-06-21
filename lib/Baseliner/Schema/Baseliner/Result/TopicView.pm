package Baseliner::Schema::Baseliner::Result::TopicView;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("TopicView");

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q{

    SELECT  T.MID TOPIC_MID, TITLE, T.CREATED_ON, T.CREATED_BY, STATUS,  NUMCOMMENT, C.ID CATEGORY_ID, C.NAME CATEGORY_NAME, 
            ID_CATEGORY_STATUS CATEGORY_STATUS_ID, S.NAME CATEGORY_STATUS_NAME, ID_PRIORITY AS PRIORITY_ID, TP.NAME PRIORITY_NAME,
            RESPONSE_TIME_MIN, EXPR_RESPONSE_TIME, DEADLINE_MIN, EXPR_DEADLINE, C.COLOR CATEGORY_COLOR, L.ID LABEL_ID, L.NAME LABEL_NAME, L.COLOR LABEL_COLOR,
            P.ID AS PROJECT_ID, P.NAME AS PROJECT_NAME, F.FILENAME AS FILE_NAME, PS.TEXT AS TEXT
            FROM  BALI_TOPIC T
                    LEFT JOIN BALI_TOPIC_CATEGORIES C ON ID_CATEGORY = C.ID
                    LEFT JOIN BALI_TOPIC_LABEL TL ON TL.ID_TOPIC = T.MID
                    LEFT JOIN BALI_LABEL L ON L.ID = TL.ID_LABEL
                    LEFT JOIN BALI_TOPIC_PRIORITY TP ON T.ID_PRIORITY = TP.ID
                    LEFT JOIN (SELECT COUNT(*) AS NUMCOMMENT, A.MID 
                                        FROM BALI_TOPIC A, BALI_MASTER_REL REL, BALI_POST B
                                        WHERE A.MID = REL.FROM_MID
                                        AND REL.TO_MID = B.MID
                                        AND REL.REL_TYPE = 'topic_post'
                                        GROUP BY A.MID) D ON T.MID = D.MID
                    LEFT JOIN BALI_TOPIC_STATUS S ON ID_CATEGORY_STATUS = S.ID
                    LEFT JOIN BALI_MASTER_REL REL_PR ON REL_PR.FROM_MID = T.MID AND REL_PR.REL_TYPE = 'topic_project'
                    LEFT JOIN BALI_PROJECT P ON P.MID = REL_PR.TO_MID
                    LEFT JOIN BALI_MASTER_REL REL_F ON REL_F.FROM_MID = T.MID AND REL_F.REL_TYPE = 'topic_file_version'
                    LEFT JOIN BALI_FILE_VERSION F ON F.MID = REL_F.TO_MID
                    LEFT JOIN BALI_MASTER_REL REL_PS ON REL_PS.FROM_MID = T.MID AND REL_PS.REL_TYPE = 'topic_post'
                    LEFT JOIN BALI_POST PS ON PS.MID = REL_PS.TO_MID
});

__PACKAGE__->add_columns(
	qw(
        topic_mid 
        title
        created_on
        created_by
        status
        numcomment
        category_id
        category_name
        category_status_id
        category_status_name        
        priority_id
        priority_name
        response_time_min
        expr_response_time
        deadline_min
        expr_deadline
        category_color
        label_id
        label_name
        label_color
        project_id
        project_name
        file_name
        text
    )
);

1;
