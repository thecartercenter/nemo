CREATE TABLE `answers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `response_id` int(11) DEFAULT NULL,
  `option_id` int(11) DEFAULT NULL,
  `value` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `questioning_id` int(11) DEFAULT NULL,
  `time_value` time DEFAULT NULL,
  `date_value` date DEFAULT NULL,
  `datetime_value` datetime DEFAULT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `answers_option_id_fk` (`option_id`),
  KEY `answers_questioning_id_fk` (`questioning_id`),
  KEY `answers_response_id_fk` (`response_id`),
  FULLTEXT KEY `fulltext_answers` (`value`)
) ENGINE=MyISAM AUTO_INCREMENT=183 DEFAULT CHARSET=utf8;

CREATE TABLE `assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mission_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `active` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `role` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `assignments_mission_id_fk` (`mission_id`),
  KEY `assignments_user_id_fk` (`user_id`),
  CONSTRAINT `assignments_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `assignments_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=295 DEFAULT CHARSET=latin1;

CREATE TABLE `broadcast_addressings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `broadcast_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `broadcast_addressings_broadcast_id_fk` (`broadcast_id`),
  KEY `broadcast_addressings_user_id_fk` (`user_id`),
  CONSTRAINT `broadcast_addressings_broadcast_id_fk` FOREIGN KEY (`broadcast_id`) REFERENCES `broadcasts` (`id`),
  CONSTRAINT `broadcast_addressings_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `broadcasts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subject` varchar(255) DEFAULT NULL,
  `body` text,
  `medium` varchar(255) DEFAULT NULL,
  `send_errors` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `which_phone` varchar(255) DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `broadcasts_mission_id_fk` (`mission_id`),
  CONSTRAINT `broadcasts_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `choices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `answer_id` int(11) DEFAULT NULL,
  `option_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `choices_answer_id_fk` (`answer_id`),
  KEY `choices_option_id_fk` (`option_id`),
  CONSTRAINT `choices_option_id_fk` FOREIGN KEY (`option_id`) REFERENCES `options` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

CREATE TABLE `conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `questioning_id` int(11) DEFAULT NULL,
  `ref_qing_id` int(11) DEFAULT NULL,
  `op` varchar(255) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `option_id` int(11) DEFAULT NULL,
  `is_standard` tinyint(1) DEFAULT '0',
  `standard_id` int(11) DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_conditions_on_mission_id_and_standard_id` (`mission_id`,`standard_id`),
  KEY `conditions_option_id_fk` (`option_id`),
  KEY `conditions_questioning_id_fk` (`questioning_id`),
  KEY `conditions_ref_qing_id_fk` (`ref_qing_id`),
  KEY `index_conditions_on_standard_id` (`standard_id`),
  CONSTRAINT `conditions_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `conditions_option_id_fk` FOREIGN KEY (`option_id`) REFERENCES `options` (`id`),
  CONSTRAINT `conditions_questioning_id_fk` FOREIGN KEY (`questioning_id`) REFERENCES `questionings` (`id`),
  CONSTRAINT `conditions_ref_qing_id_fk` FOREIGN KEY (`ref_qing_id`) REFERENCES `questionings` (`id`),
  CONSTRAINT `conditions_standard_id_fk` FOREIGN KEY (`standard_id`) REFERENCES `conditions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8;

CREATE TABLE `form_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `form_id` int(11) DEFAULT NULL,
  `sequence` int(11) DEFAULT '1',
  `code` varchar(255) DEFAULT NULL,
  `is_current` tinyint(1) DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_form_versions_on_code` (`code`),
  KEY `form_versions_form_id_fk` (`form_id`),
  CONSTRAINT `form_versions_form_id_fk` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=334 DEFAULT CHARSET=utf8;

