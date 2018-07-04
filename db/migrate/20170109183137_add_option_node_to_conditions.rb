class AddOptionNodeToConditions < ActiveRecord::Migration[4.2]
  def change
    add_reference :conditions, :option_node, index: true, foreign_key: true
  end
end
