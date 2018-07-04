class CreateConditions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :conditions do |t|
      t.integer :questioning_id
      t.integer :ref_qing_id
      t.string :op
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :conditions
  end
end
