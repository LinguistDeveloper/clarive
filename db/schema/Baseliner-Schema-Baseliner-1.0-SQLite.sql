-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Aug 17 20:27:55 2011
-- 

BEGIN TRANSACTION;

--
-- Table: bali_baseline
--
DROP TABLE bali_baseline;

CREATE TABLE bali_baseline (
  id INTEGER PRIMARY KEY NOT NULL,
  bl VARCHAR2(100) NOT NULL,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(1024)
);

--
-- Table: bali_calendar
--
DROP TABLE bali_calendar;

CREATE TABLE bali_calendar (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR2(100) NOT NULL,
  ns VARCHAR2(100) NOT NULL DEFAULT '/',
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  description VARCHAR2(1024),
  type VARCHAR2(2) DEFAULT 'HI',
);

--
-- Table: bali_chain
--
DROP TABLE bali_chain;

CREATE TABLE bali_chain (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(2000) NOT NULL,
  job_type VARCHAR2(50),
  active NUMBER(126) DEFAULT 1,
  action VARCHAR2(255),
  ns VARCHAR2(1024) DEFAULT '/',
  bl VARCHAR2(50) DEFAULT '*',
);

--
-- Table: bali_chained_rule
--
DROP TABLE bali_chained_rule;

CREATE TABLE bali_chained_rule (
  id INTEGER PRIMARY KEY NOT NULL,
  chain_id integer NOT NULL,
  seq integer NOT NULL DEFAULT 1,
  name varchar2(30) NOT NULL,
  description varchar2(500),
  step varchar2(10) NOT NULL,
  dsl varchar2(20),
  dsl_code clob NOT NULL,
  active char(1) NOT NULL DEFAULT NULL,
);

--
-- Table: bali_chained_service
--
DROP TABLE bali_chained_service;

CREATE TABLE bali_chained_service (
  id INTEGER PRIMARY KEY NOT NULL,
  chain_id NUMBER(126) NOT NULL,
  seq NUMBER(126) NOT NULL,
  key VARCHAR2(255) NOT NULL,
  description VARCHAR2(2000),
  step VARCHAR2(50) DEFAULT 'RUN',
  active NUMBER(126) DEFAULT 1,
);

--
-- Table: bali_config
--
DROP TABLE bali_config;

CREATE TABLE bali_config (
  id INTEGER PRIMARY KEY NOT NULL,
  ns VARCHAR2(1000) NOT NULL DEFAULT '/',
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  key VARCHAR2(100) NOT NULL,
  value VARCHAR2(1024) DEFAULT NULL,
  ts DATE(19) NOT NULL DEFAULT SYSDATE,
  ref NUMBER(126),
  reftable VARCHAR2(100),
  data BLOB,
  parent_id NUMBER(126) NOT NULL DEFAULT 0                     ,
);

--
-- Table: bali_config_rel
--
DROP TABLE bali_config_rel;

CREATE TABLE bali_config_rel (
  id INTEGER PRIMARY KEY NOT NULL,
  namespace_id INT(10) NOT NULL,
  plugin_id INT(10) NOT NULL
);

--
-- Table: bali_configset
--
DROP TABLE bali_configset;

CREATE TABLE bali_configset (
  id INTEGER PRIMARY KEY NOT NULL,
  namespace_id INT(10) NOT NULL,
  baseline_id INT(10) NOT NULL,
  wiki_id INT(10) NOT NULL,
  created_on DATETIME(19) NOT NULL
);

--
-- Table: bali_daemon
--
DROP TABLE bali_daemon;

CREATE TABLE bali_daemon (
  id INTEGER PRIMARY KEY NOT NULL,
  service VARCHAR2(255),
  active NUMBER(126) DEFAULT 1,
  config VARCHAR2(255),
  pid NUMBER(126),
  params VARCHAR2(1024),
  hostname VARCHAR2(255) DEFAULT 'localhost',
);

--
-- Table: bali_message
--
DROP TABLE bali_message;

