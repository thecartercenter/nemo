class MigrateSmsMessageData < ActiveRecord::Migration
  def up
    Sms::Message.all.each do |msg|
      if msg.direction == 'incoming' || (msg.to.in? [nil, 'null'])
        msg.type = 'Sms::Incoming'
        msg.to = nil
        msg.user_id = find_user_id(msg.from)
      elsif msg.direction == 'outgoing' || (msg.from.in? [nil, 'null'])
        if msg.to.try(:size) > 1
          msg.type = 'Sms::Broadcast'
          msg.to = nil
        else
          msg.type = 'Sms::Reply'
          msg.to = msg.to.first if msg.to.is_a? Array
          msg.user_id = find_user_id(msg.to)
        end
        msg.from = nil
      else
        raise "Unable to set type for message id #{msg.id}"
      end
      msg.save
    end

    remove_column :sms_messages, :direction
    change_column :sms_messages, :to, :string
  end

  def down
    add_column :sms_messages, :direction, :string
    change_column :sms_messages, :to, :text

    Sms::Message.all.each do |msg|
      if msg.type == 'Sms::Incoming'
        msg.direction = 'incoming'
      elsif msg.type.in? %w(Sms::Broadcast Sms::Reply)
        msg.direction = 'outgoing'
        msg.to = [msg.to]
      else
        raise "Unable to read type for message id #{msg.id}"
      end
      msg.type = msg.user_id = ''
      msg.save
    end
  end

  def find_user_id(phone)
    User.where('phone = ? OR phone2 = ?', phone, phone).first.try :id
  end
end
