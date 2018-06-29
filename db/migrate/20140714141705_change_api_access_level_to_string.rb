class ChangeAPIAccessLevelToString < ActiveRecord::Migration[4.2]
  def up
    # First set all nulls to private/inherit
    execute("UPDATE forms SET access_level = 1 WHERE access_level IS NULL")
    execute("UPDATE questionables SET access_level = 2 WHERE access_level IS NULL")

    # Alter
    change_column :forms, :access_level, :string, :null => false, :default => 'private' # private
    change_column :questionables, :access_level, :string, :null => false, :default => 'inherit'

    # Now convert to string values
    execute("UPDATE forms SET access_level = 'private' WHERE access_level = '1'")
    execute("UPDATE forms SET access_level = 'public' WHERE access_level = '2'")
    execute("UPDATE forms SET access_level = 'protected' WHERE access_level = '3'")
    execute("UPDATE questionables SET access_level = 'private' WHERE access_level = '1'")
    execute("UPDATE questionables SET access_level = 'inherit' WHERE access_level = '2'")
  end

  def down
  end
end
