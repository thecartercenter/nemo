class AddOptionNodeToConditions < ActiveRecord::Migration
  def change
    add_reference :conditions, :option_node, index: true, foreign_key: true
  end
end
