class RenameNumericToInteger < ActiveRecord::Migration
  def self.up
    execute("update question_types set name = 'integer', long_name = 'Integer' where name = 'numeric'")
  end

  def self.down
  end
end
