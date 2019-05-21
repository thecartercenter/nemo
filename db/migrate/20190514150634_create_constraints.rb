# frozen_string_literal: true

class CreateConstraints < ActiveRecord::Migration[5.2]
  def change
    create_table :constraints, id: :uuid do |t|
      t.string :accept_if, null: false, limit: 16
      t.integer :rank, null: false
      t.references :mission, type: :uuid, foreign_key: true, index: true
      t.references :questioning, type: :uuid, index: true

      t.timestamps
    end

    add_index :constraints, %i[questioning_id rank], unique: true
    add_foreign_key :constraints, :form_items, column: "questioning_id"
  end
end
