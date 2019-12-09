# frozen_string_literal: true

class ScopeFormVersionNumberConstraintToForm < ActiveRecord::Migration[5.2]
  def up
    remove_index :form_versions, :number
    add_index :form_versions, %i[form_id number], unique: true
  end

  def down
    remove_index :form_versions, %i[form_id number]
    add_index :form_versions, :number, unique: true
  end
end