CREATE TABLE bali_message (
  id INTEGER PRIMARY KEY NOT NULL,
  subject VARCHAR2(1024) NOT NULL,
  body CLOB(2147483647),
  created DATE(19) DEFAULT SYSDATE,
  active NUMBER(126) DEFAULT 1,
  attach BLOB,
  sender VARCHAR2(255),
  content_type VARCHAR2(50),
  attach_content_type VARCHAR2(50),
  attach_filename VARCHAR2(255)
);

--
-- Table: bali_namespace
--
DROP TABLE bali_namespace;

CREATE TABLE bali_namespace (
  id INTEGER PRIMARY KEY NOT NULL,
  ns VARCHAR2(100) NOT NULL,
  provider VARCHAR2(500)
);

--
-- Table: bali_plugin
--
DROP TABLE bali_plugin;

CREATE TABLE bali_plugin (
  id INTEGER PRIMARY KEY NOT NULL,
  plugin VARCHAR(250) NOT NULL,
  desc VARCHAR(500) NOT NULL,
  wiki_id INT(10) NOT NULL
);

--
-- Table: bali_project
--
DROP TABLE bali_project;

CREATE TABLE bali_project (
  id  NOT NULL,
  name varchar2(1024) NOT NULL,
  data clob,
  ns varchar2(1024) DEFAULT '/',
  bl varchar2(1024) DEFAULT '*',
  ts datetime DEFAULT current_timestamp,
  domain varchar2(1),
  description clob,
  id_parent numeric(126),
  nature varchar2(1024),
  PRIMARY KEY (id),
  FOREIGN KEY(id_parent) REFERENCES bali_project(id)
);

CREATE INDEX bali_project_idx_id_parent ON bali_project (id_parent);

--
-- Table: bali_provider
--
DROP TABLE bali_provider;

CREATE TABLE bali_provider (
  id INTEGER PRIMARY KEY NOT NULL,
  plugin VARCHAR(250) NOT NULL
);

--
-- Table: bali_relationship
--
DROP TABLE bali_relationship;

CREATE TABLE bali_relationship (
  from_ns VARCHAR2(1024) NOT NULL,
  to_ns VARCHAR2(1024) NOT NULL,
  from_id NUMBER(38),
  to_id NUMBER(38),
  type VARCHAR2(45),
  PRIMARY KEY (to_ns, from_ns)
);

--
-- Table: bali_release
--
DROP TABLE bali_release;

CREATE TABLE bali_release (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(2000),
  active CHAR(1) NOT NULL DEFAULT 1,
  ts DATE(19) DEFAULT SYSDATE,
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  username VARCHAR2(255),
  ns VARCHAR2(1024) DEFAULT '/',
);

--
-- Table: bali_repo
--
DROP TABLE bali_repo;

CREATE TABLE bali_repo (
  ns VARCHAR2(1024) NOT NULL,
  backend VARCHAR2(1024) DEFAULT 'default',
  ts DATE(19) DEFAULT SYSDATE,
  bl VARCHAR2(255) DEFAULT '*',
  provider VARCHAR2(1024) NOT NULL,
  item VARCHAR2(1024) NOT NULL,
  class VARCHAR2(1024) NOT NULL,
  data CLOB(2147483647),
  PRIMARY KEY (ns)
);

--
-- Table: bali_request
--
DROP TABLE bali_request;

CREATE TABLE bali_request (
  id INTEGER PRIMARY KEY NOT NULL,
  ns VARCHAR2(1024) NOT NULL,
  bl VARCHAR2(50) DEFAULT '*',
  requested_on DATE(19),
  finished_on DATE(19),
  status VARCHAR2(50) DEFAULT 'pending',
  finished_by VARCHAR2(255),
  requested_by VARCHAR2(255),
  action VARCHAR2(255),
  id_parent NUMBER(38),
  key VARCHAR2(255),
  name VARCHAR2(255),
  type VARCHAR2(100) DEFAULT 'approval',
  id_wiki NUMBER(126),
  id_job NUMBER(126),
  data CLOB(2147483647),
  callback VARCHAR2(1024),
  id_message NUMBER(126)
);

