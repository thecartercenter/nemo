class AddDeletedAtToSoftDeleteableTables < ActiveRecord::Migration[4.2]
  TABLES = %i(answers assignments choices conditions form_items form_versions forms media_objects missions
    option_nodes option_sets options questions report_calculations report_option_set_choices
    report_reports responses taggings tags user_group_assignments user_groups users)

  def change
    TABLES.each do |t|
      add_column t, :deleted_at, :datetime
      add_index t, :deleted_at
    end
  end
end
