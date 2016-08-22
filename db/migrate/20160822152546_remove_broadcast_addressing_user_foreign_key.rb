class RemoveBroadcastAddressingUserForeignKey < ActiveRecord::Migration
  def up
    remove_foreign_key "broadcast_addressings", "addressee"
  end
end
