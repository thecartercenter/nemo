# frozen_string_literal: true

class RemoveAPIV1Columns < ActiveRecord::Migration[6.1]
  def up
    drop_table :whitelistings
  end

  def down
    # create_table "whitelistings", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    #   t.datetime "created_at", null: false
    #   t.datetime "updated_at", null: false
    #   t.uuid "user_id"
    #   t.uuid "whitelistable_id"
    #   t.string "whitelistable_type", limit: 255
    #   t.index ["user_id"], name: "index_whitelistings_on_user_id"
    #   t.index ["whitelistable_id"], name: "index_whitelistings_on_whitelistable_id"
    # end
  end
end
