class CreateMissions < ActiveRecord::Migration[4.2]
  def change
    create_table :missions do |t|
      t.string :name
      t.string :compact_name

      t.timestamps
    end
  end
end
