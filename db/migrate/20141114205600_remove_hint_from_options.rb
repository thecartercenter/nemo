class RemoveHintFromOptions < ActiveRecord::Migration
  def up
    remove_column :options, :_hint
    remove_column :options, :hint_translations
  end

  def down
  end
end
