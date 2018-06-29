class DropViews < ActiveRecord::Migration[4.2]
  def up
    execute("DROP VIEW _answers") rescue nil
  end

  def down
  end
end
