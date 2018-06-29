class OptionSet < ActiveRecord::Base
  belongs_to :original, class_name: "OptionSet"
  belongs_to :root_node, -> { where(option_id: nil) }, class_name: OptionNode, dependent: :destroy
end
class OptionNode < ActiveRecord::Base
  has_ancestry cache_depth: true
  belongs_to :option
end
class Option < ActiveRecord::Base; end

class ReconstructOptionNodesOriginalId < ActiveRecord::Migration[4.2]
  def up
    transaction do
      # Process all option sets with originals
      OptionSet.where("original_id IS NOT NULL").each do |option_set|
        if original = option_set.original
          puts "Processing option set #{option_set.name}"
          option_set.root_node.update_columns(original_id: original.root_node_id)
          check_children_for_matches(option_set.root_node, original.root_node, 1)
        end
      end
    end
  end

  def check_children_for_matches(copy, original, level)
    indent = " " * (level * 2)
    copy_children = copy.children.includes(:option).to_a
    orig_children = original.children.includes(:option).index_by { |c| c.option.canonical_name }
    copy_children.each do |copy_child|
      puts "#{indent}Checking for original of #{copy_child.option.canonical_name}"
      if match = orig_children[copy_child.option.canonical_name]
        copy_child.update_columns(original_id: match.id)
        if copy_child.children.any? && match.children.any?
          puts "#{indent}  Recursing"
          check_children_for_matches(copy_child, match, level + 1)
        end
      else
        puts "#{indent}  NO MATCH FOUND (this is ok, just letting you know)"
      end
    end
  end
end
