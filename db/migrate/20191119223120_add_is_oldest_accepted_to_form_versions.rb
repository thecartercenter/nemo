# frozen_string_literal: true

class AddIsOldestAcceptedToFormVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :form_versions, :is_oldest_accepted, :boolean, null: false, default: true

    # Revert the default before setting a single one to true (otherwise validation fails).
    FormVersion.all.each { |fv| fv.update!(is_oldest_accepted: false) }
    FormVersion.all.each { |fv| fv.update!(is_oldest_accepted: fv.is_current) }
  end
end
