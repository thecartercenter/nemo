class RenameOptionSetNameWhereDuplicates < ActiveRecord::Migration[6.1]
  def up
    OptionSet.rename_duplicates!
  end
end
