class AddPrefLangToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :pref_lang, :string

    # set all existing users to english
    User.update_all("pref_lang = 'en'")
  end

  def down
    remove_column :users, :pref_lang
  end
end
