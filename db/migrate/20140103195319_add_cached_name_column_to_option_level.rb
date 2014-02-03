class AddCachedNameColumnToOptionLevel < ActiveRecord::Migration
  def change
    add_column :option_levels, :_name, :string
  end
end
