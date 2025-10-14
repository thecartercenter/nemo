# frozen_string_literal: true

class CreateFormTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :form_templates, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :category
      t.string :tags, array: true, default: []
      t.jsonb :template_data, null: false
      t.boolean :is_public, default: false, null: false
      t.integer :usage_count, default: 0, null: false
      t.references :creator, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :mission, null: true, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :form_templates, :creator_id
    add_index :form_templates, :mission_id
    add_index :form_templates, :category
    add_index :form_templates, :is_public
    add_index :form_templates, :usage_count
    add_index :form_templates, :tags, using: 'gin'
    add_index :form_templates, :template_data, using: 'gin'
  end
end