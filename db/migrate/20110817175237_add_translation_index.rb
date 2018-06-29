class AddTranslationIndex < ActiveRecord::Migration[4.2]
  def self.up
    add_index(:translations, [:language_id, :class_name, :fld, :obj_id],
      :unique => true, :name => "translation_master")
  end

  def self.down
    remove_index(:translations, 'translation_master')
  end
end
