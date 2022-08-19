# frozen_string_literal: true

class AddResponseModifier < ActiveRecord::Migration[6.1]
  def change
    # Now that we have Enketo, it's helpful to know which software was used to edit the response.
    # Defaults to nil meaning unedited.
    add_column :responses, :modifier, :string

    reversible do |dir|
      dir.up do
        # Note: update_all intentionally does NOT update the updated_at field.
        Response.where("updated_at > (created_at + INTERVAL '10 seconds')").update_all(modifier: "web")
      end
    end
  end
end
