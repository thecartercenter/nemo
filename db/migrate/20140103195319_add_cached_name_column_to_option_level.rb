class AddCachedNameColumnToOptionLevel < ActiveRecord::Migration[4.2]
  def change
    add_column :option_levels, :_name, :string
  end
end
