class AddOrderingToOptionSets < ActiveRecord::Migration[4.2]
  def self.up
    add_column :option_sets, :ordering, :string
  end

  def self.down
    remove_column :option_sets, :ordering
  end
end
