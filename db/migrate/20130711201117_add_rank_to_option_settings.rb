class AddRankToOptionSettings < ActiveRecord::Migration
  def change
    add_column :optionings, :rank, :integer
  end
end
