class CreateOptionSets < ActiveRecord::Migration
  def self.up
    create_table :option_sets do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :option_sets
  end
end
