class ChangeStandardIdToOriginalIdAndAddStandardCopy < ActiveRecord::Migration
  def up
    [Form, Question, OptionSet].each do |klass|
      table = klass.table_name
      add_column table, :standard_copy, :boolean, null: false, default: false

      # At this point, standard copies have standard_ids.
      execute("UPDATE #{table} SET standard_copy = 1 WHERE standard_id IS NOT NULL")

      # If there is already an original_id column, we need to nuke it, but copy values first.
      if klass.column_names.include?('original_id')
        execute("UPDATE #{table} SET standard_id = original_id WHERE original_id IS NOT NULL")
        remove_column table, :original_id
      end

      # Now we can rename.
      rename_column table, :standard_id, :original_id
    end
  end

  def down
  end
end
