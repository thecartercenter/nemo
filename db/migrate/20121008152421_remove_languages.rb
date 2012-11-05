class RemoveLanguages < ActiveRecord::Migration
  def up
    drop_table :languages
  end

  def down
  end
end
