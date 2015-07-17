class AddTextTypeForSmsToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :text_type_for_sms, :boolean, null: false, default: false
  end
end
