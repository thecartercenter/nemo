class RemoveHintFromOptions < ActiveRecord::Migration[4.2]
  def up
    remove_column :options, :_hint
    remove_column :options, :hint_translations
  end

  def down
  end
end
