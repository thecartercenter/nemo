class CreateSmsResponses < ActiveRecord::Migration
  def change
    create_table :sms_responses do |t|
      t.string :message
      t.integer :response_id

      t.timestamps
    end
  end
end
