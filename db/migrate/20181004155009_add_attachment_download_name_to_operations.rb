# frozen_string_literal: true

class AddAttachmentDownloadNameToOperations < ActiveRecord::Migration[5.1]
  def up
    add_column(:operations, :attachment_download_name, :string)
  end

  def down
    remove_column(:operations, :attachment_download_name)
  end
end
