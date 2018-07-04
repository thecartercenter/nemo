class CreateTaggings < ActiveRecord::Migration[4.2]
  def change
    create_table :taggings do |t|
      t.references :question, null: false
      t.references :tag, null: false
      t.boolean :is_standard, default: false
      t.integer :standard_id

      t.timestamps
    end
    add_index :taggings, :question_id
    add_index :taggings, :tag_id
  end
end
