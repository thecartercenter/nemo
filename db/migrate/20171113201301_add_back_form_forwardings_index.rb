class AddBackFormForwardingsIndex < ActiveRecord::Migration[4.2]
  def up
    add_index "form_forwardings", %w(form_id recipient_id recipient_type),
      name: "form_forwardings_full", unique: true
  end
end
