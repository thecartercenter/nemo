# frozen_string_literal: true

class CreateAnnotations < ActiveRecord::Migration[8.0]
  def change
    create_table :annotations, id: :uuid do |t|
      t.text :content, null: false
      t.string :annotation_type, default: "note", null: false
      t.decimal :position_x, precision: 10, scale: 2
      t.decimal :position_y, precision: 10, scale: 2
      t.decimal :width, precision: 10, scale: 2
      t.decimal :height, precision: 10, scale: 2
      t.boolean :is_public, default: true, null: false
      t.references :author, null: false, foreign_key: {to_table: :users}, type: :uuid
      t.references :response, null: false, foreign_key: true, type: :uuid
      t.references :answer, null: true, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :annotations, :annotation_type
    add_index :annotations, :is_public
  end
end
