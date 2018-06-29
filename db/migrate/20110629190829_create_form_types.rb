class CreateFormTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :form_types do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :form_types
  end
end
