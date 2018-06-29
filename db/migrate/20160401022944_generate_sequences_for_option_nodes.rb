class GenerateSequencesForOptionNodes < ActiveRecord::Migration[4.2]
  def up
    OptionSet.find_each do |option_set|
      option_set.descendants.find_each.with_index do |option_node, i|
        option_node.update_attributes(sequence: i + 1)
      end
    end
  end

  def down
    OptionNode.update_all(sequence: nil)
  end
end
