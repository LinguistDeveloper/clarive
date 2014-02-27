package Baseliner::Schema::Baseliner::Result::TopicView;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("TopicView");

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q{

    SELECT  T.MID TOPIC_MID,
            T.MID,
            T.TITLE,
            T.CREATED_ON,
            T.CREATED_BY,
            T.MODIFIED_ON,
            T.MODIFIED_BY,
            T.DESCRIPTION,
            T.STATUS, 
            NUMCOMMENT,
            C.ID CATEGORY_ID,
            C.NAME CATEGORY_NAME,
            T.PROGRESS,
            T.ID_CATEGORY_STATUS CATEGORY_STATUS_ID,
            S.NAME CATEGORY_STATUS_NAME,
            S.SEQ CATEGORY_STATUS_SEQ,
            S.TYPE CATEGORY_STATUS_TYPE,
            T.ID_PRIORITY AS PRIORITY_ID,
            TP.NAME PRIORITY_NAME,
            TP.RESPONSE_TIME_MIN,
            TP.EXPR_RESPONSE_TIME,
            TP.DEADLINE_MIN,
            TP.EXPR_DEADLINE,
            C.COLOR CATEGORY_COLOR,
            C.IS_CHANGESET,
            C.IS_RELEASE,
            F.FILENAME AS FILE_NAME,
            PS.TEXT AS TEXT,
            NUM_FILE,
            U.USERNAME ASSIGNEE,
            MA.MONIKER,
            DS.NAME directory
            FROM  BALI_TOPIC T
                    JOIN BALI_MASTER MA ON T.MID = MA.MID
                    LEFT JOIN BALI_TOPIC_CATEGORIES C ON T.ID_CATEGORY = C.ID
                    LEFT JOIN BALI_TOPIC_PRIORITY TP ON T.ID_PRIORITY = TP.ID
                    LEFT JOIN (SELECT COUNT(*) AS NUMCOMMENT, A.MID 
                                        FROM BALI_TOPIC A, BALI_MASTER_REL REL, BALI_POST B
                                        WHERE A.MID = REL.FROM_MID
                                        AND REL.TO_MID = B.MID
                                        AND REL.REL_TYPE = 'topic_post'
                                        GROUP BY A.MID) D ON T.MID = D.MID
                    LEFT JOIN (SELECT COUNT(*) AS NUM_FILE, E.MID 
                                        FROM BALI_TOPIC E, BALI_MASTER_REL REL1, BALI_FILE_VERSION G
                                        WHERE E.MID = REL1.FROM_MID
                                        AND REL1.TO_MID = G.MID
                                        AND REL1.REL_TYPE = 'topic_file_version'
                                        GROUP BY E.MID) H ON T.MID = H.MID                                         
                    LEFT JOIN BALI_TOPIC_STATUS S ON T.ID_CATEGORY_STATUS = S.ID

                    LEFT JOIN BALI_MASTER_REL REL_F ON REL_F.FROM_MID = T.MID AND REL_F.REL_TYPE = 'topic_file_version'
                    LEFT JOIN BALI_FILE_VERSION F ON F.MID = REL_F.TO_MID

                    LEFT JOIN BALI_MASTER_REL REL_PS ON REL_PS.FROM_MID = T.MID AND REL_PS.REL_TYPE = 'topic_post'
                    LEFT JOIN BALI_POST PS ON PS.MID = REL_PS.TO_MID
                    
                    LEFT JOIN BALI_MASTER_REL REL_USER ON REL_USER.FROM_MID = T.MID AND REL_USER.REL_TYPE = 'topic_users'
                    LEFT JOIN BALI_USER U ON U.MID = REL_USER.TO_MID
                    
                    LEFT JOIN BALI_PROJECT_DIRECTORIES_FILES DF ON DF.ID_FILE = T.MID
                    LEFT JOIN BALI_PROJECT_DIRECTORIES DS ON DF.ID_DIRECTORY = DS.ID
            WHERE T.ACTIVE = 1
});

__PACKAGE__->add_columns(
    qw(
        topic_mid 
        mid
        title
        created_on
        created_by
        modified_on
        modified_by
        description
        status
        numcomment
        category_id
        category_name
        category_status_id
        category_status_name        
        category_status_seq
        category_status_type
        priority_id
        priority_name
        response_time_min
        expr_response_time
        deadline_min
        expr_deadline
        category_color
        is_changeset
        is_release
        file_name
        text
        progress
        num_file
        assignee
        moniker
        directory
    )
);

__PACKAGE__->set_primary_key( 'topic_mid' );

1;
