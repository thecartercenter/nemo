class CreateTags < ActiveRecord::Migration[4.2]
  def change
    create_table :tags do |t|
      t.string :name, limit: 64, null: false
      t.references :mission
      t.boolean :is_standard, default: false
      t.integer :standard_id

      t.timestamps
    end
    add_index :tags, :mission_id
  end
end
