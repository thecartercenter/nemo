class Condition < ActiveRecord::Base
  belongs_to(:ref_qing, class_name: "Questioning", foreign_key: "ref_qing_id", inverse_of: :referring_conditions)
  serialize :option_ids, JSON

  def options
    # We need to sort since ar#find doesn't guarantee order
    option_ids.nil? ? nil : Option.find(option_ids).sort_by{ |o| option_ids.index(o.id) }
  end

  def option_nodes
    option_ids.nil? ? nil : OptionNode.where(option_id: option_ids, option_set_id: ref_qing.option_set).sort_by { |on| option_ids.index(on.option_id) }
  end
end

class OptionNode < ActiveRecord::Base
  belongs_to :option, autosave: true
end

class PopulateConditionOptionNodeReference < ActiveRecord::Migration
  def up
    check_failed = false

    # Make sure all leaf nodes match leaf options.
    Condition.all.each do |condition|
      if condition.option_ids.present?
        node = condition.option_nodes.last
        option = condition.options.last
        if node.option_id != option.id
          puts "Condition ##{condition.id}: OptionNode ##{node.id} didn't match Option ##{option.id}"
          check_failed = true
        end
      end
    end

    raise "OptionNode <=> Option check failed" if check_failed

    Condition.all.each do |condition|
      if condition.option_ids.present?
        node = condition.option_nodes.last
        condition.update_attribute(:option_node_id, node.id)
      end
    end
  end
end
