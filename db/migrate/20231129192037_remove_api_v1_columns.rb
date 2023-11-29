# frozen_string_literal: true

class RemoveAPIV1Columns < ActiveRecord::Migration[6.1]
  def up
    drop_table :whitelistings

    remove_column :users, :api_key
  end

  def down
    create_table :whitelistings, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.uuid "user_id"
      t.uuid "whitelistable_id"
      t.string "whitelistable_type", limit: 255
      t.index ["user_id"], name: "index_whitelistings_on_user_id"
      t.index ["whitelistable_id"], name: "index_whitelistings_on_whitelistable_id"
    end

    add_column :users, :api_key, :string, limit: 255
  end
end
