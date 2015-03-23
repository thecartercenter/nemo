class AddRankUniqueIndex < ActiveRecord::Migration
  def up
    add_index :form_items, [:ancestry, :rank], unique: true
  end

  def down
  end
end
