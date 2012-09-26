class RemoveLanguageFromUsers < ActiveRecord::Migration
  def up
    remove_column(:users, :language_id)
  end

  def down
  end
end
