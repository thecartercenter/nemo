class AddDirtyDupeToResponse < ActiveRecord::Migration[6.1]
  def up
    add_column :responses, :dirty_dupe, :boolean, default: true, null: false

    # Set existing responses to not dirty
    Response.all.each do |r|
      r.dirty_dupe = false
      # Dont update timestamps
      r.save(touch: false)
    end

  end

  def down
    remove_column :responses, :dirty_dupe, :boolean, default: true
  end
end
