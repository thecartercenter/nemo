# frozen_string_literal: true

class AddOptionNameTranslationsIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :options, :name_translations, using: :gin
  end
end
