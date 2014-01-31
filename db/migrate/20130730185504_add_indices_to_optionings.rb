class AddIndicesToOptionings < ActiveRecord::Migration
  def change
    add_index :optionings, [:option_set_id]
    add_index :optionings, [:option_id]
  end
end
