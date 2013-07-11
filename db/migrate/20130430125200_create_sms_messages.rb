class CreateSmsMessages < ActiveRecord::Migration
  def change
    create_table :sms_messages do |t|
      t.string :direction
      t.text :to
      t.string :from
      t.text :body
      t.datetime :sent_at

      t.timestamps
    end
  end
end
