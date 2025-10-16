# frozen_string_literal: true

class CreateWorkflowTables < ActiveRecord::Migration[8.0]
  def change
    create_table :workflows, id: :uuid do |t|
      t.string :name, null: false, limit: 255
      t.text :description
      t.string :workflow_type, null: false, limit: 255
      t.jsonb :config, null: false, default: {}
      t.boolean :active, default: true, null: false
      t.references :mission, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :workflows, :mission_id
    add_index :workflows, :user_id
    add_index :workflows, :workflow_type
    add_index :workflows, :active

    create_table :workflow_instances, id: :uuid do |t|
      t.references :workflow, null: false, foreign_key: true, type: :uuid
      t.string :trigger_object_type, null: false, limit: 255
      t.uuid :trigger_object_id, null: false
      t.references :trigger_user, foreign_key: { to_table: :users }, type: :uuid
      t.string :status, default: 'pending', null: false, limit: 255
      t.integer :current_step, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.text :cancellation_reason

      t.timestamps
    end

    add_index :workflow_instances, :workflow_id
    add_index :workflow_instances, [:trigger_object_type, :trigger_object_id]
    add_index :workflow_instances, :trigger_user_id
    add_index :workflow_instances, :status

    create_table :workflow_steps, id: :uuid do |t|
      t.references :workflow, null: false, foreign_key: true, type: :uuid
      t.integer :step_number, null: false
      t.string :step_type, null: false, limit: 255
      t.string :name, null: false, limit: 255
      t.text :description
      t.jsonb :config, null: false, default: {}
      t.string :status, default: 'pending', limit: 255

      t.timestamps
    end

    add_index :workflow_steps, :workflow_id
    add_index :workflow_steps, :step_number
    add_index :workflow_steps, :step_type

    create_table :approval_requests, id: :uuid do |t|
      t.references :workflow_instance, null: false, foreign_key: true, type: :uuid
      t.references :workflow_step, null: false, foreign_key: true, type: :uuid
      t.references :approver, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :status, default: 'pending', null: false, limit: 255
      t.datetime :due_date
      t.text :comments
      t.datetime :approved_at
      t.datetime :rejected_at

      t.timestamps
    end

    add_index :approval_requests, :workflow_instance_id
    add_index :approval_requests, :workflow_step_id
    add_index :approval_requests, :approver_id
    add_index :approval_requests, :status

    create_table :workflow_logs, id: :uuid do |t|
      t.references :workflow_instance, null: false, foreign_key: true, type: :uuid
      t.string :event_type, null: false, limit: 255
      t.text :message, null: false
      t.references :user, foreign_key: true, type: :uuid
      t.jsonb :data

      t.timestamps
    end

    add_index :workflow_logs, :workflow_instance_id
    add_index :workflow_logs, :event_type
    add_index :workflow_logs, :user_id
  end
end