--
-- Table: bali_role
--
DROP TABLE bali_role;

CREATE TABLE bali_role (
  id INTEGER PRIMARY KEY NOT NULL,
  role VARCHAR2(255) NOT NULL,
  description VARCHAR2(2048),
  mailbox VARCHAR2(255)
);

--
-- Table: bali_sem
--
DROP TABLE bali_sem;

CREATE TABLE bali_sem (
  sem VARCHAR2(1024) NOT NULL,
  description VARCHAR2(2147483647),
  slots NUMBER(126) DEFAULT 1,
  active NUMBER(126) DEFAULT 1,
  bl VARCHAR2(255) NOT NULL DEFAULT '*',
  queue_mode VARCHAR2(255) NOT NULL DEFAULT 'slot',
  PRIMARY KEY (sem, bl)
);

--
-- Table: bali_sem_queue
--
DROP TABLE bali_sem_queue;

CREATE TABLE bali_sem_queue (
  id INTEGER PRIMARY KEY NOT NULL,
  sem VARCHAR2(1024) NOT NULL,
  who VARCHAR2(1024),
  who_id VARCHAR2(255),
  host VARCHAR2(255) DEFAULT 'localhost',
  pid NUMBER(126),
  status VARCHAR2(50) DEFAULT 'idle',
  active NUMBER(126) DEFAULT 1,
  seq NUMBER(126),
  id_job NUMBER(126),
  run_now NUMBER(126) DEFAULT 0,
  wait_secs NUMBER(126) DEFAULT 0,
  busy_secs NUMBER(126) DEFAULT 0,
  ts_request DATE(19) DEFAULT sysdate,
  ts_grant DATE(19),
  ts_release DATE(19),
  bl VARCHAR2(50) DEFAULT '*',
  caller VARCHAR2(1024),
  expire_on DATE(19)
);

--
-- Table: bali_service
--
DROP TABLE bali_service;

CREATE TABLE bali_service (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(100) NOT NULL,
  desc VARCHAR(100) NOT NULL,
  wiki_id INT(10) NOT NULL
);

--
-- Table: bali_session
--
DROP TABLE bali_session;

CREATE TABLE bali_session (
  id VARCHAR2(72) NOT NULL,
  session_data CLOB(2147483647),
  expires NUMBER(126),
  PRIMARY KEY (id)
);

--
-- Table: bali_user
--
DROP TABLE bali_user;

CREATE TABLE bali_user (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar2(45) NOT NULL,
  password varchar2(45) NOT NULL,
  realname varchar2(4000),
  avatar blob,
  data clob,
  alias varchar2(512)
);

--
-- Table: bali_user_project
--
DROP TABLE bali_user_project;

CREATE TABLE bali_user_project (
  id  NOT NULL,
  name  NOT NULL,
  info ,
  PRIMARY KEY (id)
);

--
-- Table: bali_wiki
--
DROP TABLE bali_wiki;

CREATE TABLE bali_wiki (
  id INTEGER PRIMARY KEY NOT NULL,
  text CLOB(2147483647),
  username VARCHAR2(255),
  modified_on DATE(19) DEFAULT SYSDATE,
  content_type VARCHAR2(255) DEFAULT 'text/plain',
  id_wiki NUMBER(126)
);

--
-- Table: bali_calendar_window
--
DROP TABLE bali_calendar_window;

CREATE TABLE bali_calendar_window (
  id INTEGER PRIMARY KEY NOT NULL DEFAULT 1,
  start_time VARCHAR2(20),
  end_time VARCHAR2(20),
  day VARCHAR2(20),
  type VARCHAR2(1),
  active VARCHAR2(1) DEFAULT 1,
  id_cal NUMBER(126) NOT NULL DEFAULT 1,
  start_date DATE(19),
  end_date DATE(19),
  FOREIGN KEY(id_cal) REFERENCES bali_calendar(id)
);

