class CreateFormVersions < ActiveRecord::Migration[4.2]
  def change
    create_table :form_versions do |t|
      t.integer :form_id
      t.integer :sequence, :default => 1
      t.string :code
      t.boolean :is_current, :default => true

      t.timestamps
    end
    add_index :form_versions, :code, :unique => true
  end
end
