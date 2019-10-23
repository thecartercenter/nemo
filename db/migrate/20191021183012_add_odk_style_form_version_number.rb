# frozen_string_literal: true

class AddOdkStyleFormVersionNumber < ActiveRecord::Migration[5.2]
  def change
    add_column :form_versions, :number, :string, limit: 10
    add_index :form_versions, [:number], unique: true

    reversible do |dir|
      dir.up do
        FormVersion.all.order(:created_at).each(&method(:update_version_number))
      end
    end

    change_column_null :form_versions, :number, false
  end

  def update_version_number(form_version)
    date = form_version.created_at.strftime("%Y%m%d")
    revision = 0

    # Set version number using ODK date-revision convention
    loop do
      raise RevisionTooHighError if revision >= 100
      form_version.number = date + revision.to_s.rjust(2, "0")
      revision += 1
      break unless FormVersion.find_by(number: form_version.number)
    end

    form_version.save!
  end
end
