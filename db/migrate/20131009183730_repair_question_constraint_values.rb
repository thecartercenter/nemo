class RepairQuestionConstraintValues < ActiveRecord::Migration[4.2]
  def up
    # Now obsolete
    #
    # # turn off callbacks
    # Question.reset_callbacks :save
    #
    # Question.all.each do |q|
    #   # use send b/c it's a private method
    #   q.send('normalize_constraint_values')
    #
    #   # don't validate b/c who knows what that might do
    #   q.save(:validate => false)
    # end
  end

  def down
  end
end
