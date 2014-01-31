class AddDeltaToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :delta, :boolean, :default => true, :null => false
  end
end
