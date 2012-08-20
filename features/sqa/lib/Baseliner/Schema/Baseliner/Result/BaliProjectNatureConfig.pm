package Baseliner::Schema::Baseliner::Result::BaliProjectNatureConfig;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("BaliProjectNatureConfig");

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q{
SELECT t.ID AS id, t.NAME AS project_name, t.NATURE AS nature, NULL AS sp_name, 'CAM' as tree_level, RUN_SQA_TEST, RUN_SQA_ANTE, RUN_SQA_PROD, BLOCK_DEPLOYMENT_TEST, BLOCK_DEPLOYMENT_ANTE, BLOCK_DEPLOYMENT_PROD
FROM 
(SELECT p.NAME, p.ID, p.ID_PARENT, c.nature , MAX(CASE WHEN c.BL = 'TEST' AND c.KEY = 'config.sqa.run_sqa' THEN c.VALUE ELSE NULL END) as RUN_SQA_TEST
                    , MAX(CASE WHEN c.BL = 'ANTE' AND c.KEY = 'config.sqa.run_sqa' THEN c.VALUE ELSE NULL END) as RUN_SQA_ANTE
                    , MAX(CASE WHEN c.BL = 'PROD' AND c.KEY = 'config.sqa.run_sqa' THEN c.VALUE ELSE NULL END) as RUN_SQA_PROD
                    , MAX(CASE WHEN c.BL = 'TEST' AND c.KEY = 'config.sqa.block_deployment' THEN c.VALUE ELSE NULL END) as BLOCK_DEPLOYMENT_TEST
                    , MAX(CASE WHEN c.BL = 'ANTE' AND c.KEY = 'config.sqa.block_deployment' THEN c.VALUE ELSE NULL END) as BLOCK_DEPLOYMENT_ANTE
                    , MAX(CASE WHEN c.BL = 'PROD' AND c.KEY = 'config.sqa.block_deployment' THEN c.VALUE ELSE NULL END) as BLOCK_DEPLOYMENT_PROD
FROM BALI_PROJECT p , 
     (SELECT ns, bl, key, value, substr(ns, instr(ns, '/', 1, 1) + 1, instr(ns, '/', 1, 2) - instr(ns, '/', 1, 1) - 1 ) as nature, substr(ns, instr(ns, '/', 1, 2) + 1) as id FROM BALI_CONFIG WHERE NS LIKE 'nature/%/%') c
WHERE p.ID = c.ID
GROUP BY p.NAME, p.ID, c.nature, p.ID_PARENT
HAVING p.ID_PARENT IS NULL) c,

(SELECT p.NAME, p.ID, n.NATURE
FROM BALI_PROJECT p,
    (SELECT 'J2EE' AS NATURE FROM DUAL
    UNION 
    SELECT '.NET' AS NATURE FROM DUAL
    UNION  
    SELECT 'ORACLE' AS NATURE FROM DUAL
    UNION 
    SELECT 'FICHEROS' AS NATURE FROM DUAL
    UNION 
    SELECT 'BIZTALK' AS NATURE FROM DUAL
    UNION 
    SELECT 'ECLIPSE' AS NATURE FROM DUAL
    ) n
WHERE p.ID_PARENT IS NULL) t 

WHERE c.ID(+) = t.ID AND
      c.NATURE(+) = t.NATURE
ORDER BY 1, 3
});

__PACKAGE__->add_columns(
	'id','project_name', 'nature', 'sp_name', 'run_sqa_test', 'run_sqa_ante', 'run_sqa_prod', 'block_deployment_test', 'block_deployment_ante', 'block_deployment_prod'
);

1;