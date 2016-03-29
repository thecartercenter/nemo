class AddSmsGuideFormattingToOptionSet < ActiveRecord::Migration
  def change
    add_column :option_sets, :sms_guide_formatting, :string, null: false, default: "auto"
  end
end
