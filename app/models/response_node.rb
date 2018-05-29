# frozen_string_literal: true

# Parent class for nodes in the answer hierarchy
class ResponseNode < ApplicationRecord
  self.table_name = "answers"

  belongs_to :form_item, inverse_of: :answers, foreign_key: "questioning_id"
  has_closure_tree dependent: :destroy

  def debug_tree(indent: 0)
    child_tree = children.sort_by(&:new_rank).map { |c| c.debug_tree(indent: indent + 1) }.join
    chunks = []
    chunks << " " * (indent * 2)
    chunks << new_rank.to_s.rjust(2)
    chunks << " "
    chunks << self.class.name.ljust(15)
    chunks << "(FI: #{form_item.type} #{form_item.rank})"
    "\n#{chunks.join}#{child_tree}"
  end

  # This method should eventually not be needed since closure_tree supports deterministic ordering.
  # However, enabling it currently causes performance issues so we're holding off.
  def sorted_children
    children.sort_by(&:new_rank)
  end

  # Should eventually be changed to just point to children once closure_tree's ordering is turned on.
  alias c sorted_children
end
