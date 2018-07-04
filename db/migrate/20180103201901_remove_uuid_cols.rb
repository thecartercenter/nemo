class RemoveUuidCols < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Base.connection.tables.each do |table|
      if column_exists?(table, "uuid")
        remove_column table, "uuid"
      end
    end
  end

  def down
    raise IrreversibleMigration
  end
end
