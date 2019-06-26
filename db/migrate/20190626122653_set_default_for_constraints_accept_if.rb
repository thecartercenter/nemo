# frozen_string_literal: true

class SetDefaultForConstraintsAcceptIf < ActiveRecord::Migration[5.2]
  def up
    change_column_default :constraints, :accept_if, "all_met"
  end
end
