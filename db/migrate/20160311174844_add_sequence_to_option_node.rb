class AddSequenceToOptionNode < ActiveRecord::Migration[4.2]
  def change
    add_column :option_nodes, :sequence, :integer
  end
end
