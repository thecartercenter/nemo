class AddMetadataTypeToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :questions, :metadata_type, :string
  end
end
