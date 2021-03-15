# frozen_string_literal: true

class RemovePaperclipColumns < ActiveRecord::Migration[6.1]
  def change
    remove_paperclip_metadata
    remove_other_obsolete_columns
  end

  def remove_other_obsolete_columns
    # This is now saved in the DB instead of being set dynamically.
    remove_column :operations, :attachment_download_name, :string
    # This has been obsolete for a long time.
    remove_column :responses, :odk_xml, :text
  end

  def remove_paperclip_metadata
    remove_column :operations, :attachment_content_type, :string
    remove_column :operations, :attachment_file_name, :string
    remove_column :operations, :attachment_file_size, :integer
    remove_column :operations, :attachment_legacy_url, :string
    remove_column :operations, :attachment_updated_at, :datetime

    remove_column :saved_uploads, :file_content_type, :string
    remove_column :saved_uploads, :file_file_name, :string
    remove_column :saved_uploads, :file_file_size, :integer
    remove_column :saved_uploads, :file_legacy_url, :string
    remove_column :saved_uploads, :file_updated_at, :datetime

    remove_column :questions, :media_prompt_content_type, :string
    remove_column :questions, :media_prompt_file_name, :string
    remove_column :questions, :media_prompt_file_size, :integer
    remove_column :questions, :media_prompt_legacy_url, :string
    remove_column :questions, :media_prompt_updated_at, :datetime

    remove_column :media_objects, :item_content_type, :string
    remove_column :media_objects, :item_file_name, :string
    remove_column :media_objects, :item_file_size, :integer
    remove_column :media_objects, :item_legacy_url, :string
    remove_column :media_objects, :item_updated_at, :datetime

    remove_column :responses, :odk_xml_content_type, :string
    remove_column :responses, :odk_xml_file_name, :string
    remove_column :responses, :odk_xml_file_size, :integer
    remove_column :responses, :odk_xml_legacy_url, :string
    remove_column :responses, :odk_xml_updated_at, :datetime
  end
end
