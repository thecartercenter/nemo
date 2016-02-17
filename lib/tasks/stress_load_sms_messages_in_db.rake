require 'task_helpers/stress_sms_helper'

# This task needs changes in order to be used for any form, mission, etc.
# It has a lot of hardcoded ids that were used to speed the implementation.
namespace :stress do
  desc "Loads incoming and outgoing SMSs on db with their respective form responses"
  task :load_sms_messages_in_db, [:quantity, :mission_id, :words_file] => [:environment] do |t, args|
    args.with_defaults(quantity: 1,
      mission_id: 24,
      words_file: 'lib/task_helpers/1k_random_words.txt')

    p args

    form_id = 321
    user_id = 1085

    StressSmsHelper.read_words_file args[:words_file]

    options_from_set = Hash.new
    [614, 596, 629, 627, 640].each do |option_set_id|
      options_from_set[option_set_id] = get_options_ids_for_option_set(option_set_id)
    end

    disable_db_checks

    (1..args[:quantity].to_i).each do |i|
      message_body = 'iad StressTesting-Responses were inserted directly on the db without sms decode.'

      ActiveRecord::Base.connection.insert "INSERT INTO `sms_messages` (`type`, `from`, `body`, `sent_at`, `adapter_name`, `mission_id`, `created_at`, `updated_at`, `user_id`) VALUES ('Sms::Incoming', '+553598765432', '#{message_body}', NOW(), 'TwilioTestStub', #{args[:mission_id]}, NOW(), NOW(), #{user_id})"

      response_id = ActiveRecord::Base.connection.insert "INSERT INTO `responses` (`user_id`, `form_id`, `source`, `mission_id`, `created_at`, `updated_at`) VALUES (#{user_id}, #{form_id}, 'sms', #{args[:mission_id]}, NOW(), NOW())"
      ActiveRecord::Base.connection.execute "UPDATE `forms` SET `responses_count` = COALESCE(`responses_count`, 0) + 1 WHERE `forms`.`id` = #{form_id}"

      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`value`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES ('#{StressSmsHelper.random_text}', 18282, #{response_id}, NOW(), NOW())"
      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`value`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES ('#{rand(1000000)}', 18284, #{response_id}, NOW(), NOW())"
      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`value`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES ('#{StressSmsHelper.random_text}', 18285, #{response_id}, NOW(), NOW())"
      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`value`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES ('#{rand(1000000)}', 18288, #{response_id}, NOW(), NOW())"
      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`value`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES ('#{StressSmsHelper.random_text}', 18290, #{response_id}, NOW(), NOW())"

      # Question: Stress1
      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`option_id`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES (#{options_from_set[614].sample}, 18281, #{response_id}, NOW(), NOW())"
      # Question: Stress3
      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`option_id`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES (#{options_from_set[596].sample}, 18283, #{response_id}, NOW(), NOW())"
      # Question: Stress6
      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`option_id`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES (#{options_from_set[629].sample}, 18286, #{response_id}, NOW(), NOW())"
      # Question: Stress9
      ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`option_id`, `questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES (#{options_from_set[640].sample}, 18289, #{response_id}, NOW(), NOW())"
      # Question: Stress7
      answer_id = ActiveRecord::Base.connection.insert "INSERT INTO `answers` (`questioning_id`, `response_id`, `created_at`, `updated_at`) VALUES (18287, #{response_id}, NOW(), NOW())"
      ActiveRecord::Base.connection.insert "INSERT INTO `choices` (`option_id`, `answer_id`, `created_at`, `updated_at`) VALUES (#{options_from_set[627].sample}, #{answer_id}, NOW(), NOW())"

      ActiveRecord::Base.connection.execute "UPDATE `responses` SET `responses`.`updated_at` = NOW() WHERE `responses`.`id` = #{response_id}"

      ActiveRecord::Base.connection.insert "INSERT INTO `sms_messages` (`type`, `to`, `body`, `mission_id`, `user_id`, `adapter_name`, `created_at`, `updated_at`, `sent_at`) VALUES ('Sms::Reply', '+553588567281', 'Your response to form \\'iad\\' was received. Thank you!', #{args[:mission_id]}, #{user_id}, 'TwilioTestStub', NOW(), NOW(), NOW())"
    end

    enable_db_checks
  end
end

def get_options_ids_for_option_set(option_sets_id)
  ActiveRecord::Base.connection.execute("SELECT `option_nodes`.option_id FROM `option_nodes`
    WHERE `option_nodes`.`ancestry` =
    (SELECT `option_sets`.root_node_id FROM `option_sets` WHERE `option_sets`.`id` = #{option_sets_id} LIMIT 1)
    ORDER BY rank").entries.flatten
end

def disable_db_checks
  ActiveRecord::Base.connection.execute "ALTER TABLE `sms_messages` DISABLE KEYS;"
  ActiveRecord::Base.connection.execute "ALTER TABLE `answers` DISABLE KEYS;"
  ActiveRecord::Base.connection.execute "ALTER TABLE `choices` DISABLE KEYS;"

  ActiveRecord::Base.connection.execute "SET FOREIGN_KEY_CHECKS = 0;"
  ActiveRecord::Base.connection.execute "SET UNIQUE_CHECKS = 0;"
  ActiveRecord::Base.connection.execute "SET AUTOCOMMIT = 0;"

end

def enable_db_checks
  ActiveRecord::Base.connection.execute "ALTER TABLE `sms_messages` ENABLE KEYS;"
  ActiveRecord::Base.connection.execute "ALTER TABLE `answers` ENABLE KEYS;"
  ActiveRecord::Base.connection.execute "ALTER TABLE `choices` ENABLE KEYS;"

  ActiveRecord::Base.connection.execute "SET UNIQUE_CHECKS = 1;"
  ActiveRecord::Base.connection.execute "SET FOREIGN_KEY_CHECKS = 1;"
  ActiveRecord::Base.connection.execute "COMMIT;"
end
