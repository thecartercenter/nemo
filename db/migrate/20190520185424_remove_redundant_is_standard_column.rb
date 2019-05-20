# frozen_string_literal: true

class RemoveRedundantIsStandardColumn < ActiveRecord::Migration[5.2]
  def up
    remove_column :forms, :is_standard
    remove_column :questions, :is_standard
    remove_column :option_sets, :is_standard
    remove_column :option_nodes, :is_standard
  end
end
