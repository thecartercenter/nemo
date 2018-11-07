# frozen_string_literal: true

class CreateSavedUploads < ActiveRecord::Migration[5.1]
  def change
    create_table :saved_uploads do |t|
      t.attachment(:file)
      t.timestamps
    end
  end
end
