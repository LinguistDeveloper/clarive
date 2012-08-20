-- 
-- Created by SQL::Translator::Producer::Oracle
-- Created on Wed Nov 10 14:33:12 2010
-- 
--
-- Table: bali_baseline
--;

DROP TABLE "bali_baseline" CASCADE CONSTRAINTS;

CREATE TABLE "bali_baseline" (
  "id" number(38) NOT NULL,
  "bl" varchar2(100) NOT NULL,
  "name" varchar2(255) NOT NULL,
  "description" varchar2(1024),
  PRIMARY KEY ("id")
);

--
-- Table: bali_calendar
--;

DROP TABLE "bali_calendar" CASCADE CONSTRAINTS;

CREATE TABLE "bali_calendar" (
  "id" number(38) NOT NULL,
  "name" varchar2(100) NOT NULL,
  "ns" varchar2(100) DEFAULT ''/'                   ' NOT NULL,
  "bl" varchar2(100) DEFAULT ''*'                   ' NOT NULL,
  "description" varchar2(1024),
  "type" varchar2(2) DEFAULT 'HI',
  PRIMARY KEY ("id")
);

--
-- Table: bali_chain
--;

DROP TABLE "bali_chain" CASCADE CONSTRAINTS;

CREATE TABLE "bali_chain" (
  "id" number(38) NOT NULL,
  "name" varchar2(255) NOT NULL,
  "description" varchar2(2000) NOT NULL,
  "job_type" varchar2(50),
  "active" number(38) DEFAULT '1',
  "action" varchar2(255),
  "ns" varchar2(1024) DEFAULT ''/'',
  "bl" varchar2(50) DEFAULT ''*'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_chained_service
--;

DROP TABLE "bali_chained_service" CASCADE CONSTRAINTS;

CREATE TABLE "bali_chained_service" (
  "id" number(38) NOT NULL,
  "chain_id" number(38) NOT NULL,
  "seq" number(38) NOT NULL,
  "key" varchar2(255) NOT NULL,
  "description" varchar2(2000),
  "step" varchar2(50) DEFAULT ''RUN'',
  "active" number(38) DEFAULT '1',
  PRIMARY KEY ("id")
);

--
-- Table: bali_config
--;

DROP TABLE "bali_config" CASCADE CONSTRAINTS;

CREATE TABLE "bali_config" (
  "id" number(38) NOT NULL,
  "ns" varchar2(1000) DEFAULT ''/'                   ' NOT NULL,
  "bl" varchar2(100) DEFAULT ''*'                   ' NOT NULL,
  "key" varchar2(100) NOT NULL,
  "value" varchar2(1024) DEFAULT NULL,
  "ts" date DEFAULT 'SYSDATE               ' NOT NULL,
  "ref" number(38),
  "reftable" varchar2(100),
  "data" blob(2147483647),
  "parent_id" number(38) DEFAULT '1' NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_config_rel
--;

DROP TABLE "bali_config_rel" CASCADE CONSTRAINTS;

CREATE TABLE "bali_config_rel" (
  "id" number NOT NULL,
  "namespace_id" number(10) NOT NULL,
  "plugin_id" number(10) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_configset
--;

DROP TABLE "bali_configset" CASCADE CONSTRAINTS;

CREATE TABLE "bali_configset" (
  "id" number NOT NULL,
  "namespace_id" number(10) NOT NULL,
  "baseline_id" number(10) NOT NULL,
  "wiki_id" number(10) NOT NULL,
  "created_on" date NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_daemon
--;

DROP TABLE "bali_daemon" CASCADE CONSTRAINTS;

CREATE TABLE "bali_daemon" (
  "id" number(38) NOT NULL,
  "service" varchar2(255),
  "active" number(38) DEFAULT '1',
  "config" varchar2(255),
  "pid" number(38),
  "params" varchar2(1024),
  "hostname" varchar2(255) DEFAULT ''localhost'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_message
--;

DROP TABLE "bali_message" CASCADE CONSTRAINTS;

CREATE TABLE "bali_message" (
  "id" number(38) NOT NULL,
  "subject" varchar2(1024) NOT NULL,
  "body" clob,
  "created" date DEFAULT 'SYSDATE',
  "active" number(38) DEFAULT '1',
  "attach" blob(2147483647),
  "sender" varchar2(255),
  "content_type" varchar2(50),
  "attach_content_type" varchar2(50),
  "attach_filename" varchar2(255),
  PRIMARY KEY ("id")
);

--
-- Table: bali_namespace
--;

DROP TABLE "bali_namespace" CASCADE CONSTRAINTS;

CREATE TABLE "bali_namespace" (
  "id" number(38) NOT NULL,
  "ns" varchar2(100) NOT NULL,
  "provider" varchar2(500),
  PRIMARY KEY ("id")
);

--
-- Table: bali_plugin
--;

DROP TABLE "bali_plugin" CASCADE CONSTRAINTS;

CREATE TABLE "bali_plugin" (
  "id" number NOT NULL,
  "plugin" varchar2(250) NOT NULL,
  "desc" varchar2(500) NOT NULL,
  "wiki_id" number(10) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_project
--;

DROP TABLE "bali_project" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_project_id";

CREATE SEQUENCE "sq_bali_project_id";

CREATE TABLE "bali_project" (
  "id" number(38) NOT NULL,
  "name" varchar2(1024) NOT NULL,
  "data" clob,
  "ns" varchar2(1024) DEFAULT '/',
  "bl" varchar2(1024) DEFAULT '*',
  "ts" date DEFAULT SYSDATE,
  "domain" varchar2(1),
  "description" clob,
  PRIMARY KEY ("id")
);

--
-- Table: bali_provider
--;

DROP TABLE "bali_provider" CASCADE CONSTRAINTS;

CREATE TABLE "bali_provider" (
  "id" number NOT NULL,
  "plugin" varchar2(250) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_relationship
--;

DROP TABLE "bali_relationship" CASCADE CONSTRAINTS;

CREATE TABLE "bali_relationship" (
  "from_id" number(38) NOT NULL,
  "to_id" number(38) NOT NULL,
  "type" varchar2(45),
  PRIMARY KEY ("to_id", "from_id")
);

--
-- Table: bali_release
--;

DROP TABLE "bali_release" CASCADE CONSTRAINTS;

CREATE TABLE "bali_release" (
  "id" number(38) NOT NULL,
  "name" varchar2(255) NOT NULL,
  "description" varchar2(2000),
  "active" char(1) DEFAULT '1 ' NOT NULL,
  "ts" date DEFAULT 'SYSDATE',
  "bl" varchar2(100) DEFAULT ''*' ' NOT NULL,
  "username" varchar2(255),
  "ns" varchar2(1024) DEFAULT ''/'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_repo
--;

DROP TABLE "bali_repo" CASCADE CONSTRAINTS;

CREATE TABLE "bali_repo" (
  "ns" varchar2(1024) NOT NULL,
  "backend" varchar2(1024) DEFAULT ''default'',
  "ts" date DEFAULT 'SYSDATE',
  "bl" varchar2(255) DEFAULT ''*'',
  "provider" varchar2(1024) NOT NULL,
  "item" varchar2(1024) NOT NULL,
  "class" varchar2(1024) NOT NULL,
  "data" clob,
  PRIMARY KEY ("ns")
);

--
-- Table: bali_request
--;

DROP TABLE "bali_request" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_request_id";

CREATE SEQUENCE "sq_bali_request_id";

CREATE TABLE "bali_request" (
  "id" number(38) NOT NULL,
  "ns" varchar2(1024) NOT NULL,
  "bl" varchar2(50) DEFAULT '*',
  "requested_on" date,
  "finished_on" date,
  "status" varchar2(50) DEFAULT 'pending',
  "finished_by" varchar2(255),
  "requested_by" varchar2(255),
  "action" varchar2(255),
  "id_parent" number(38),
  "key" varchar2(255),
  "name" varchar2(255),
  "type" varchar2(100) DEFAULT 'approval',
  "id_wiki" number(38),
  "id_job" number(38),
  "data" clob,
  "callback" varchar2(1024),
  "id_message" number(38),
  PRIMARY KEY ("id")
);

--
-- Table: bali_role
--;

DROP TABLE "bali_role" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_role_id";

CREATE SEQUENCE "sq_bali_role_id";

CREATE TABLE "bali_role" (
  "id" number(38) NOT NULL,
  "role" varchar2(255) NOT NULL,
  "description" varchar2(2048),
  "mailbox" varchar2(255),
  PRIMARY KEY ("id")
);

--
-- Table: bali_sem
--;

DROP TABLE "bali_sem" CASCADE CONSTRAINTS;

CREATE TABLE "bali_sem" (
  "name" varchar2(255) NOT NULL,
  "description" clob,
  "active" number(38) DEFAULT '1',
  "type" varchar2(50) DEFAULT ''global'
',
  PRIMARY KEY ("name")
);

--
-- Table: bali_service
--;

DROP TABLE "bali_service" CASCADE CONSTRAINTS;

CREATE TABLE "bali_service" (
  "id" number NOT NULL,
  "name" varchar2(100) NOT NULL,
  "desc" varchar2(100) NOT NULL,
  "wiki_id" number(10) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_session
--;

DROP TABLE "bali_session" CASCADE CONSTRAINTS;

CREATE TABLE "bali_session" (
  "id" varchar2(72) NOT NULL,
  "session_data" clob,
  "expires" number(38),
  PRIMARY KEY ("id")
);

--
-- Table: bali_user
--;

DROP TABLE "bali_user" CASCADE CONSTRAINTS;

CREATE TABLE "bali_user" (
  "id" number NOT NULL,
  "username" varchar2(45) NOT NULL,
  "password" varchar2(45) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_wiki
--;

DROP TABLE "bali_wiki" CASCADE CONSTRAINTS;

CREATE TABLE "bali_wiki" (
  "id" number(38) NOT NULL,
  "text" clob,
  "username" varchar2(255),
  "modified_on" date DEFAULT 'SYSDATE',
  "content_type" varchar2(255) DEFAULT ''text/plain'
',
  "id_wiki" number(38),
  PRIMARY KEY ("id")
);

--
-- Table: bali_calendar_window
--;

DROP TABLE "bali_calendar_window" CASCADE CONSTRAINTS;

CREATE TABLE "bali_calendar_window" (
  "id" number(38) DEFAULT '1' NOT NULL,
  "start_time" varchar2(20),
  "end_time" varchar2(20),
  "day" varchar2(20),
  "type" varchar2(1),
  "active" varchar2(1) DEFAULT ''1'',
  "id_cal" number(38) DEFAULT '1' NOT NULL,
  "start_date" date,
  "end_date" date,
  PRIMARY KEY ("id")
);

--
-- Table: bali_job
--;

DROP TABLE "bali_job" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_job_id";

CREATE SEQUENCE "sq_bali_job_id";

CREATE TABLE "bali_job" (
  "id" number(38) NOT NULL,
  "name" varchar2(45),
  "starttime" date DEFAULT SYSDATE NOT NULL,
  "maxstarttime" date DEFAULT SYSDATE+1 NOT NULL,
  "endtime" date,
  "status" varchar2(45) DEFAULT 'READY' NOT NULL,
  "ns" varchar2(45) DEFAULT '/' NOT NULL,
  "bl" varchar2(45) DEFAULT '*' NOT NULL,
  "runner" varchar2(255),
  "pid" number(38),
  "comments" varchar2(1024),
  "type" varchar2(100),
  "username" varchar2(255),
  "ts" date DEFAULT SYSDATE,
  "host" varchar2(255) DEFAULT 'localhost',
  "owner" varchar2(255),
  "step" varchar2(50) DEFAULT 'PRE',
  "id_stash" number(38),
  "rollback" number(38) DEFAULT '0',
  "now" number(38) DEFAULT '0',
  "schedtime" date DEFAULT sysdate,
  "exec" number(38) DEFAULT '1',
  "request_status" varchar2(50),
  PRIMARY KEY ("id")
);

--
-- Table: bali_job_stash
--;

DROP TABLE "bali_job_stash" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_job_stash_id";

CREATE SEQUENCE "sq_bali_job_stash_id";

CREATE TABLE "bali_job_stash" (
  "id" number(38) NOT NULL,
  "stash" blob(2147483647),
  "id_job" number(38),
  PRIMARY KEY ("id")
);

--
-- Table: bali_message_queue
--;

DROP TABLE "bali_message_queue" CASCADE CONSTRAINTS;

CREATE TABLE "bali_message_queue" (
  "id" number(38) NOT NULL,
  "id_message" number(38),
  "username" varchar2(255),
  "destination" varchar2(50),
  "sent" date DEFAULT 'SYSDATE',
  "received" date,
  "active" number(38) DEFAULT '1',
  "carrier" varchar2(50) DEFAULT ''instant'',
  "carrier_param" varchar2(50),
  "result" clob,
  "attempts" number(38) DEFAULT '0',
  PRIMARY KEY ("id")
);

--
-- Table: bali_project_items
--;

DROP TABLE "bali_project_items" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_project_items_id";

CREATE SEQUENCE "sq_bali_project_items_id";

CREATE TABLE "bali_project_items" (
  "id" number(38) NOT NULL,
  "id_project" number(38) NOT NULL,
  "ns" varchar2(1024),
  PRIMARY KEY ("id")
);

--
-- Table: bali_release_items
--;

DROP TABLE "bali_release_items" CASCADE CONSTRAINTS;

CREATE TABLE "bali_release_items" (
  "id" number(38) NOT NULL,
  "id_rel" number(38) NOT NULL,
  "item" varchar2(1024),
  "provider" varchar2(1024),
  "data" clob,
  "ns" varchar2(255),
  PRIMARY KEY ("id")
);

--
-- Table: bali_roleaction
--;

DROP TABLE "bali_roleaction" CASCADE CONSTRAINTS;

CREATE TABLE "bali_roleaction" (
  "id_role" number(38) NOT NULL,
  "action" varchar2(255) NOT NULL,
  "bl" varchar2(50) DEFAULT '*' NOT NULL,
  PRIMARY KEY ("action", "id_role", "bl")
);

--
-- Table: bali_roleuser
--;

DROP TABLE "bali_roleuser" CASCADE CONSTRAINTS;

CREATE TABLE "bali_roleuser" (
  "username" varchar2(255) NOT NULL,
  "id_role" number(38) NOT NULL,
  "ns" varchar2(100) DEFAULT '/' NOT NULL,
  PRIMARY KEY ("ns", "id_role", "username")
);

--
-- Table: bali_sem_queue
--;

DROP TABLE "bali_sem_queue" CASCADE CONSTRAINTS;

CREATE TABLE "bali_sem_queue" (
  "id" number(38) NOT NULL,
  "who" varchar2(1024),
  "host" varchar2(255) DEFAULT ''localhost'',
  "pid" number(38),
  "active" number(38) DEFAULT '1',
  "place" number(38),
  "now" number(38) DEFAULT '0
',
  "ts_request" date DEFAULT 'sysdate',
  "ts_grant" date,
  "ts_release" date,
  "bl" varchar2(50) DEFAULT ''*'',
  "caller" varchar2(1024),
  "sem_name" varchar2(255) NOT NULL,
  "wait_until" date,
  "status" varchar2(50) DEFAULT ''idle'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_job_items
--;

DROP TABLE "bali_job_items" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_job_items_id";

CREATE SEQUENCE "sq_bali_job_items_id";

CREATE TABLE "bali_job_items" (
  "id" number(38) NOT NULL,
  "data" clob,
  "item" varchar2(1024),
  "provider" varchar2(1024),
  "id_job" number(38) NOT NULL,
  "service" varchar2(255),
  "application" varchar2(1024),
  "rfc" varchar2(1024),
  PRIMARY KEY ("id")
);

--
-- Table: bali_log
--;

DROP TABLE "bali_log" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_log_id";

CREATE SEQUENCE "sq_bali_log_id";

CREATE TABLE "bali_log" (
  "id" number(38) NOT NULL,
  "text" varchar2(2048),
  "lev" varchar2(10),
  "id_job" number(38) NOT NULL,
  "more" varchar2(10),
  "timestamp" date DEFAULT SYSDATE,
  "ns" varchar2(255) DEFAULT '/',
  "provider" varchar2(255),
  "data" blob(2147483647),
  "data_name" varchar2(1024),
  "data_length" number(38) DEFAULT '0',
  "module" varchar2(1024),
  "section" varchar2(255) DEFAULT 'general',
  "step" varchar2(50),
  "exec" number(38) DEFAULT '1',
  "prefix" varchar2(1024),
  "milestone" varchar2(1024),
  PRIMARY KEY ("id")
);

--
-- Table: bali_log_data
--;

DROP TABLE "bali_log_data" CASCADE CONSTRAINTS;

DROP SEQUENCE "sq_bali_log_data_id";

CREATE SEQUENCE "sq_bali_log_data_id";

CREATE TABLE "bali_log_data" (
  "id" number(38) NOT NULL,
  "id_log" number(38) NOT NULL,
  "data" blob(2147483647),
  "timestamp" date DEFAULT SYSDATE,
  "name" varchar2(2048),
  "type" varchar2(255),
  "len" number(38),
  PRIMARY KEY ("id")
);

ALTER TABLE "bali_calendar_window" ADD CONSTRAINT "bali_calendar_window_id_cal_fk" FOREIGN KEY ("id_cal") REFERENCES "bali_calendar" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_job" ADD CONSTRAINT "bali_job_id_stash_fk" FOREIGN KEY ("id_stash") REFERENCES "bali_job_stash" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_job_stash" ADD CONSTRAINT "bali_job_stash_id_job_fk" FOREIGN KEY ("id_job") REFERENCES "bali_job" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_message_queue" ADD CONSTRAINT "bali_message_queue_id_message_" FOREIGN KEY ("id_message") REFERENCES "bali_message" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_project_items" ADD CONSTRAINT "bali_project_items_id_project_" FOREIGN KEY ("id_project") REFERENCES "bali_project" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_release_items" ADD CONSTRAINT "bali_release_items_id_rel_fk" FOREIGN KEY ("id_rel") REFERENCES "bali_release" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_roleaction" ADD CONSTRAINT "bali_roleaction_id_role_fk" FOREIGN KEY ("id_role") REFERENCES "bali_role" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_roleuser" ADD CONSTRAINT "bali_roleuser_id_role_fk" FOREIGN KEY ("id_role") REFERENCES "bali_role" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_sem_queue" ADD CONSTRAINT "bali_sem_queue_sem_name_fk" FOREIGN KEY ("sem_name") REFERENCES "bali_sem" ("name") ON DELETE CASCADE;

ALTER TABLE "bali_job_items" ADD CONSTRAINT "bali_job_items_id_job_fk" FOREIGN KEY ("id_job") REFERENCES "bali_job" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_log" ADD CONSTRAINT "bali_log_id_job_fk" FOREIGN KEY ("id_job") REFERENCES "bali_job" ("id") ON DELETE CASCADE;

ALTER TABLE "bali_log" ADD CONSTRAINT "bali_log_id_job_exec_fk" FOREIGN KEY ("id_job", "exec") REFERENCES "bali_job" ("id");

ALTER TABLE "bali_log_data" ADD CONSTRAINT "bali_log_data_id_log_fk" FOREIGN KEY ("id_log") REFERENCES "bali_log" ("id") ON DELETE CASCADE;

CREATE INDEX "bali_calendar_window_idx_id_ca" on "bali_calendar_window" ("id_cal");

CREATE INDEX "bali_job_idx_id_stash" on "bali_job" ("id_stash");

CREATE INDEX "bali_job_stash_idx_id_job" on "bali_job_stash" ("id_job");

CREATE INDEX "bali_message_queue_idx_id_mess" on "bali_message_queue" ("id_message");

CREATE INDEX "bali_project_items_idx_id_proj" on "bali_project_items" ("id_project");

CREATE INDEX "bali_release_items_idx_id_rel" on "bali_release_items" ("id_rel");

CREATE INDEX "bali_roleaction_idx_id_role" on "bali_roleaction" ("id_role");

CREATE INDEX "bali_roleuser_idx_id_role" on "bali_roleuser" ("id_role");

CREATE INDEX "bali_sem_queue_idx_sem_name" on "bali_sem_queue" ("sem_name");

CREATE INDEX "bali_job_items_idx_id_job" on "bali_job_items" ("id_job");

CREATE INDEX "bali_log_idx_id_job" on "bali_log" ("id_job");

CREATE INDEX "bali_log_idx_id_job_exec" on "bali_log" ("id_job", "exec");

CREATE INDEX "bali_log_data_idx_id_log" on "bali_log_data" ("id_log");

CREATE OR REPLACE TRIGGER "ai_bali_project_id"
BEFORE INSERT ON "bali_project"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_project_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

CREATE OR REPLACE TRIGGER "ai_bali_request_id"
BEFORE INSERT ON "bali_request"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_request_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

CREATE OR REPLACE TRIGGER "ai_bali_role_id"
BEFORE INSERT ON "bali_role"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_role_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

CREATE OR REPLACE TRIGGER "ai_bali_job_id"
BEFORE INSERT ON "bali_job"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_job_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

CREATE OR REPLACE TRIGGER "ai_bali_job_stash_id"
BEFORE INSERT ON "bali_job_stash"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_job_stash_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

CREATE OR REPLACE TRIGGER "ai_bali_project_items_id"
BEFORE INSERT ON "bali_project_items"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_project_items_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

CREATE OR REPLACE TRIGGER "ai_bali_job_items_id"
BEFORE INSERT ON "bali_job_items"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_job_items_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

CREATE OR REPLACE TRIGGER "ai_bali_log_id"
BEFORE INSERT ON "bali_log"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_log_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

CREATE OR REPLACE TRIGGER "ai_bali_log_data_id"
BEFORE INSERT ON "bali_log_data"
FOR EACH ROW WHEN (
 new."id" IS NULL OR new."id" = 0
)
BEGIN
 SELECT "sq_bali_log_data_id".nextval
 INTO :new."id"
 FROM dual;
END;
/

