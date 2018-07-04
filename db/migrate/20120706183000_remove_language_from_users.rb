class RemoveLanguageFromUsers < ActiveRecord::Migration[4.2]
  def up
    remove_column(:users, :language_id)
  end

  def down
  end
end
