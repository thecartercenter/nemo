class CreateForms < ActiveRecord::Migration[4.2]
  def self.up
    create_table :forms do |t|
      t.string :name
      t.boolean :is_published
      t.integer :form_type_id

      t.timestamps
    end
  end

  def self.down
    drop_table :forms
  end
end
