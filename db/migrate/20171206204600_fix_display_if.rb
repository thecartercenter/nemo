class FixDisplayIf < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE form_items SET display_if = 'always'")
    execute("UPDATE form_items SET display_if = 'all_met' WHERE EXISTS (
      SELECT * FROM conditions WHERE questioning_id = form_items.id AND deleted_at IS NULL)")
  end
end
