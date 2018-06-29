class AddRankToOptionSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :optionings, :rank, :integer
  end
end