CREATE TABLE `forms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `published` tinyint(1) DEFAULT '0',
  `downloads` int(11) DEFAULT NULL,
  `responses_count` int(11) DEFAULT '0',
  `mission_id` int(11) DEFAULT NULL,
  `current_version_id` int(11) DEFAULT NULL,
  `upgrade_needed` tinyint(1) DEFAULT '0',
  `smsable` tinyint(1) DEFAULT '0',
  `is_standard` tinyint(1) DEFAULT '0',
  `standard_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_forms_on_mission_id_and_standard_id` (`mission_id`,`standard_id`),
  UNIQUE KEY `index_forms_on_mission_id_and_name` (`mission_id`,`name`),
  KEY `index_forms_on_standard_id` (`standard_id`),
  KEY `forms_current_version_id_fk` (`current_version_id`),
  CONSTRAINT `forms_current_version_id_fk` FOREIGN KEY (`current_version_id`) REFERENCES `form_versions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `forms_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `forms_standard_id_fk` FOREIGN KEY (`standard_id`) REFERENCES `forms` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=357 DEFAULT CHARSET=utf8;

CREATE TABLE `missions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `compact_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `locked` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_missions_on_compact_name` (`compact_name`)
) ENGINE=InnoDB AUTO_INCREMENT=495 DEFAULT CHARSET=latin1;

CREATE TABLE `option_sets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  `is_standard` tinyint(1) DEFAULT '0',
  `standard_id` int(11) DEFAULT NULL,
  `geographic` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_option_sets_on_mission_id_and_standard_id` (`mission_id`,`standard_id`),
  UNIQUE KEY `index_option_sets_on_mission_id_and_name` (`mission_id`,`name`),
  KEY `index_option_sets_on_standard_id` (`standard_id`),
  KEY `index_option_sets_on_geographic` (`geographic`),
  CONSTRAINT `option_sets_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `option_sets_standard_id_fk` FOREIGN KEY (`standard_id`) REFERENCES `option_sets` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=88 DEFAULT CHARSET=utf8;

CREATE TABLE `optionings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `option_set_id` int(11) DEFAULT NULL,
  `option_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `rank` int(11) DEFAULT NULL,
  `is_standard` tinyint(1) DEFAULT '0',
  `standard_id` int(11) DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_optionings_on_mission_id_and_standard_id` (`mission_id`,`standard_id`),
  KEY `optionings_option_id_fk` (`option_id`),
  KEY `optionings_option_set_id_fk` (`option_set_id`),
  KEY `index_optionings_on_standard_id` (`standard_id`),
  CONSTRAINT `optionings_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `optionings_option_id_fk` FOREIGN KEY (`option_id`) REFERENCES `options` (`id`),
  CONSTRAINT `optionings_option_set_id_fk` FOREIGN KEY (`option_set_id`) REFERENCES `option_sets` (`id`),
  CONSTRAINT `optionings_standard_id_fk` FOREIGN KEY (`standard_id`) REFERENCES `optionings` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=225 DEFAULT CHARSET=utf8;

CREATE TABLE `options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  `_name` varchar(255) DEFAULT NULL,
  `_hint` text,
  `name_translations` text,
  `hint_translations` text,
  `is_standard` tinyint(1) DEFAULT '0',
  `standard_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_options_on_mission_id_and_standard_id` (`mission_id`,`standard_id`),
  KEY `index_options_on_standard_id` (`standard_id`),
  CONSTRAINT `options_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `options_standard_id_fk` FOREIGN KEY (`standard_id`) REFERENCES `options` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=229 DEFAULT CHARSET=utf8;

CREATE TABLE `questionings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question_id` int(11) DEFAULT NULL,
  `form_id` int(11) DEFAULT NULL,
  `rank` int(11) DEFAULT NULL,
  `required` tinyint(1) DEFAULT '0',
  `hidden` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_standard` tinyint(1) DEFAULT '0',
  `standard_id` int(11) DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_questionings_on_mission_id_and_standard_id` (`mission_id`,`standard_id`),
  KEY `questionings_form_id_fk` (`form_id`),
  KEY `questionings_question_id_fk` (`question_id`),
  KEY `index_questionings_on_standard_id` (`standard_id`),
  CONSTRAINT `questionings_form_id_fk` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`),
  CONSTRAINT `questionings_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `questionings_question_id_fk` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`),
  CONSTRAINT `questionings_standard_id_fk` FOREIGN KEY (`standard_id`) REFERENCES `questionings` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=629 DEFAULT CHARSET=utf8;

