class CreateNewReportReports < ActiveRecord::Migration[4.2]
  def up
    create_table :report_reports do |t|
      t.integer  "mission_id"
      t.string   "type"
      t.string   "name"
      t.boolean  "saved",               :default => false
      t.integer  "filter_id"
      t.integer  "grouping1_id"
      t.integer  "grouping2_id"
      t.integer  "aggregation_id"
      t.string   "omnibus_calculation"
      t.integer  "option_set_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "viewed_at"
      t.integer  "view_count",          :default => 0
      t.string   "display_type",        :default => "Table"
      t.string   "bar_style",           :default => "Side By Side"
      t.boolean  "unreviewed",          :default => false
      t.string   "question_labels",      :default => "Code"
      t.boolean  "show_question_labels", :default => true
      t.string   "percent_type"
      t.boolean  "unique_rows"

      t.timestamps
    end
  end

  def down
    drop_table :report_reports
  end
end
