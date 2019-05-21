# frozen_string_literal: true

class AddRejectionMessageToConstraints < ActiveRecord::Migration[5.2]
  def change
    add_column :constraints, :rejection_msg_translations, :jsonb, default: {}, null: false
  end
end
