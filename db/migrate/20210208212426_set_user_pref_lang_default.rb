# frozen_string_literal: true

class SetUserPrefLangDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :pref_lang, "en"
  end
end
