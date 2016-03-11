class GenerateSequencesForOptionNodes < ActiveRecord::Migration
  def up
    OptionSet.find_each do |option_set|
      option_set.generate_sequence(batch: true)
    end
  end

  def down
    OptionNode.find_each do |option_node|
      next unless option_node.sequence
      option_node.sequence = nil
      option_node.save(validate: false)
    end
  end
end
