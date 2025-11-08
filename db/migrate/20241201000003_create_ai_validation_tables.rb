# frozen_string_literal: true

class CreateAiValidationTables < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_validation_rules, id: :uuid do |t|
      t.string :name, null: false, limit: 255
      t.text :description
      t.string :rule_type, null: false, limit: 255
      t.jsonb :config, null: false, default: {}
      t.string :ai_model, default: 'gpt-3.5-turbo', limit: 255
      t.decimal :threshold, precision: 5, scale: 2, default: 0.8
      t.boolean :active, default: true, null: false
      t.references :mission, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :ai_validation_rules, :rule_type
    add_index :ai_validation_rules, :active

    create_table :ai_validation_results, id: :uuid do |t|
      t.references :ai_validation_rule, null: false, foreign_key: true, type: :uuid
      t.references :response, null: false, foreign_key: true, type: :uuid
      t.string :validation_type, null: false, limit: 255
      t.decimal :confidence_score, precision: 5, scale: 2, null: false
      t.boolean :is_valid, null: false
      t.text :issues, default: [], array: true
      t.text :suggestions, default: [], array: true
      t.text :explanation
      t.boolean :passed, null: false

      t.timestamps
    end

    add_index :ai_validation_results, :validation_type
    add_index :ai_validation_results, :passed
    add_index :ai_validation_results, :confidence_score
  end
end