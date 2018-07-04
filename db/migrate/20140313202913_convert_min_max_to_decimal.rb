class ConvertMinMaxToDecimal < ActiveRecord::Migration[4.2]
  def up
    change_column :questionables, :minimum, :decimal, :precision => 15, :scale => 10
    change_column :questionables, :maximum, :decimal, :precision => 15, :scale => 10
  end

  def down
  end
end
