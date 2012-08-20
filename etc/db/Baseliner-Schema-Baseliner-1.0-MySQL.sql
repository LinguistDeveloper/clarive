-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed Mar 16 14:34:35 2011
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `bali_baseline`;

--
-- Table: `bali_baseline`
--
CREATE TABLE `bali_baseline` (
  `id` bigint(126) NOT NULL,
  `bl` varchar(100) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_calendar`;

--
-- Table: `bali_calendar`
--
CREATE TABLE `bali_calendar` (
  `id` bigint(126) NOT NULL,
  `name` varchar(100) NOT NULL,
  `ns` varchar(100) NOT NULL DEFAULT ''/'                   ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                   ',
  `description` text,
  `type` varchar(2) DEFAULT 'HI',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_chain`;

--
-- Table: `bali_chain`
--
CREATE TABLE `bali_chain` (
  `id` bigint(38) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `job_type` varchar(50),
  `active` bigint(126) DEFAULT 1,
  `action` varchar(255),
  `ns` text DEFAULT ''/'',
  `bl` varchar(50) DEFAULT ''*'',
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_chained_service`;

--
-- Table: `bali_chained_service`
--
CREATE TABLE `bali_chained_service` (
  `id` bigint(126) NOT NULL,
  `chain_id` bigint(126) NOT NULL,
  `seq` bigint(126) NOT NULL,
  `key` varchar(255) NOT NULL,
  `description` text,
  `step` varchar(50) DEFAULT ''RUN'',
  `active` bigint(126) DEFAULT 1,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_commonfiles`;

--
-- Table: `bali_commonfiles`
--
CREATE TABLE `bali_commonfiles` (
  `id` bigint(126) NOT NULL,
  `nombre` varchar(64) NOT NULL,
  `tipo` CHAR(4) NOT NULL,
  `descripcion` text,
  `ns` varchar(100) NOT NULL DEFAULT ''/'                   ',
  `f_alta` DATE DEFAULT 'SYSDATE',
  `f_baja` DATE DEFAULT 'to_date('99991231','yyyymmdd')',
  `separador` CHAR(4) DEFAULT ''/'',
  `src_dir` text NOT NULL DEFAULT ''\'                   ',
  `sep_comment` CHAR(4) DEFAULT '';'',
  `clave_num` varchar(20) DEFAULT ''TRUE'',
  PRIMARY KEY (`id`),
  UNIQUE `bali_commonfiles_u01` (`src_dir`, `nombre`),
  UNIQUE `bali_commonfiles_u02` (`id`, `f_baja`, `ns`)
);

DROP TABLE IF EXISTS `bali_commonfiles_values`;

--
-- Table: `bali_commonfiles_values`
--
CREATE TABLE `bali_commonfiles_values` (
  `fileid` bigint(126) NOT NULL,
  `clave` text NOT NULL,
  `valor` text,
  `secordesc` text,
  `ns` varchar(100) NOT NULL DEFAULT ''/'                   ',
  `f_alta` DATE NOT NULL DEFAULT 'SYSDATE',
  `f_baja` DATE NOT NULL DEFAULT 'TO_DATE('99991231','yyyymmdd')',
  `f_modif` DATE DEFAULT 'SYSDATE',
  `last_user` varchar(15),
  `change_type` CHAR(1) NOT NULL,
  `orden` bigint(126) NOT NULL DEFAULT '0',
  PRIMARY KEY (`fileid`, `clave`, `f_alta`, `ns`, `change_type`)
);

DROP TABLE IF EXISTS `bali_config`;

--
-- Table: `bali_config`
--
CREATE TABLE `bali_config` (
  `id` bigint(126) NOT NULL,
  `ns` text NOT NULL DEFAULT ''/'                   ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                   ',
  `key` varchar(100) NOT NULL,
  `value` text DEFAULT NULL,
  `ts` DATE NOT NULL DEFAULT 'SYSDATE               ',
  `ref` bigint(126),
  `reftable` varchar(100),
  `data` BLOB,
  `parent_id` bigint(126) NOT NULL DEFAULT 0                     ,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_config_rel`;

--
-- Table: `bali_config_rel`
--
CREATE TABLE `bali_config_rel` (
  `id` INTEGER NOT NULL,
  `namespace_id` integer(10) NOT NULL,
  `plugin_id` integer(10) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_configset`;

--
-- Table: `bali_configset`
--
CREATE TABLE `bali_configset` (
  `id` INTEGER NOT NULL,
  `namespace_id` integer(10) NOT NULL,
  `baseline_id` integer(10) NOT NULL,
  `wiki_id` integer(10) NOT NULL,
  `created_on` datetime NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_daemon`;

--
-- Table: `bali_daemon`
--
CREATE TABLE `bali_daemon` (
  `id` bigint(126) NOT NULL,
  `service` varchar(255),
  `active` bigint(126) DEFAULT 1,
  `config` varchar(255),
  `pid` bigint(126),
  `params` text,
  `hostname` varchar(255) DEFAULT ''localhost'',
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_file_dist`;

--
-- Table: `bali_file_dist`
--
CREATE TABLE `bali_file_dist` (
  `id` bigint(126) NOT NULL,
  `ns` text NOT NULL DEFAULT ''/'                 ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                 ',
  `filter` text DEFAULT ''*.*'    ',
  `isrecursive` tinyint(1) DEFAULT '0    ',
  `src_dir` varchar(100) NOT NULL DEFAULT ''.'     ',
  `dest_dir` varchar(100) NOT NULL,
  `ssh_host` varchar(100) NOT NULL,
  `xtype` varchar(16),
  `sys` varchar(20) NOT NULL DEFAULT 'AIX',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_message`;

--
-- Table: `bali_message`
--
CREATE TABLE `bali_message` (
  `id` bigint(126) NOT NULL,
  `subject` text NOT NULL,
  `body` longtext,
  `created` DATE DEFAULT 'SYSDATE',
  `active` bigint(126) DEFAULT 1,
  `attach` BLOB,
  `sender` varchar(255),
  `content_type` varchar(50),
  `attach_content_type` varchar(50),
  `attach_filename` varchar(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_namespace`;

--
-- Table: `bali_namespace`
--
CREATE TABLE `bali_namespace` (
  `id` bigint(126) NOT NULL,
  `ns` varchar(100) NOT NULL,
  `provider` text,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_plugin`;

--
-- Table: `bali_plugin`
--
CREATE TABLE `bali_plugin` (
  `id` INTEGER NOT NULL,
  `plugin` VARCHAR(250) NOT NULL,
  `desc` text NOT NULL,
  `wiki_id` integer(10) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_project`;

--
-- Table: `bali_project`
--
CREATE TABLE `bali_project` (
  `id`  NOT NULL auto_increment,
  `name` text NOT NULL,
  `data` longtext,
  `ns` text DEFAULT '/',
  `bl` text DEFAULT '*',
  `ts` datetime DEFAULT current_timestamp,
  `domain` varchar(1),
  `description` longtext,
  `id_parent` numeric(126),
  INDEX `bali_project_idx_id_parent` (`id_parent`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_project_fk_id_parent` FOREIGN KEY (`id_parent`) REFERENCES `bali_project` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_provider`;

--
-- Table: `bali_provider`
--
CREATE TABLE `bali_provider` (
  `id` INTEGER NOT NULL,
  `plugin` VARCHAR(250) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_relationship`;

--
-- Table: `bali_relationship`
--
CREATE TABLE `bali_relationship` (
  `from_id` bigint(38) NOT NULL,
  `to_id` bigint(38) NOT NULL,
  `type` varchar(45),
  PRIMARY KEY (`to_id`, `from_id`)
);

DROP TABLE IF EXISTS `bali_release`;

--
-- Table: `bali_release`
--
CREATE TABLE `bali_release` (
  `id` bigint(38) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `active` CHAR(1) NOT NULL DEFAULT '1 ',
  `ts` DATE DEFAULT 'SYSDATE',
  `bl` varchar(100) NOT NULL DEFAULT ''*' ',
  `username` varchar(255),
  `ns` text DEFAULT ''/'',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_repo`;

--
-- Table: `bali_repo`
--
CREATE TABLE `bali_repo` (
  `ns` text NOT NULL,
  `backend` text DEFAULT ''default'',
  `ts` DATE DEFAULT 'SYSDATE',
  `bl` varchar(255) DEFAULT ''*'',
  `provider` text NOT NULL,
  `item` text NOT NULL,
  `class` text NOT NULL,
  `data` longtext,
  PRIMARY KEY (`ns`)
);

DROP TABLE IF EXISTS `bali_request`;

--
-- Table: `bali_request`
--
CREATE TABLE `bali_request` (
  `id` bigint(38) NOT NULL auto_increment,
  `ns` text NOT NULL,
  `bl` varchar(50) DEFAULT '*',
  `requested_on` DATE,
  `finished_on` DATE,
  `status` varchar(50) DEFAULT 'pending',
  `finished_by` varchar(255),
  `requested_by` varchar(255),
  `action` varchar(255),
  `id_parent` bigint(38),
  `key` varchar(255),
  `name` varchar(255),
  `type` varchar(100) DEFAULT 'approval',
  `id_wiki` bigint(126),
  `id_job` bigint(126),
  `data` longtext,
  `callback` text,
  `id_message` bigint(126),
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_role`;

--
-- Table: `bali_role`
--
CREATE TABLE `bali_role` (
  `id` bigint(38) NOT NULL auto_increment,
  `role` varchar(255) NOT NULL,
  `description` text,
  `mailbox` varchar(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_sem`;

--
-- Table: `bali_sem`
--
CREATE TABLE `bali_sem` (
  `name` varchar(255) NOT NULL,
  `description` longtext,
  `active` bigint(126) DEFAULT 1,
  `type` varchar(50) DEFAULT ''global'
',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_service`;

--
-- Table: `bali_service`
--
CREATE TABLE `bali_service` (
  `id` INTEGER NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `desc` VARCHAR(100) NOT NULL,
  `wiki_id` integer(10) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_session`;

--
-- Table: `bali_session`
--
CREATE TABLE `bali_session` (
  `id` varchar(72) NOT NULL,
  `session_data` longtext,
  `expires` bigint(126),
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_user`;

--
-- Table: `bali_user`
--
CREATE TABLE `bali_user` (
  `id` bigint(126) NOT NULL auto_increment,
  `username` varchar(45) NOT NULL,
  `password` varchar(45) NOT NULL,
  `realname` text,
  `avatar` BLOB,
  `alias` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_wiki`;

--
-- Table: `bali_wiki`
--
CREATE TABLE `bali_wiki` (
  `id` bigint(126) NOT NULL,
  `text` longtext,
  `username` varchar(255),
  `modified_on` DATE DEFAULT 'SYSDATE',
  `content_type` varchar(255) DEFAULT ''text/plain'
',
  `id_wiki` bigint(126),
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_calendar_window`;

--
-- Table: `bali_calendar_window`
--
CREATE TABLE `bali_calendar_window` (
  `id` bigint(126) NOT NULL DEFAULT 1                     ,
  `start_time` varchar(20),
  `end_time` varchar(20),
  `day` varchar(20),
  `type` varchar(1),
  `active` varchar(1) DEFAULT ''1'',
  `id_cal` bigint(126) NOT NULL DEFAULT 1                     ,
  `start_date` DATE,
  `end_date` DATE,
  INDEX `bali_calendar_window_idx_id_cal` (`id_cal`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_calendar_window_fk_id_cal` FOREIGN KEY (`id_cal`) REFERENCES `bali_calendar` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_job`;

--
-- Table: `bali_job`
--
CREATE TABLE `bali_job` (
  `id` bigint(38) NOT NULL auto_increment,
  `name` varchar(45),
  `starttime` DATE NOT NULL DEFAULT SYSDATE,
  `maxstarttime` DATE NOT NULL DEFAULT SYSDATE+1,
  `endtime` DATE,
  `status` varchar(45) NOT NULL DEFAULT 'READY',
  `ns` varchar(45) NOT NULL DEFAULT '/',
  `bl` varchar(45) NOT NULL DEFAULT '*',
  `runner` varchar(255),
  `pid` bigint(38),
  `comments` text,
  `type` varchar(100),
  `username` varchar(255),
  `ts` DATE DEFAULT SYSDATE,
  `host` varchar(255) DEFAULT 'localhost',
  `owner` varchar(255),
  `step` varchar(50) DEFAULT 'PRE',
  `id_stash` bigint(38),
  `rollback` bigint(126) DEFAULT 0,
  `now` bigint(126) DEFAULT 0,
  `schedtime` DATE DEFAULT sysdate,
  `exec` bigint(126) DEFAULT 1,
  `request_status` varchar(50),
  INDEX `bali_job_idx_id_stash` (`id_stash`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_job_fk_id_stash` FOREIGN KEY (`id_stash`) REFERENCES `bali_job_stash` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_job_stash`;

--
-- Table: `bali_job_stash`
--
CREATE TABLE `bali_job_stash` (
  `id` bigint(38) NOT NULL auto_increment,
  `stash` BLOB,
  `id_job` bigint(38),
  INDEX `bali_job_stash_idx_id_job` (`id_job`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_job_stash_fk_id_job` FOREIGN KEY (`id_job`) REFERENCES `bali_job` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_message_queue`;

--
-- Table: `bali_message_queue`
--
CREATE TABLE `bali_message_queue` (
  `id` bigint(126) NOT NULL,
  `id_message` bigint(126),
  `username` varchar(255),
  `destination` varchar(50),
  `sent` DATE DEFAULT 'SYSDATE',
  `received` DATE,
  `active` bigint(126) DEFAULT 1,
  `carrier` varchar(50) DEFAULT ''instant'',
  `carrier_param` varchar(50),
  `result` longtext,
  `attempts` bigint(126) DEFAULT 0,
  INDEX `bali_message_queue_idx_id_message` (`id_message`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_message_queue_fk_id_message` FOREIGN KEY (`id_message`) REFERENCES `bali_message` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_project_items`;

--
-- Table: `bali_project_items`
--
CREATE TABLE `bali_project_items` (
  `id` bigint(126) NOT NULL auto_increment,
  `id_project` bigint(126) NOT NULL,
  `ns` text,
  INDEX `bali_project_items_idx_id_project` (`id_project`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_project_items_fk_id_project` FOREIGN KEY (`id_project`) REFERENCES `bali_project` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_release_items`;

--
-- Table: `bali_release_items`
--
CREATE TABLE `bali_release_items` (
  `id` bigint(38) NOT NULL,
  `id_rel` bigint(38) NOT NULL,
  `item` text,
  `provider` text,
  `data` longtext,
  `ns` varchar(255),
  INDEX `bali_release_items_idx_id_rel` (`id_rel`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_release_items_fk_id_rel` FOREIGN KEY (`id_rel`) REFERENCES `bali_release` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_roleaction`;

--
-- Table: `bali_roleaction`
--
CREATE TABLE `bali_roleaction` (
  `id_role` bigint(38) NOT NULL,
  `action` varchar(255) NOT NULL,
  `bl` varchar(50) NOT NULL DEFAULT '*',
  INDEX `bali_roleaction_idx_id_role` (`id_role`),
  PRIMARY KEY (`action`, `id_role`, `bl`),
  CONSTRAINT `bali_roleaction_fk_id_role` FOREIGN KEY (`id_role`) REFERENCES `bali_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_roleuser`;

--
-- Table: `bali_roleuser`
--
CREATE TABLE `bali_roleuser` (
  `username` varchar(255) NOT NULL,
  `id_role` bigint(126) NOT NULL,
  `ns` varchar(100) NOT NULL DEFAULT ''/'                   ',
  INDEX bali_roleuser_idx_id_role (`id_role`),
  PRIMARY KEY (`username`, `id_role`),
  CONSTRAINT `bali_roleuser_fk_id_role` FOREIGN KEY (`id_role`) REFERENCES `bali_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_sem_queue`;

--
-- Table: `bali_sem_queue`
--
CREATE TABLE `bali_sem_queue` (
  `id` bigint(126) NOT NULL,
  `who` text,
  `host` varchar(255) DEFAULT ''localhost'',
  `pid` bigint(126),
  `active` bigint(126) DEFAULT 1,
  `place` bigint(126),
  `now` bigint(126) DEFAULT 0
,
  `ts_request` DATE DEFAULT 'sysdate',
  `ts_grant` DATE,
  `ts_release` DATE,
  `bl` varchar(50) DEFAULT ''*'',
  `caller` text,
  `sem_name` varchar(255) NOT NULL,
  `wait_until` DATE,
  `status` varchar(50) DEFAULT ''idle'',
  INDEX `bali_sem_queue_idx_sem_name` (`sem_name`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_sem_queue_fk_sem_name` FOREIGN KEY (`sem_name`) REFERENCES `bali_sem` (`name`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_sqa`;

--
-- Table: `bali_sqa`
--
CREATE TABLE `bali_sqa` (
  `id`  NOT NULL auto_increment,
  `ns` text,
  `bl` text,
  `id_prj` numeric(126),
  `nature` text,
  `qualification` text,
  `status` text,
  `data` longtext,
  INDEX `bali_sqa_idx_id_prj` (`id_prj`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_sqa_fk_id_prj` FOREIGN KEY (`id_prj`) REFERENCES `bali_project` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_job_items`;

--
-- Table: `bali_job_items`
--
CREATE TABLE `bali_job_items` (
  `id` bigint(38) NOT NULL auto_increment,
  `data` longtext,
  `item` text,
  `provider` text,
  `id_job` bigint(38) NOT NULL,
  `service` varchar(255),
  `application` text,
  `rfc` text,
  INDEX `bali_job_items_idx_id_job` (`id_job`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_job_items_fk_id_job` FOREIGN KEY (`id_job`) REFERENCES `bali_job` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_log`;

--
-- Table: `bali_log`
--
CREATE TABLE `bali_log` (
  `id` bigint(38) NOT NULL auto_increment,
  `text` text,
  `lev` varchar(10),
  `id_job` bigint(38) NOT NULL,
  `more` varchar(10),
  `timestamp` DATE DEFAULT SYSDATE,
  `ns` varchar(255) DEFAULT '/',
  `provider` varchar(255),
  `data` BLOB,
  `data_name` text,
  `data_length` bigint(38) DEFAULT 0,
  `module` text,
  `section` varchar(255) DEFAULT 'general',
  `step` varchar(50),
  `exec` bigint(126) DEFAULT 1,
  `prefix` text,
  `milestone` text,
  INDEX `bali_log_idx_id_job` (`id_job`),
  INDEX `bali_log_idx_id_job_exec` (`id_job`, `exec`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_log_fk_id_job` FOREIGN KEY (`id_job`) REFERENCES `bali_job` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bali_log_fk_id_job_exec` FOREIGN KEY (`id_job`, `exec`) REFERENCES `bali_job` (`id`, `exec`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_roleuser`;

--
-- Table: `bali_roleuser`
--
CREATE TABLE `bali_roleuser` (
  `username` varchar(255) NOT NULL,
  `id_role` bigint(38) NOT NULL,
  `ns` varchar(100) NOT NULL DEFAULT '/',
  INDEX `bali_roleuser_idx_username` (`username`),
  INDEX `bali_roleuser_idx_id_role` (`id_role`),
  PRIMARY KEY (`ns`, `id_role`, `username`),
  CONSTRAINT `bali_roleuser_fk_username` FOREIGN KEY (`username`) REFERENCES `bali_user` (`username`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bali_roleuser_fk_id_role` FOREIGN KEY (`id_role`) REFERENCES `bali_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_log_data`;

--
-- Table: `bali_log_data`
--
CREATE TABLE `bali_log_data` (
  `id` bigint(38) NOT NULL auto_increment,
  `id_log` bigint(38) NOT NULL,
  `data` BLOB,
  `timestamp` DATE DEFAULT SYSDATE,
  `name` text,
  `type` varchar(255),
  `len` bigint(38),
  INDEX `bali_log_data_idx_id_log` (`id_log`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_log_data_fk_id_log` FOREIGN KEY (`id_log`) REFERENCES `bali_log` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

