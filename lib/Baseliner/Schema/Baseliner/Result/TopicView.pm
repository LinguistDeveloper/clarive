package Baseliner::Schema::Baseliner::Result::TopicView;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("TopicView");

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q{
SELECT t.MID AS MID, t.ID AS ID, TITLE,
CREATED_ON, CREATED_BY, STATUS, S.NAME AS STATUS_NAME, NUMCOMMENT, F.NAME AS NAMECATEGORY, F.ID AS CATEGORY, L.NAME AS LABEL,
ID_CATEGORY_STATUS, ID_PRIORITY, RESPONSE_TIME_MIN, EXPR_RESPONSE_TIME, DEADLINE_MIN, EXPR_DEADLINE, F.COLOR CATEGORY_COLOR
FROM  BALI_TOPIC t
    LEFT JOIN BALI_TOPIC_CATEGORIES F ON ID_CATEGORY = F.ID
    LEFT JOIN BALI_TOPIC_LABEL TL ON TL.ID_TOPIC = t.ID
    LEFT JOIN BALI_LABEL L ON L.ID = TL.ID_LABEL
    LEFT JOIN (SELECT COUNT(*) AS NUMCOMMENT, A.MID 
                                FROM BALI_TOPIC A, BALI_MASTER_REL REL, BALI_POST B
                                WHERE A.MID = REL.FROM_MID
                                AND REL.TO_MID = B.MID
                                AND REL.REL_TYPE = 'topic_post'
                                GROUP BY A.MID) D
                      ON t.MID = D.MID
    LEFT JOIN BALI_TOPIC_STATUS S ON ID_CATEGORY_STATUS = S.ID
});

__PACKAGE__->add_columns(
	qw(
        mid 
        id
        title
        created_on
        created_by
        status
        status_name
        numcomment
        namecategory
        category
        id_category_status
        id_priority
        response_time_min
        expr_response_time
        deadline_min
        expr_deadline
        category_color
     )
);

1;

