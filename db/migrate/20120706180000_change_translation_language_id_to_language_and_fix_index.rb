class ChangeTranslationLanguageIdToLanguageAndFixIndex < ActiveRecord::Migration[4.2]
  def up
    # remove old index
    remove_index(:translations, :name => "translation_master")

    # add the language column and populate it
    add_column(:translations, :language, :string)
    execute("UPDATE translations tr, languages l SET tr.language = l.code WHERE tr.language_id = l.id")

    # drop the language_id column
    remove_column(:translations, :language_id)

    # create a new index
    add_index(:translations, ["language", "class_name", "fld", "obj_id"], :name => "translation_master", :unique => true)
  end

  def down
  end
end