CREATE TABLE `questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(255) DEFAULT NULL,
  `option_set_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `minimum` int(11) DEFAULT NULL,
  `maximum` int(11) DEFAULT NULL,
  `maxstrictly` tinyint(1) DEFAULT NULL,
  `minstrictly` tinyint(1) DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  `qtype_name` varchar(255) DEFAULT NULL,
  `_name` text,
  `_hint` text,
  `name_translations` text,
  `hint_translations` text,
  `key` tinyint(1) DEFAULT '0',
  `is_standard` tinyint(1) DEFAULT '0',
  `standard_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_questions_on_mission_id_and_standard_id` (`mission_id`,`standard_id`),
  UNIQUE KEY `index_questions_on_mission_id_and_code` (`mission_id`,`code`),
  KEY `index_questions_on_qtype_name` (`qtype_name`),
  KEY `questions_option_set_id_fk` (`option_set_id`),
  KEY `index_questions_on_standard_id` (`standard_id`),
  CONSTRAINT `questions_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `questions_option_set_id_fk` FOREIGN KEY (`option_set_id`) REFERENCES `option_sets` (`id`),
  CONSTRAINT `questions_standard_id_fk` FOREIGN KEY (`standard_id`) REFERENCES `questions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=651 DEFAULT CHARSET=utf8;

CREATE TABLE `report_calculations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) DEFAULT NULL,
  `report_report_id` int(11) DEFAULT NULL,
  `question1_id` int(11) DEFAULT NULL,
  `attrib1_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `rank` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `report_calculations_question1_id_fk` (`question1_id`),
  KEY `report_calculations_report_report_id_fk` (`report_report_id`),
  CONSTRAINT `report_calculations_question1_id_fk` FOREIGN KEY (`question1_id`) REFERENCES `questions` (`id`),
  CONSTRAINT `report_calculations_report_report_id_fk` FOREIGN KEY (`report_report_id`) REFERENCES `report_reports` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `report_option_set_choices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_report_id` int(11) DEFAULT NULL,
  `option_set_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `report_option_set_choices_option_set_id_fk` (`option_set_id`),
  KEY `report_option_set_choices_report_report_id_fk` (`report_report_id`),
  CONSTRAINT `report_option_set_choices_option_set_id_fk` FOREIGN KEY (`option_set_id`) REFERENCES `option_sets` (`id`),
  CONSTRAINT `report_option_set_choices_report_report_id_fk` FOREIGN KEY (`report_report_id`) REFERENCES `report_reports` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `report_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mission_id` int(11) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `option_set_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `viewed_at` datetime DEFAULT NULL,
  `view_count` int(11) DEFAULT '0',
  `display_type` varchar(255) DEFAULT 'table',
  `bar_style` varchar(255) DEFAULT 'side_by_side',
  `unreviewed` tinyint(1) DEFAULT '0',
  `question_labels` varchar(255) DEFAULT 'title',
  `percent_type` varchar(255) DEFAULT 'none',
  `unique_rows` tinyint(1) DEFAULT '0',
  `aggregation_name` varchar(255) DEFAULT NULL,
  `form_id` int(11) DEFAULT NULL,
  `question_order` varchar(255) NOT NULL DEFAULT 'number',
  `text_responses` varchar(255) DEFAULT 'all',
  `disagg_qing_id` int(11) DEFAULT NULL,
  `filter` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_report_reports_on_view_count` (`view_count`),
  KEY `report_reports_mission_id_fk` (`mission_id`),
  KEY `report_reports_form_id_fk` (`form_id`),
  KEY `report_reports_disagg_qing_id_fk` (`disagg_qing_id`),
  CONSTRAINT `report_reports_disagg_qing_id_fk` FOREIGN KEY (`disagg_qing_id`) REFERENCES `questionings` (`id`),
  CONSTRAINT `report_reports_form_id_fk` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`),
  CONSTRAINT `report_reports_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `responses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `form_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `reviewed` tinyint(1) DEFAULT '0',
  `source` varchar(255) DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  `incomplete` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_responses_on_created_at` (`created_at`),
  KEY `index_responses_on_updated_at` (`updated_at`),
  KEY `index_responses_on_reviewed` (`reviewed`),
  KEY `responses_form_id_fk` (`form_id`),
  KEY `responses_mission_id_fk` (`mission_id`),
  KEY `responses_user_id_fk` (`user_id`),
  CONSTRAINT `responses_form_id_fk` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`),
  CONSTRAINT `responses_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`),
  CONSTRAINT `responses_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=125 DEFAULT CHARSET=utf8;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) NOT NULL,
  `data` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8;

