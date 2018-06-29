class AddOdkXmlToResponses < ActiveRecord::Migration[4.2]
  def change
    add_column :responses, :odk_xml, :text
  end
end
