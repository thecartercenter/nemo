class AddValueToOptions < ActiveRecord::Migration
  def change
    add_column :options, :value, :integer, null: true
  end
end
