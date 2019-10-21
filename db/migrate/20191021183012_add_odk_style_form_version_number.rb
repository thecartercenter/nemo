# frozen_string_literal: true

class AddOdkStyleFormVersionNumber < ActiveRecord::Migration[5.2]
  def change
    add_column :form_versions, :number, :string
    add_index :form_versions, [:number], unique: true

    reversible do |dir|
      dir.up do
        FormVersion.all.order(:created_at).each(&method(:update_version_number))
      end
    end
  end

  def update_version_number(form_version)
    date = form_version.created_at.strftime("%Y%m%d")
    revision = 0

    # Set version number using ODK date-revision convention
    loop do
      raise "Revision can't be more than 2 digits" if revision >= 100
      form_version.number = date + revision.to_s.rjust(2, "0")
      revision += 1
      break unless FormVersion.find_by(number: form_version.number)
    end

    form_version.save!
  end
end
