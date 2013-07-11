class AddRankToOptionSettings < ActiveRecord::Migration
  def change
    add_column :option_settings, :rank, :integer
  end
end
