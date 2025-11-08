# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments, id: :uuid do |t|
      t.text :content, null: false
      t.string :comment_type, default: 'general', null: false
      t.boolean :is_resolved, default: false, null: false
      t.references :author, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :response, null: false, foreign_key: true, type: :uuid
      t.references :parent, null: true, foreign_key: { to_table: :comments }, type: :uuid

      t.timestamps
    end

    add_index :comments, :comment_type
    add_index :comments, :is_resolved
  end
end