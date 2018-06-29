class RenameSettingLanguagesToPreferredLocales < ActiveRecord::Migration[4.2]
  def up
    add_column :settings, :preferred_locales, :string

    # convert to array and serialize
    Setting.all.each do |s|
      s.preferred_locales = (s.languages || '').split(',')
      s.save(:validate => false)
    end

    remove_column :settings, :languages
  end

  def down

  end
end
