class CreateTranslations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :translations do |t|
      t.integer :language_id
      t.integer :question_id
      t.integer :option_id
      t.text :str

      t.timestamps
    end
  end

  def self.down
    drop_table :translations
  end
end
