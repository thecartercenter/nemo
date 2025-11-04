class DropFoosTable < ActiveRecord::Migration[4.2]
  def up
    # some old test table that managed to hang around

    drop_table :foos
  rescue StandardError
    nil
  end

  def down
  end
end