CREATE TABLE `settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `timezone` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `mission_id` int(11) DEFAULT NULL,
  `outgoing_sms_adapter` varchar(255) DEFAULT NULL,
  `intellisms_username` varchar(255) DEFAULT NULL,
  `intellisms_password` varchar(255) DEFAULT NULL,
  `isms_hostname` varchar(255) DEFAULT NULL,
  `isms_username` varchar(255) DEFAULT NULL,
  `isms_password` varchar(255) DEFAULT NULL,
  `incoming_sms_number` varchar(255) DEFAULT NULL,
  `preferred_locales` varchar(255) DEFAULT NULL,
  `override_code` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `settings_mission_id_fk` (`mission_id`),
  CONSTRAINT `settings_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=506 DEFAULT CHARSET=utf8;

CREATE TABLE `sms_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `direction` varchar(255) DEFAULT NULL,
  `to` text,
  `from` varchar(255) DEFAULT NULL,
  `body` text,
  `sent_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `mission_id` int(11) DEFAULT NULL,
  `adapter_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sms_messages_on_body` (`body`(160)),
  KEY `sms_messages_mission_id_fk` (`mission_id`),
  CONSTRAINT `sms_messages_mission_id_fk` FOREIGN KEY (`mission_id`) REFERENCES `missions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=113 DEFAULT CHARSET=utf8;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `password_salt` varchar(255) DEFAULT NULL,
  `crypted_password` varchar(255) DEFAULT NULL,
  `single_access_token` varchar(255) DEFAULT NULL,
  `perishable_token` varchar(255) DEFAULT NULL,
  `persistence_token` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `login_count` int(11) DEFAULT '0',
  `notes` text,
  `last_request_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `phone2` varchar(255) DEFAULT NULL,
  `admin` tinyint(1) DEFAULT NULL,
  `current_mission_id` int(11) DEFAULT NULL,
  `pref_lang` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_login` (`login`),
  KEY `users_current_mission_id_fk` (`current_mission_id`),
  CONSTRAINT `users_current_mission_id_fk` FOREIGN KEY (`current_mission_id`) REFERENCES `missions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=291 DEFAULT CHARSET=utf8;

INSERT INTO schema_migrations (version) VALUES ('20110602191123');

INSERT INTO schema_migrations (version) VALUES ('20110602191155');

INSERT INTO schema_migrations (version) VALUES ('20110602191220');

INSERT INTO schema_migrations (version) VALUES ('20110621231556');

INSERT INTO schema_migrations (version) VALUES ('20110621231721');

INSERT INTO schema_migrations (version) VALUES ('20110622182016');

INSERT INTO schema_migrations (version) VALUES ('20110623183148');

INSERT INTO schema_migrations (version) VALUES ('20110623193938');

INSERT INTO schema_migrations (version) VALUES ('20110624133714');

INSERT INTO schema_migrations (version) VALUES ('20110629190738');

INSERT INTO schema_migrations (version) VALUES ('20110629190744');

INSERT INTO schema_migrations (version) VALUES ('20110629190749');

INSERT INTO schema_migrations (version) VALUES ('20110629190755');

INSERT INTO schema_migrations (version) VALUES ('20110629190801');

INSERT INTO schema_migrations (version) VALUES ('20110629190806');

INSERT INTO schema_migrations (version) VALUES ('20110629190812');

INSERT INTO schema_migrations (version) VALUES ('20110629190817');

INSERT INTO schema_migrations (version) VALUES ('20110629190823');

INSERT INTO schema_migrations (version) VALUES ('20110629190829');

INSERT INTO schema_migrations (version) VALUES ('20110629190834');

INSERT INTO schema_migrations (version) VALUES ('20110630141414');

INSERT INTO schema_migrations (version) VALUES ('20110630154332');

INSERT INTO schema_migrations (version) VALUES ('20110630160747');

INSERT INTO schema_migrations (version) VALUES ('20110630195026');

INSERT INTO schema_migrations (version) VALUES ('20110713165635');

INSERT INTO schema_migrations (version) VALUES ('20110713174932');

INSERT INTO schema_migrations (version) VALUES ('20110713185801');

INSERT INTO schema_migrations (version) VALUES ('20110713211903');

INSERT INTO schema_migrations (version) VALUES ('20110719191108');

INSERT INTO schema_migrations (version) VALUES ('20110720164304');

INSERT INTO schema_migrations (version) VALUES ('20110721204754');

