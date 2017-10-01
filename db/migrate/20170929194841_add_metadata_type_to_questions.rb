class AddMetadataTypeToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :metadata_type, :string
  end
end