CREATE INDEX bali_calendar_window_idx_id_cal ON bali_calendar_window (id_cal);

--
-- Table: bali_job
--
DROP TABLE bali_job;

CREATE TABLE bali_job (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR2(45),
  starttime DATE(19) NOT NULL DEFAULT SYSDATE,
  maxstarttime DATE(19) NOT NULL DEFAULT SYSDATE,
  endtime DATE(19),
  status VARCHAR2(45) NOT NULL DEFAULT 'READY',
  ns VARCHAR2(45) NOT NULL DEFAULT '/',
  bl VARCHAR2(45) NOT NULL DEFAULT '*',
  runner VARCHAR2(255),
  pid NUMBER(38),
  comments VARCHAR2(1024),
  type VARCHAR2(100),
  username VARCHAR2(255),
  ts DATE(19) DEFAULT SYSDATE,
  host VARCHAR2(255) DEFAULT 'localhost',
  owner VARCHAR2(255),
  step VARCHAR2(50) DEFAULT 'PRE',
  id_stash NUMBER(38),
  rollback NUMBER(126) DEFAULT 0,
  now NUMBER(126) DEFAULT 0,
  schedtime DATE(19) DEFAULT sysdate,
  exec NUMBER(126) DEFAULT 1,
  request_status VARCHAR2(50),
  FOREIGN KEY(id_stash) REFERENCES bali_job_stash(id)
);

CREATE INDEX bali_job_idx_id_stash ON bali_job (id_stash);

--
-- Table: bali_job_stash
--
DROP TABLE bali_job_stash;

CREATE TABLE bali_job_stash (
  id INTEGER PRIMARY KEY NOT NULL,
  stash BLOB,
  id_job NUMBER(38),
  FOREIGN KEY(id_job) REFERENCES bali_job(id)
);

CREATE INDEX bali_job_stash_idx_id_job ON bali_job_stash (id_job);

--
-- Table: bali_message_queue
--
DROP TABLE bali_message_queue;

CREATE TABLE bali_message_queue (
  id INTEGER PRIMARY KEY NOT NULL,
  id_message NUMBER(126),
  username VARCHAR2(255),
  destination VARCHAR2(50),
  sent DATE(19) DEFAULT SYSDATE,
  received DATE(19),
  active NUMBER(126) DEFAULT 1,
  carrier VARCHAR2(50) DEFAULT 'instant',
  carrier_param VARCHAR2(50),
  result CLOB(2147483647),
  attempts NUMBER(126) DEFAULT 0,
  FOREIGN KEY(id_message) REFERENCES bali_message(id)
);

CREATE INDEX bali_message_queue_idx_id_message ON bali_message_queue (id_message);

--
-- Table: bali_project_items
--
DROP TABLE bali_project_items;

CREATE TABLE bali_project_items (
  id  NOT NULL,
  id_project numeric(126) NOT NULL,
  ns varchar2(1024),
  PRIMARY KEY (id),
  FOREIGN KEY(id_project) REFERENCES bali_project(id)
);

CREATE INDEX bali_project_items_idx_id_project ON bali_project_items (id_project);

--
-- Table: bali_release_items
--
DROP TABLE bali_release_items;

CREATE TABLE bali_release_items (
  id INTEGER PRIMARY KEY NOT NULL,
  id_rel NUMBER(38) NOT NULL,
  item VARCHAR2(1024),
  provider VARCHAR2(1024),
  data CLOB(2147483647),
  ns VARCHAR2(255),
  FOREIGN KEY(id_rel) REFERENCES bali_release(id)
);

CREATE INDEX bali_release_items_idx_id_rel ON bali_release_items (id_rel);

--
-- Table: bali_repokeys
--
DROP TABLE bali_repokeys;

