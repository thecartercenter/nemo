class AddDeltaToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :delta, :boolean, :default => true, :null => false
  end
end
