# frozen_string_literal: true

class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks, id: :uuid do |t|
      t.string :name, null: false, limit: 255
      t.string :url, null: false, limit: 500
      t.text :events, default: [], array: true
      t.string :secret, limit: 255
      t.boolean :active, default: true, null: false
      t.integer :retry_count, default: 0, null: false
      t.datetime :last_triggered_at
      t.references :mission, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    # `t.references` already adds an index in modern Rails; avoid duplicate index creation.
    add_index :webhooks, :active
    add_index :webhooks, :events, using: :gin

    create_table :webhook_deliveries, id: :uuid do |t|
      t.references :webhook, null: false, foreign_key: true, type: :uuid
      t.string :event, null: false, limit: 255
      t.jsonb :payload
      t.string :status, default: "pending", null: false, limit: 255
      t.integer :response_code
      t.text :response_body
      t.text :error_message
      t.integer :retry_count, default: 0, null: false
      t.datetime :delivered_at

      t.timestamps
    end

    add_index :webhook_deliveries, :status
    add_index :webhook_deliveries, :event
    add_index :webhook_deliveries, :created_at
  end
end
