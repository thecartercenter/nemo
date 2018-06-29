class RemoveSettables < ActiveRecord::Migration[4.2]
  def up
    # add 'key' column to settings
    add_column(:settings, :key, :string)

    # copy settable keys to settings
    execute("UPDATE settings s, settables sb SET s.key = sb.key WHERE s.settable_id = sb.id")

    # remove settables table and settable_id col
    remove_column(:settings, :settable_id)
    drop_table(:settables)
  end

  def down
  end
end
