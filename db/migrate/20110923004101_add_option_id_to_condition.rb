class AddOptionIdToCondition < ActiveRecord::Migration[4.2]
  def self.up
    add_column :conditions, :option_id, :integer
    Condition.all.each do |cond|
      if cond.ref_question.options
        cond.option_id = cond.ref_question.options.find{|o| o.value == cond.value}.id
        cond.value = nil
        cond.save
      end
    end
  end

  def self.down
    remove_column :conditions, :option_id
  end
end
