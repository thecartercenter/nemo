class AddOdkXmlToResponses < ActiveRecord::Migration
  def change
    add_column :responses, :odk_xml, :text
  end
end
