class CreateReportOptionSetChoices < ActiveRecord::Migration[4.2]
  def change
    create_table :report_option_set_choices do |t|
      t.column :report_report_id, :integer
      t.column :option_set_id, :integer
    end

    add_index :report_option_set_choices, :report_report_id
    add_index :report_option_set_choices, :option_set_id
  end
end
