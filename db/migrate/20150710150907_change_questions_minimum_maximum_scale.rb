class ChangeQuestionsMinimumMaximumScale < ActiveRecord::Migration
  def up
    change_table :questions do |t|
      t.change :minimum, :decimal, precision: 15, scale: 8
      t.change :maximum, :decimal, precision: 15, scale: 8
    end
  end

  def down
    change_table :questions do |t|
      t.change :minimum, :decimal, precision: 15, scale: 10
      t.change :maximum, :decimal, precision: 15, scale: 10
    end
  end
end
