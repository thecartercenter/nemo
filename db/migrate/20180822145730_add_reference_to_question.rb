class AddReferenceToQuestion < ActiveRecord::Migration[5.1]
  def change
    add_column :questions, :reference, :string
  end
end
