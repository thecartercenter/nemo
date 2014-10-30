class AddPubChangedAtToForms < ActiveRecord::Migration
  def change
    add_column :forms, :pub_changed_at, :datetime
  end
end
