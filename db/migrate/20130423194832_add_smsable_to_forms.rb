# frozen_string_literal: true

class AddSmsableToForms < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :smsable, :boolean, default: false
  end
end