INSERT INTO schema_migrations (version) VALUES ('20110722194551');

INSERT INTO schema_migrations (version) VALUES ('20110722194603');

INSERT INTO schema_migrations (version) VALUES ('20110722200238');

INSERT INTO schema_migrations (version) VALUES ('20110722205622');

INSERT INTO schema_migrations (version) VALUES ('20110726143633');

INSERT INTO schema_migrations (version) VALUES ('20110726144308');

INSERT INTO schema_migrations (version) VALUES ('20110726185552');

INSERT INTO schema_migrations (version) VALUES ('20110810133630');

INSERT INTO schema_migrations (version) VALUES ('20110810134344');

INSERT INTO schema_migrations (version) VALUES ('20110811154224');

INSERT INTO schema_migrations (version) VALUES ('20110814182130');

INSERT INTO schema_migrations (version) VALUES ('20110814185101');

INSERT INTO schema_migrations (version) VALUES ('20110815174137');

INSERT INTO schema_migrations (version) VALUES ('20110815193346');

INSERT INTO schema_migrations (version) VALUES ('20110816185426');

INSERT INTO schema_migrations (version) VALUES ('20110817175237');

INSERT INTO schema_migrations (version) VALUES ('20110817183704');

INSERT INTO schema_migrations (version) VALUES ('20110817184219');

INSERT INTO schema_migrations (version) VALUES ('20110823170400');

INSERT INTO schema_migrations (version) VALUES ('20110823171727');

INSERT INTO schema_migrations (version) VALUES ('20110901141457');

INSERT INTO schema_migrations (version) VALUES ('20110901175612');

INSERT INTO schema_migrations (version) VALUES ('20110908165935');

INSERT INTO schema_migrations (version) VALUES ('20110908195844');

INSERT INTO schema_migrations (version) VALUES ('20110908211409');

INSERT INTO schema_migrations (version) VALUES ('20110913142741');

INSERT INTO schema_migrations (version) VALUES ('20110913143939');

INSERT INTO schema_migrations (version) VALUES ('20110913162231');

INSERT INTO schema_migrations (version) VALUES ('20110913202244');

INSERT INTO schema_migrations (version) VALUES ('20110914144631');

INSERT INTO schema_migrations (version) VALUES ('20110922181111');

INSERT INTO schema_migrations (version) VALUES ('20110923004101');

INSERT INTO schema_migrations (version) VALUES ('20111006155632');

INSERT INTO schema_migrations (version) VALUES ('20111006160017');

INSERT INTO schema_migrations (version) VALUES ('20111103141618');

INSERT INTO schema_migrations (version) VALUES ('20111103152358');

INSERT INTO schema_migrations (version) VALUES ('20111103153031');

INSERT INTO schema_migrations (version) VALUES ('20111122190536');

INSERT INTO schema_migrations (version) VALUES ('20120110163524');

INSERT INTO schema_migrations (version) VALUES ('20120110163624');

INSERT INTO schema_migrations (version) VALUES ('20120110163625');

INSERT INTO schema_migrations (version) VALUES ('20120110163724');

INSERT INTO schema_migrations (version) VALUES ('20120110163922');

INSERT INTO schema_migrations (version) VALUES ('20120110163943');

INSERT INTO schema_migrations (version) VALUES ('20120110164008');

INSERT INTO schema_migrations (version) VALUES ('20120117191616');

INSERT INTO schema_migrations (version) VALUES ('20120131161053');

INSERT INTO schema_migrations (version) VALUES ('20120131202355');

INSERT INTO schema_migrations (version) VALUES ('20120131202427');

INSERT INTO schema_migrations (version) VALUES ('20120203164645');

INSERT INTO schema_migrations (version) VALUES ('20120221210027');

INSERT INTO schema_migrations (version) VALUES ('20120223201044');

INSERT INTO schema_migrations (version) VALUES ('20120223205639');

INSERT INTO schema_migrations (version) VALUES ('20120320153040');

INSERT INTO schema_migrations (version) VALUES ('20120321155330');

INSERT INTO schema_migrations (version) VALUES ('20120322151536');

INSERT INTO schema_migrations (version) VALUES ('20120322173538');

INSERT INTO schema_migrations (version) VALUES ('20120322175333');

INSERT INTO schema_migrations (version) VALUES ('20120322180750');

