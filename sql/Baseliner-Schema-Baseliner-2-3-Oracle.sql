-- Convert schema 'sql/Baseliner-Schema-Baseliner-2-Oracle.sql' to 'sql/Baseliner-Schema-Baseliner-3-Oracle.sql':;

-- Output database Oracle is untested/unsupported!!!;

BEGIN;

ALTER TABLE bali_plugin DROP COLUMN "desc";

ALTER TABLE bali_service DROP COLUMN "desc";

ALTER TABLE bali_plugin ADD ( description varchar2(500) NOT NULL );

ALTER TABLE bali_service ADD ( description varchar2(100) NOT NULL );


COMMIT;

