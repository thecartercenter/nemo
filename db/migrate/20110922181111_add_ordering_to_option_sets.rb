class AddOrderingToOptionSets < ActiveRecord::Migration
  def self.up
    add_column :option_sets, :ordering, :string
  end

  def self.down
    remove_column :option_sets, :ordering
  end
end
