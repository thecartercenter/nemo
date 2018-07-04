class RemoveStandardColsFromFormVersion < ActiveRecord::Migration[4.2]
  def up
    # not sure why these got put on here. standard forms shouldn't even have versions as they never get published.
    remove_column :form_versions, :is_standard
    remove_column :form_versions, :standard_id
  end

  def down
  end
end