INSERT INTO schema_migrations (version) VALUES ('20120413151514');

INSERT INTO schema_migrations (version) VALUES ('20120426154100');

INSERT INTO schema_migrations (version) VALUES ('20120426182952');

INSERT INTO schema_migrations (version) VALUES ('20120519202915');

INSERT INTO schema_migrations (version) VALUES ('20120521191051');

INSERT INTO schema_migrations (version) VALUES ('20120521192411');

INSERT INTO schema_migrations (version) VALUES ('20120521221511');

INSERT INTO schema_migrations (version) VALUES ('20120626184028');

INSERT INTO schema_migrations (version) VALUES ('20120629210925');

INSERT INTO schema_migrations (version) VALUES ('20120702172029');

INSERT INTO schema_migrations (version) VALUES ('20120706180000');

INSERT INTO schema_migrations (version) VALUES ('20120706183000');

INSERT INTO schema_migrations (version) VALUES ('20120706184000');

INSERT INTO schema_migrations (version) VALUES ('20120706193519');

INSERT INTO schema_migrations (version) VALUES ('20120706201054');

INSERT INTO schema_migrations (version) VALUES ('20120717162456');

INSERT INTO schema_migrations (version) VALUES ('20120717182055');

INSERT INTO schema_migrations (version) VALUES ('20120813180144');

INSERT INTO schema_migrations (version) VALUES ('20120820145220');

INSERT INTO schema_migrations (version) VALUES ('20120820165013');

INSERT INTO schema_migrations (version) VALUES ('20120820181620');

INSERT INTO schema_migrations (version) VALUES ('20120820181749');

INSERT INTO schema_migrations (version) VALUES ('20120820181944');

INSERT INTO schema_migrations (version) VALUES ('20120820182538');

INSERT INTO schema_migrations (version) VALUES ('20120820193330');

INSERT INTO schema_migrations (version) VALUES ('20120822152209');

INSERT INTO schema_migrations (version) VALUES ('20120822161441');

INSERT INTO schema_migrations (version) VALUES ('20120906150610');

INSERT INTO schema_migrations (version) VALUES ('20120906155118');

INSERT INTO schema_migrations (version) VALUES ('20120906170242');

INSERT INTO schema_migrations (version) VALUES ('20120906183249');

INSERT INTO schema_migrations (version) VALUES ('20120906184149');

INSERT INTO schema_migrations (version) VALUES ('20120925145245');

INSERT INTO schema_migrations (version) VALUES ('20121008152421');

INSERT INTO schema_migrations (version) VALUES ('20121008153636');

INSERT INTO schema_migrations (version) VALUES ('20121015163120');

INSERT INTO schema_migrations (version) VALUES ('20121015164830');

INSERT INTO schema_migrations (version) VALUES ('20121018182218');

INSERT INTO schema_migrations (version) VALUES ('20121018183850');

INSERT INTO schema_migrations (version) VALUES ('20121018184503');

INSERT INTO schema_migrations (version) VALUES ('20121022153208');

INSERT INTO schema_migrations (version) VALUES ('20121112143155');

INSERT INTO schema_migrations (version) VALUES ('20121112143800');

INSERT INTO schema_migrations (version) VALUES ('20121112174623');

INSERT INTO schema_migrations (version) VALUES ('20121126153456');

INSERT INTO schema_migrations (version) VALUES ('20121230200218');

INSERT INTO schema_migrations (version) VALUES ('20130213223146');

INSERT INTO schema_migrations (version) VALUES ('20130214013213');

INSERT INTO schema_migrations (version) VALUES ('20130214040034');

INSERT INTO schema_migrations (version) VALUES ('20130217133401');

INSERT INTO schema_migrations (version) VALUES ('20130217153912');

INSERT INTO schema_migrations (version) VALUES ('20130226161010');

INSERT INTO schema_migrations (version) VALUES ('20130226161123');

INSERT INTO schema_migrations (version) VALUES ('20130421174728');

INSERT INTO schema_migrations (version) VALUES ('20130421181048');

INSERT INTO schema_migrations (version) VALUES ('20130421182318');

INSERT INTO schema_migrations (version) VALUES ('20130423154043');

INSERT INTO schema_migrations (version) VALUES ('20130423192101');

INSERT INTO schema_migrations (version) VALUES ('20130423194832');

INSERT INTO schema_migrations (version) VALUES ('20130425153308');

