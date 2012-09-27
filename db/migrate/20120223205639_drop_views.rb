class DropViews < ActiveRecord::Migration
  def up
    execute("DROP VIEW _answers") rescue nil
  end

  def down
  end
end
