-- Convert schema 'sql/Baseliner-Schema-Baseliner-1-Oracle.sql' to 'sql/Baseliner-Schema-Baseliner-2-Oracle.sql':;

-- Output database Oracle is untested/unsupported!!!;

BEGIN;

CREATE TABLE bali_topic (
  id number(38) NOT NULL,
  title varchar2(1024) NOT NULL,
  description clob NOT NULL,
  created_on date DEFAULT SYSDATE NOT NULL,
  created_by varchar2(255) NOT NULL,
  status char(1) DEFAULT 'O' NOT NULL,
  id_category number(38) NOT NULL,
  id_category_status number(38),
  id_priority number(38),
  response_time_min number(38),
  deadline_min number(38),
  expr_response_time varchar2(255),
  expr_deadline varchar2(255),
  PRIMARY KEY (id)
);

CREATE TABLE bali_topic_categories (
  id number(38) NOT NULL,
  name varchar2(255) NOT NULL,
  description varchar2(1024),
  PRIMARY KEY (id)
);

CREATE TABLE bali_topic_categories_status (
  id_category number(38) NOT NULL,
  id_status number(38) NOT NULL
);

CREATE TABLE bali_topic_label (
  id_topic number(38) NOT NULL,
  id_label number(38) NOT NULL
);

CREATE TABLE bali_topic_msg (
  id number(38) NOT NULL,
  id_topic number(38) NOT NULL,
  text clob NOT NULL,
  created_on date DEFAULT SYSDATE NOT NULL,
  created_by varchar2(255) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE bali_topic_priority (
  id number(38) NOT NULL,
  name varchar2(255) NOT NULL,
  response_time_min number(38),
  deadline_min number(38),
  expr_response_time varchar2(255),
  expr_deadline varchar2(255),
  PRIMARY KEY (id)
);

CREATE TABLE bali_topic_project (
  id_topic number(38) NOT NULL,
  id_project number(38) NOT NULL
);

CREATE TABLE bali_topic_status (
  id number(38) NOT NULL,
  name varchar2(255) NOT NULL,
  description varchar2(1024),
  PRIMARY KEY (id)
);

CREATE INDEX bali_topic_categories_status01 on bali_topic_categories_status (id_status);

CREATE INDEX bali_topic_label_idx_id_labe01 on bali_topic_label (id_label);

CREATE INDEX bali_topic_project_idx_id_pr01 on bali_topic_project (id_project);

DROP TABLE bali_issue CASCADE CONSTRAINTS;

DROP TABLE bali_issue_categories CASCADE CONSTRAINTS;

DROP TABLE bali_issue_msg CASCADE CONSTRAINTS;

DROP TABLE bali_issue_priority CASCADE CONSTRAINTS;

DROP TABLE bali_issue_status CASCADE CONSTRAINTS;

DROP TABLE bali_issue_categories_status CASCADE CONSTRAINTS;

DROP TABLE bali_issue_label CASCADE CONSTRAINTS;

DROP TABLE bali_issue_project CASCADE CONSTRAINTS;


COMMIT;

