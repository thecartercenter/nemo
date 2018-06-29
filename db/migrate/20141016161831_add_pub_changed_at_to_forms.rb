class AddPubChangedAtToForms < ActiveRecord::Migration[4.2]
  def change
    add_column :forms, :pub_changed_at, :datetime
  end
end
