class CreateMediaObjects < ActiveRecord::Migration
  def change
    create_table :media_objects do |t|
      t.references :answer, index: true, foreign_key: true
      t.text :annotation
      t.string :type

      t.timestamps null: false
    end
  end
end
