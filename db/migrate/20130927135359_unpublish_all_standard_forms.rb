class UnpublishAllStandardForms < ActiveRecord::Migration
  def up
    # standard forms are now not publishable, so they should all be unpublished
    fixed = update("UPDATE forms SET published = 0 WHERE is_standard = 1 AND published = 1")
  end

  def down
  end
end
