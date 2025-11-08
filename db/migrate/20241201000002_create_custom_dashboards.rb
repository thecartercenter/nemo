# frozen_string_literal: true

class CreateCustomDashboards < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_dashboards, id: :uuid do |t|
      t.string :name, null: false, limit: 255
      t.text :description
      t.jsonb :layout, null: false
      t.jsonb :settings, null: false
      t.boolean :is_public, default: false, null: false
      t.references :mission, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    # Reference columns already add indexes by default in Rails 8.
    add_index :custom_dashboards, :is_public

    create_table :dashboard_widgets, id: :uuid do |t|
      t.references :custom_dashboard, null: false, foreign_key: true, type: :uuid
      t.string :widget_type, null: false, limit: 255
      t.jsonb :config, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :dashboard_widgets, :position
    add_index :dashboard_widgets, :widget_type
  end
end