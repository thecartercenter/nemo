# frozen_string_literal: true

class RemoveFormVersionSequence < ActiveRecord::Migration[5.2]
  def change
    remove_column :form_versions, :sequence, :integer
  end
end
