class AddSmsGuideFormattingToOptionSet < ActiveRecord::Migration[4.2]
  def change
    add_column :option_sets, :sms_guide_formatting, :string, null: false, default: "auto"
  end
end
