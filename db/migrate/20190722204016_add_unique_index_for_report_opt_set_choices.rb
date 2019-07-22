# frozen_string_literal: true

class AddUniqueIndexForReportOptSetChoices < ActiveRecord::Migration[5.2]
  def change
    add_index :report_option_set_choices, %i[option_set_id report_report_id],
      unique: true, name: "report_option_set_choice_unique"
  end
end