INSERT INTO schema_migrations (version) VALUES ('20130428154325');

INSERT INTO schema_migrations (version) VALUES ('20130430125200');

INSERT INTO schema_migrations (version) VALUES ('20130430135749');

INSERT INTO schema_migrations (version) VALUES ('20130515183455');

INSERT INTO schema_migrations (version) VALUES ('20130522230727');

INSERT INTO schema_migrations (version) VALUES ('20130523135556');

INSERT INTO schema_migrations (version) VALUES ('20130523140659');

INSERT INTO schema_migrations (version) VALUES ('20130523143757');

INSERT INTO schema_migrations (version) VALUES ('20130603201712');

INSERT INTO schema_migrations (version) VALUES ('20130605144308');

INSERT INTO schema_migrations (version) VALUES ('20130605152216');

INSERT INTO schema_migrations (version) VALUES ('20130607135946');

INSERT INTO schema_migrations (version) VALUES ('20130613215128');

INSERT INTO schema_migrations (version) VALUES ('20130613225417');

INSERT INTO schema_migrations (version) VALUES ('20130710122835');

INSERT INTO schema_migrations (version) VALUES ('20130711201117');

INSERT INTO schema_migrations (version) VALUES ('20130711201223');

INSERT INTO schema_migrations (version) VALUES ('20130712183705');

INSERT INTO schema_migrations (version) VALUES ('20130719142702');

INSERT INTO schema_migrations (version) VALUES ('20130724212350');

INSERT INTO schema_migrations (version) VALUES ('20130730144254');

INSERT INTO schema_migrations (version) VALUES ('20130730185504');

INSERT INTO schema_migrations (version) VALUES ('20130801185708');

INSERT INTO schema_migrations (version) VALUES ('20130801185904');

INSERT INTO schema_migrations (version) VALUES ('20130806132009');

INSERT INTO schema_migrations (version) VALUES ('20130812145656');

INSERT INTO schema_migrations (version) VALUES ('20130819152914');

INSERT INTO schema_migrations (version) VALUES ('20130819154559');

INSERT INTO schema_migrations (version) VALUES ('20130819154806');

INSERT INTO schema_migrations (version) VALUES ('20130820002104');

INSERT INTO schema_migrations (version) VALUES ('20130820002405');

INSERT INTO schema_migrations (version) VALUES ('20130829005907');

INSERT INTO schema_migrations (version) VALUES ('20130829009920');

INSERT INTO schema_migrations (version) VALUES ('20130829010537');

INSERT INTO schema_migrations (version) VALUES ('20130912153204');

INSERT INTO schema_migrations (version) VALUES ('20130918173729');

INSERT INTO schema_migrations (version) VALUES ('20130918180627');

INSERT INTO schema_migrations (version) VALUES ('20130918185359');

INSERT INTO schema_migrations (version) VALUES ('20130927122240');

INSERT INTO schema_migrations (version) VALUES ('20130927135358');

INSERT INTO schema_migrations (version) VALUES ('20130927135359');

INSERT INTO schema_migrations (version) VALUES ('20131009183730');

INSERT INTO schema_migrations (version) VALUES ('20131011121258');

INSERT INTO schema_migrations (version) VALUES ('20131011154737');

INSERT INTO schema_migrations (version) VALUES ('20131025142216');

INSERT INTO schema_migrations (version) VALUES ('20131025174451');

INSERT INTO schema_migrations (version) VALUES ('20131025203530');

INSERT INTO schema_migrations (version) VALUES ('20131029133657');

INSERT INTO schema_migrations (version) VALUES ('20131029140847');

INSERT INTO schema_migrations (version) VALUES ('20131112194557');

INSERT INTO schema_migrations (version) VALUES ('20131112202048');

INSERT INTO schema_migrations (version) VALUES ('20131120165641');

INSERT INTO schema_migrations (version) VALUES ('20131120173227');

INSERT INTO schema_migrations (version) VALUES ('20131120175045');

INSERT INTO schema_migrations (version) VALUES ('20131209182701');

INSERT INTO schema_migrations (version) VALUES ('20131213165632');

INSERT INTO schema_migrations (version) VALUES ('20131231191215');

INSERT INTO schema_migrations (version) VALUES ('20140102194829');

INSERT INTO schema_migrations (version) VALUES ('20140102200507');