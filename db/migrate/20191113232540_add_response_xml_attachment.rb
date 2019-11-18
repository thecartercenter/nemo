# frozen_string_literal: true

class AddResponseXmlAttachment < ActiveRecord::Migration[5.2]
  def up
    add_attachment :responses, :odk_xml
  end

  def down
    remove_attachment :responses, :odk_xml
  end
end
