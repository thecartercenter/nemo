class AddSequenceToOptionNode < ActiveRecord::Migration
  def change
    add_column :option_nodes, :sequence, :integer
  end
end
