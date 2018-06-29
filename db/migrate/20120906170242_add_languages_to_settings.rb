class AddLanguagesToSettings < ActiveRecord::Migration[4.2]
  def up
    add_column :settings, :languages, :string

    # setup defaults
    execute("UPDATE settings s SET s.languages = (SELECT GROUP_CONCAT(l.code) FROM languages l WHERE s.mission_id = l.mission_id GROUP BY l.mission_id)")
  end

  def down
    remove_column :settings, :languages
  end
end
