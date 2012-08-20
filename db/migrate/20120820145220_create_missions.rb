class CreateMissions < ActiveRecord::Migration
  def change
    create_table :missions do |t|
      t.string :name
      t.string :compact_name

      t.timestamps
    end
  end
end
