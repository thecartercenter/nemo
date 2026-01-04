# frozen_string_literal: true

class CreateValidationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :validation_rules, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :rule_type, null: false
      t.jsonb :conditions, null: false
      t.string :message
      t.boolean :is_active, default: true, null: false
      t.references :form, null: true, foreign_key: true, type: :uuid
      t.references :question, null: true, foreign_key: true, type: :uuid
      t.references :mission, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :validation_rules, :rule_type
    add_index :validation_rules, :is_active
    add_index :validation_rules, :conditions, using: "gin"
  end
end
