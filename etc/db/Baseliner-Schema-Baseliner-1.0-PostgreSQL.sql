-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed Mar 16 14:34:35 2011
-- 
--
-- Table: bali_baseline
--
DROP TABLE "bali_baseline" CASCADE;
CREATE TABLE "bali_baseline" (
  "id" bigint NOT NULL,
  "bl" character varying(100) NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" character varying(1024),
  PRIMARY KEY ("id")
);

--
-- Table: bali_calendar
--
DROP TABLE "bali_calendar" CASCADE;
CREATE TABLE "bali_calendar" (
  "id" bigint NOT NULL,
  "name" character varying(100) NOT NULL,
  "ns" character varying(100) DEFAULT ''/'                   ' NOT NULL,
  "bl" character varying(100) DEFAULT ''*'                   ' NOT NULL,
  "description" character varying(1024),
  "type" character varying(2) DEFAULT 'HI',
  PRIMARY KEY ("id")
);

--
-- Table: bali_chain
--
DROP TABLE "bali_chain" CASCADE;
CREATE TABLE "bali_chain" (
  "id" bigint NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" character varying(2000) NOT NULL,
  "job_type" character varying(50),
  "active" bigint DEFAULT 1,
  "action" character varying(255),
  "ns" character varying(1024) DEFAULT ''/'',
  "bl" character varying(50) DEFAULT ''*'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_chained_service
--
DROP TABLE "bali_chained_service" CASCADE;
CREATE TABLE "bali_chained_service" (
  "id" bigint NOT NULL,
  "chain_id" bigint NOT NULL,
  "seq" bigint NOT NULL,
  "key" character varying(255) NOT NULL,
  "description" character varying(2000),
  "step" character varying(50) DEFAULT ''RUN'',
  "active" bigint DEFAULT 1,
  PRIMARY KEY ("id")
);

--
-- Table: bali_config
--
DROP TABLE "bali_config" CASCADE;
CREATE TABLE "bali_config" (
  "id" bigint NOT NULL,
  "ns" character varying(1000) DEFAULT ''/'                   ' NOT NULL,
  "bl" character varying(100) DEFAULT ''*'                   ' NOT NULL,
  "key" character varying(100) NOT NULL,
  "value" character varying(1024) DEFAULT NULL,
  "ts" date DEFAULT 'SYSDATE               ' NOT NULL,
  "ref" bigint,
  "reftable" character varying(100),
  "data" bytea,
  "parent_id" bigint DEFAULT 0                      NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_config_rel
--
DROP TABLE "bali_config_rel" CASCADE;
CREATE TABLE "bali_config_rel" (
  "id" integer NOT NULL,
  "namespace_id" integer NOT NULL,
  "plugin_id" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_configset
--
DROP TABLE "bali_configset" CASCADE;
CREATE TABLE "bali_configset" (
  "id" integer NOT NULL,
  "namespace_id" integer NOT NULL,
  "baseline_id" integer NOT NULL,
  "wiki_id" integer NOT NULL,
  "created_on" timestamp(6) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_daemon
--
DROP TABLE "bali_daemon" CASCADE;
CREATE TABLE "bali_daemon" (
  "id" bigint NOT NULL,
  "service" character varying(255),
  "active" bigint DEFAULT 1,
  "config" character varying(255),
  "pid" bigint,
  "params" character varying(1024),
  "hostname" character varying(255) DEFAULT ''localhost'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_message
--
DROP TABLE "bali_message" CASCADE;
CREATE TABLE "bali_message" (
  "id" bigint NOT NULL,
  "subject" character varying(1024) NOT NULL,
  "body" clob,
  "created" date DEFAULT 'SYSDATE',
  "active" bigint DEFAULT 1,
  "attach" bytea,
  "sender" character varying(255),
  "content_type" character varying(50),
  "attach_content_type" character varying(50),
  "attach_filename" character varying(255),
  PRIMARY KEY ("id")
);

--
-- Table: bali_namespace
--
DROP TABLE "bali_namespace" CASCADE;
CREATE TABLE "bali_namespace" (
  "id" bigint NOT NULL,
  "ns" character varying(100) NOT NULL,
  "provider" character varying(500),
  PRIMARY KEY ("id")
);

--
-- Table: bali_plugin
--
DROP TABLE "bali_plugin" CASCADE;
CREATE TABLE "bali_plugin" (
  "id" integer NOT NULL,
  "plugin" character varying(250) NOT NULL,
  "desc" character varying(500) NOT NULL,
  "wiki_id" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_project
--
DROP TABLE "bali_project" CASCADE;
CREATE TABLE "bali_project" (
  "id" serial NOT NULL,
  "name" character varying(1024) NOT NULL,
  "data" clob,
  "ns" character varying(1024) DEFAULT '/',
  "bl" character varying(1024) DEFAULT '*',
  "ts" timestamp DEFAULT current_timestamp,
  "domain" character varying(1),
  "description" clob,
  "id_parent" numeric(126),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_project_idx_id_parent" on "bali_project" ("id_parent");

--
-- Table: bali_provider
--
DROP TABLE "bali_provider" CASCADE;
CREATE TABLE "bali_provider" (
  "id" integer NOT NULL,
  "plugin" character varying(250) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_relationship
--
DROP TABLE "bali_relationship" CASCADE;
CREATE TABLE "bali_relationship" (
  "from_id" bigint NOT NULL,
  "to_id" bigint NOT NULL,
  "type" character varying(45),
  PRIMARY KEY ("to_id", "from_id")
);

--
-- Table: bali_release
--
DROP TABLE "bali_release" CASCADE;
CREATE TABLE "bali_release" (
  "id" bigint NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" character varying(2000),
  "active" character(1) DEFAULT '1 ' NOT NULL,
  "ts" date DEFAULT 'SYSDATE',
  "bl" character varying(100) DEFAULT ''*' ' NOT NULL,
  "username" character varying(255),
  "ns" character varying(1024) DEFAULT ''/'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_repo
--
DROP TABLE "bali_repo" CASCADE;
CREATE TABLE "bali_repo" (
  "ns" character varying(1024) NOT NULL,
  "backend" character varying(1024) DEFAULT ''default'',
  "ts" date DEFAULT 'SYSDATE',
  "bl" character varying(255) DEFAULT ''*'',
  "provider" character varying(1024) NOT NULL,
  "item" character varying(1024) NOT NULL,
  "class" character varying(1024) NOT NULL,
  "data" clob,
  PRIMARY KEY ("ns")
);

--
-- Table: bali_request
--
DROP TABLE "bali_request" CASCADE;
CREATE TABLE "bali_request" (
  "id" bigserial NOT NULL,
  "ns" character varying(1024) NOT NULL,
  "bl" character varying(50) DEFAULT '*',
  "requested_on" date,
  "finished_on" date,
  "status" character varying(50) DEFAULT 'pending',
  "finished_by" character varying(255),
  "requested_by" character varying(255),
  "action" character varying(255),
  "id_parent" bigint,
  "key" character varying(255),
  "name" character varying(255),
  "type" character varying(100) DEFAULT 'approval',
  "id_wiki" bigint,
  "id_job" bigint,
  "data" clob,
  "callback" character varying(1024),
  "id_message" bigint,
  PRIMARY KEY ("id")
);

--
-- Table: bali_role
--
DROP TABLE "bali_role" CASCADE;
CREATE TABLE "bali_role" (
  "id" bigserial NOT NULL,
  "role" character varying(255) NOT NULL,
  "description" character varying(2048),
  "mailbox" character varying(255),
  PRIMARY KEY ("id")
);

--
-- Table: bali_sem
--
DROP TABLE "bali_sem" CASCADE;
CREATE TABLE "bali_sem" (
  "name" character varying(255) NOT NULL,
  "description" clob,
  "active" bigint DEFAULT 1,
  "type" character varying(50) DEFAULT ''global'
',
  PRIMARY KEY ("name")
);

--
-- Table: bali_service
--
DROP TABLE "bali_service" CASCADE;
CREATE TABLE "bali_service" (
  "id" integer NOT NULL,
  "name" character varying(100) NOT NULL,
  "desc" character varying(100) NOT NULL,
  "wiki_id" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_session
--
DROP TABLE "bali_session" CASCADE;
CREATE TABLE "bali_session" (
  "id" character varying(72) NOT NULL,
  "session_data" clob,
  "expires" bigint,
  PRIMARY KEY ("id")
);

--
-- Table: bali_user
--
DROP TABLE "bali_user" CASCADE;
CREATE TABLE "bali_user" (
  "id" bigserial NOT NULL,
  "username" character varying(45) NOT NULL,
  "password" character varying(45) NOT NULL,
  "realname" character varying(4000),
  "avatar" bytea,
  "alias" character varying(512),
  PRIMARY KEY ("id")
);

--
-- Table: bali_wiki
--
DROP TABLE "bali_wiki" CASCADE;
CREATE TABLE "bali_wiki" (
  "id" bigint NOT NULL,
  "text" clob,
  "username" character varying(255),
  "modified_on" date DEFAULT 'SYSDATE',
  "content_type" character varying(255) DEFAULT ''text/plain'
',
  "id_wiki" bigint,
  PRIMARY KEY ("id")
);

--
-- Table: bali_calendar_window
--
DROP TABLE "bali_calendar_window" CASCADE;
CREATE TABLE "bali_calendar_window" (
  "id" bigint DEFAULT 1                      NOT NULL,
  "start_time" character varying(20),
  "end_time" character varying(20),
  "day" character varying(20),
  "type" character varying(1),
  "active" character varying(1) DEFAULT ''1'',
  "id_cal" bigint DEFAULT 1                      NOT NULL,
  "start_date" date,
  "end_date" date,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_calendar_window_idx_id_cal" on "bali_calendar_window" ("id_cal");

--
-- Table: bali_job
--
DROP TABLE "bali_job" CASCADE;
CREATE TABLE "bali_job" (
  "id" bigserial NOT NULL,
  "name" character varying(45),
  "starttime" date DEFAULT SYSDATE NOT NULL,
  "maxstarttime" date DEFAULT SYSDATE+1 NOT NULL,
  "endtime" date,
  "status" character varying(45) DEFAULT 'READY' NOT NULL,
  "ns" character varying(45) DEFAULT '/' NOT NULL,
  "bl" character varying(45) DEFAULT '*' NOT NULL,
  "runner" character varying(255),
  "pid" bigint,
  "comments" character varying(1024),
  "type" character varying(100),
  "username" character varying(255),
  "ts" date DEFAULT SYSDATE,
  "host" character varying(255) DEFAULT 'localhost',
  "owner" character varying(255),
  "step" character varying(50) DEFAULT 'PRE',
  "id_stash" bigint,
  "rollback" bigint DEFAULT 0,
  "now" bigint DEFAULT 0,
  "schedtime" date DEFAULT sysdate,
  "exec" bigint DEFAULT 1,
  "request_status" character varying(50),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_job_idx_id_stash" on "bali_job" ("id_stash");

--
-- Table: bali_job_stash
--
DROP TABLE "bali_job_stash" CASCADE;
CREATE TABLE "bali_job_stash" (
  "id" bigserial NOT NULL,
  "stash" bytea,
  "id_job" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_job_stash_idx_id_job" on "bali_job_stash" ("id_job");

--
-- Table: bali_message_queue
--
DROP TABLE "bali_message_queue" CASCADE;
CREATE TABLE "bali_message_queue" (
  "id" bigint NOT NULL,
  "id_message" bigint,
  "username" character varying(255),
  "destination" character varying(50),
  "sent" date DEFAULT 'SYSDATE',
  "received" date,
  "active" bigint DEFAULT 1,
  "carrier" character varying(50) DEFAULT ''instant'',
  "carrier_param" character varying(50),
  "result" clob,
  "attempts" bigint DEFAULT 0,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_message_queue_idx_id_message" on "bali_message_queue" ("id_message");

--
-- Table: bali_project_items
--
DROP TABLE "bali_project_items" CASCADE;
CREATE TABLE "bali_project_items" (
  "id" bigserial NOT NULL,
  "id_project" bigint NOT NULL,
  "ns" character varying(1024),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_project_items_idx_id_project" on "bali_project_items" ("id_project");

--
-- Table: bali_release_items
--
DROP TABLE "bali_release_items" CASCADE;
CREATE TABLE "bali_release_items" (
  "id" bigint NOT NULL,
  "id_rel" bigint NOT NULL,
  "item" character varying(1024),
  "provider" character varying(1024),
  "data" clob,
  "ns" character varying(255),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_release_items_idx_id_rel" on "bali_release_items" ("id_rel");

--
-- Table: bali_roleaction
--
DROP TABLE "bali_roleaction" CASCADE;
CREATE TABLE "bali_roleaction" (
  "id_role" bigint NOT NULL,
  "action" character varying(255) NOT NULL,
  "bl" character varying(50) DEFAULT '*' NOT NULL,
  PRIMARY KEY ("action", "id_role", "bl")
);
CREATE INDEX "bali_roleaction_idx_id_role" on "bali_roleaction" ("id_role");

--
-- Table: bali_sem_queue
--
DROP TABLE "bali_sem_queue" CASCADE;
CREATE TABLE "bali_sem_queue" (
  "id" bigint NOT NULL,
  "who" character varying(1024),
  "host" character varying(255) DEFAULT ''localhost'',
  "pid" bigint,
  "active" bigint DEFAULT 1,
  "place" bigint,
  "now" bigint DEFAULT 0
,
  "ts_request" date DEFAULT 'sysdate',
  "ts_grant" date,
  "ts_release" date,
  "bl" character varying(50) DEFAULT ''*'',
  "caller" character varying(1024),
  "sem_name" character varying(255) NOT NULL,
  "wait_until" date,
  "status" character varying(50) DEFAULT ''idle'',
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_sem_queue_idx_sem_name" on "bali_sem_queue" ("sem_name");

--
-- Table: bali_sqa
--
DROP TABLE "bali_sqa" CASCADE;
CREATE TABLE "bali_sqa" (
  "id" serial NOT NULL,
  "ns" character varying(1024),
  "bl" character varying(1024),
  "id_prj" numeric(126),
  "nature" character varying(1024),
  "qualification" character varying(1024),
  "status" character varying(1024),
  "data" clob,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_sqa_idx_id_prj" on "bali_sqa" ("id_prj");

--
-- Table: bali_job_items
--
DROP TABLE "bali_job_items" CASCADE;
CREATE TABLE "bali_job_items" (
  "id" bigserial NOT NULL,
  "data" clob,
  "item" character varying(1024),
  "provider" character varying(1024),
  "id_job" bigint NOT NULL,
  "service" character varying(255),
  "application" character varying(1024),
  "rfc" character varying(1024),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_job_items_idx_id_job" on "bali_job_items" ("id_job");

--
-- Table: bali_log
--
DROP TABLE "bali_log" CASCADE;
CREATE TABLE "bali_log" (
  "id" bigserial NOT NULL,
  "text" character varying(2048),
  "lev" character varying(10),
  "id_job" bigint NOT NULL,
  "more" character varying(10),
  "timestamp" date DEFAULT SYSDATE,
  "ns" character varying(255) DEFAULT '/',
  "provider" character varying(255),
  "data" bytea,
  "data_name" character varying(1024),
  "data_length" bigint DEFAULT 0,
  "module" character varying(1024),
  "section" character varying(255) DEFAULT 'general',
  "step" character varying(50),
  "exec" bigint DEFAULT 1,
  "prefix" character varying(1024),
  "milestone" character varying(1024),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_log_idx_id_job" on "bali_log" ("id_job");
CREATE INDEX "bali_log_idx_id_job_exec" on "bali_log" ("id_job", "exec");

--
-- Table: bali_roleuser
--
DROP TABLE "bali_roleuser" CASCADE;
CREATE TABLE "bali_roleuser" (
  "username" character varying(255) NOT NULL,
  "id_role" bigint NOT NULL,
  "ns" character varying(100) DEFAULT '/' NOT NULL,
  PRIMARY KEY ("ns", "id_role", "username")
);
CREATE INDEX "bali_roleuser_idx_username" on "bali_roleuser" ("username");
CREATE INDEX "bali_roleuser_idx_id_role" on "bali_roleuser" ("id_role");

--
-- Table: bali_log_data
--
DROP TABLE "bali_log_data" CASCADE;
CREATE TABLE "bali_log_data" (
  "id" bigserial NOT NULL,
  "id_log" bigint NOT NULL,
  "data" bytea,
  "timestamp" date DEFAULT SYSDATE,
  "name" character varying(2048),
  "type" character varying(255),
  "len" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_log_data_idx_id_log" on "bali_log_data" ("id_log");

--
-- Foreign Key Definitions
--

ALTER TABLE "bali_project" ADD FOREIGN KEY ("id_parent")
  REFERENCES "bali_project" ("id") DEFERRABLE;

ALTER TABLE "bali_calendar_window" ADD FOREIGN KEY ("id_cal")
  REFERENCES "bali_calendar" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_job" ADD FOREIGN KEY ("id_stash")
  REFERENCES "bali_job_stash" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_job_stash" ADD FOREIGN KEY ("id_job")
  REFERENCES "bali_job" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_message_queue" ADD FOREIGN KEY ("id_message")
  REFERENCES "bali_message" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_project_items" ADD FOREIGN KEY ("id_project")
  REFERENCES "bali_project" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_release_items" ADD FOREIGN KEY ("id_rel")
  REFERENCES "bali_release" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_roleaction" ADD FOREIGN KEY ("id_role")
  REFERENCES "bali_role" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_sem_queue" ADD FOREIGN KEY ("sem_name")
  REFERENCES "bali_sem" ("name") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_sqa" ADD FOREIGN KEY ("id_prj")
  REFERENCES "bali_project" ("id") DEFERRABLE;

ALTER TABLE "bali_job_items" ADD FOREIGN KEY ("id_job")
  REFERENCES "bali_job" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_log" ADD FOREIGN KEY ("id_job")
  REFERENCES "bali_job" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_log" ADD FOREIGN KEY ("id_job", "exec")
  REFERENCES "bali_job" ("id", "exec") DEFERRABLE;

ALTER TABLE "bali_roleuser" ADD FOREIGN KEY ("username")
  REFERENCES "bali_user" ("username") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_roleuser" ADD FOREIGN KEY ("id_role")
  REFERENCES "bali_role" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_log_data" ADD FOREIGN KEY ("id_log")
  REFERENCES "bali_log" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

