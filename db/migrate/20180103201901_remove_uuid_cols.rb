class RemoveUuidCols < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Base.connection.tables.each do |table|
      remove_column table, "uuid" if column_exists?(table, "uuid")
    end
  end

  def down
    raise IrreversibleMigration
  end
end