CREATE TABLE bali_repokeys (
  ns VARCHAR2(1024) NOT NULL,
  ts DATE(19) DEFAULT SYSDATE,
  bl VARCHAR2(255) NOT NULL DEFAULT '*',
  version NUMBER(38) NOT NULL DEFAULT 0,
  k VARCHAR2(255) NOT NULL,
  v CLOB(2147483647) NOT NULL,
  PRIMARY KEY (ns, bl, k, version),
  FOREIGN KEY(ns) REFERENCES bali_repo(ns)
);

CREATE INDEX bali_repokeys_idx_ns ON bali_repokeys (ns);

--
-- Table: bali_roleaction
--
DROP TABLE bali_roleaction;

CREATE TABLE bali_roleaction (
  id_role NUMBER(38) NOT NULL,
  action VARCHAR2(255) NOT NULL,
  bl VARCHAR2(50) NOT NULL DEFAULT '*',
  PRIMARY KEY (action, id_role, bl),
  FOREIGN KEY(id_role) REFERENCES bali_role(id)
);

CREATE INDEX bali_roleaction_idx_id_role ON bali_roleaction (id_role);

--
-- Table: bali_job_items
--
DROP TABLE bali_job_items;

CREATE TABLE bali_job_items (
  id INTEGER PRIMARY KEY NOT NULL,
  data CLOB(2147483647),
  item VARCHAR2(1024),
  provider VARCHAR2(1024),
  id_job NUMBER(38) NOT NULL,
  service VARCHAR2(255),
  application VARCHAR2(1024),
  rfc VARCHAR2(1024),
  FOREIGN KEY(id_job) REFERENCES bali_job(id)
);

CREATE INDEX bali_job_items_idx_id_job ON bali_job_items (id_job);

--
-- Table: bali_log
--
DROP TABLE bali_log;

CREATE TABLE bali_log (
  id INTEGER PRIMARY KEY NOT NULL,
  text VARCHAR2(2048),
  lev VARCHAR2(10),
  id_job NUMBER(38) NOT NULL,
  more VARCHAR2(10),
  timestamp DATE(19) DEFAULT SYSDATE,
  ns VARCHAR2(255) DEFAULT '/',
  provider VARCHAR2(255),
  data BLOB,
  data_name VARCHAR2(1024),
  data_length NUMBER(38) DEFAULT 0,
  module VARCHAR2(1024),
  section VARCHAR2(255) DEFAULT 'general',
  step VARCHAR2(50),
  exec NUMBER(126) DEFAULT 1,
  prefix VARCHAR2(1024),
  milestone VARCHAR2(1024),
  FOREIGN KEY(id_job) REFERENCES bali_job(id),
  FOREIGN KEY(id_job) REFERENCES bali_job(id)
);

CREATE INDEX bali_log_idx_id_job ON bali_log (id_job);

CREATE INDEX bali_log_idx_id_job_exec ON bali_log (id_job, exec);

--
-- Table: bali_roleuser
--
DROP TABLE bali_roleuser;

CREATE TABLE bali_roleuser (
  username VARCHAR2(255) NOT NULL,
  id_role NUMBER(38) NOT NULL,
  ns VARCHAR2(100) NOT NULL DEFAULT '/',
  PRIMARY KEY (ns, id_role, username),
  FOREIGN KEY(username) REFERENCES bali_user(username),
  FOREIGN KEY(id_role) REFERENCES bali_role(id)
);

CREATE INDEX bali_roleuser_idx_username ON bali_roleuser (username);

CREATE INDEX bali_roleuser_idx_id_role ON bali_roleuser (id_role);

--
-- Table: bali_log_data
--
DROP TABLE bali_log_data;

CREATE TABLE bali_log_data (
  id INTEGER PRIMARY KEY NOT NULL,
  id_log NUMBER(38) NOT NULL,
  data BLOB,
  timestamp DATE(19) DEFAULT SYSDATE,
  name VARCHAR2(2048),
  type VARCHAR2(255),
  len NUMBER(38),
  FOREIGN KEY(id_log) REFERENCES bali_log(id)
);

CREATE INDEX bali_log_data_idx_id_log ON bali_log_data (id_log);

COMMIT;