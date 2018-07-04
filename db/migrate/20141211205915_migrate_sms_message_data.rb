class MigrateSmsMessageData < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE sms_messages
      LEFT JOIN users u ON `from` IN (u.phone, u.phone2)
      SET `type` = 'Sms::Incoming',
        `to` = NULL,
        user_id = u.id
      WHERE `direction` = 'incoming'
        OR `to` IS NULL
        OR `to` = 'null';
    SQL
    execute <<-SQL
      UPDATE sms_messages
      SET `type` = IF(`to` LIKE '%,%', 'Sms::Broadcast', 'Sms::Reply'),
        `from` = NULL
      WHERE `direction` = 'outgoing'
        OR `from` IS NULL
        OR `from` = 'null';
    SQL
    execute <<-SQL
      UPDATE sms_messages
      SET `to` = NULL
      WHERE `type` = 'Sms::Broadcast';
    SQL
    execute <<-SQL
      UPDATE sms_messages
      SET `to` = SUBSTRING_INDEX(TRIM(LEADING '["' FROM `to`), '"', 1)
      WHERE `type` = 'Sms::Reply';
    SQL
    execute <<-SQL
      UPDATE sms_messages
      LEFT JOIN users u ON `to` IN (u.phone, u.phone2)
      SET user_id = u.id
      WHERE `type` = 'Sms::Reply';
    SQL

    remove_column :sms_messages, :direction
    change_column :sms_messages, :to, :string
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
