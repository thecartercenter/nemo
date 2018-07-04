class ChangeTranslationsToPolymorphic < ActiveRecord::Migration[4.2]
  def self.up
    add_column(:translations, :class_name, :string)
    add_column(:translations, :object_id, :integer)
    add_column(:translations, :fld, :string)
    remove_column(:translations, :question_id)
    remove_column(:translations, :option_id)
    remove_column(:questions, :name)
    remove_column(:options, :name)
  end

  def self.down
  end
end
