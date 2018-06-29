class RemoveLanguages < ActiveRecord::Migration[4.2]
  def up
    drop_table :languages
  end

  def down
  end
end
