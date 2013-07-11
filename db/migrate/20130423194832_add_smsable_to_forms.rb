class AddSmsableToForms < ActiveRecord::Migration
  def change
    add_column :forms, :smsable, :boolean, :default => false
  end
end
