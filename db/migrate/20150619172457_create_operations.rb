class CreateOperations < ActiveRecord::Migration[4.2]
  def change
    create_table :operations do |t|
      t.integer :creator_id, null: false
      t.string :job_class, null: false
      t.string :description, null: false
      t.datetime :job_started_at
      t.datetime :job_failed_at
      t.datetime :job_completed_at
      t.string :job_id
      t.string :provider_job_id
      t.string :job_outcome_url
      t.text :job_error_report

      t.timestamps null: false

      # index for the admin case
      t.index :created_at

      # index for normal users
      t.index [:creator_id, :created_at]
    end

    add_foreign_key :operations, :users, column: :creator_id
  end
end
