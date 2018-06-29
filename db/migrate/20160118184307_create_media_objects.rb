class CreateMediaObjects < ActiveRecord::Migration[4.2]
  def change
    create_table :media_objects do |t|
      t.references :answer, index: true, foreign_key: true
      t.string :type

      t.timestamps null: false
    end
  end
end
