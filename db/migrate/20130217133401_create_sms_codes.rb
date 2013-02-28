class CreateSmsCodes < ActiveRecord::Migration
  def change
    create_table :sms_codes do |t|
      t.string :code
      # TOM should have indices on these foreign keys. please read up on how to create indices in rails migrations. 
      # ditto for your other migrations.
      t.integer :questioning_id
      t.integer :option_id
      t.integer :form_id
      t.integer :question_number

      t.timestamps
    end
  end
end
