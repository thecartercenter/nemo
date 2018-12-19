# frozen_string_literal: true

# Parent class for nodes in the response tree
class ResponseNode < ApplicationRecord
  self.table_name = "answers"

  acts_as_paranoid

  attr_accessor :relevant

  belongs_to :form_item, inverse_of: :response_nodes, foreign_key: "questioning_id"
  belongs_to :response

  # We don't use the advisory lock for now because it slows down concurrent inserts a lot and doesn't
  # seem necessary since we don't do a lot of concurrent edits.
  has_closure_tree order: "new_rank", numeric_order: true, dont_order_roots: true,
                   with_advisory_lock: false, soft_delete: true, dependent: :destroy

  before_save do
    destroy_obsolete_children
    propogate_response_id
  end

  after_update { children.each(&:save) }

  validates_associated :children

  delegate :code, to: :form_item
  alias c children
  alias destroy? _destroy

  def debug_tree(indent: 0)
    child_tree = children.map { |c| c.debug_tree(indent: indent + 1) }.join
    chunks = []
    chunks << " " * (indent * 2)
    chunks << new_rank.to_s.rjust(2)
    chunks << " "
    chunks << self.class.name.ljust(15)
    chunks << "(FI: #{form_item.type} #{form_item.rank})" if form_item.present?
    chunks << " Value: #{casted_value}" if casted_value.present?
    chunks << "   #{id}"
    "\n#{chunks.join}#{child_tree}"
  end

  # relevant defaults to true until set otherwise
  def relevant?
    relevant.nil? ? true : relevant
  end

  # Answer.rb implements casted_value for answers.Duck type method for non-Answer response nodes.
  def casted_value
    nil
  end

  # _destroy defaults to false unless set otherwise
  def _destroy
    @destroy.nil? ? false : @destroy
  end

  # A flag indicating whether this node should be destroyed before save.
  # convert string 'true'/'false' to boolean
  def _destroy=(d)
    @destroy = d.is_a?(String) ? d == "true" : d
  end

  def propogate_response_id
    children.reject(&:destroyed?).each do |c|
      c.response_id = response_id
    end
  end

  def destroy_obsolete_children
    children.destroy(children.select(&:irrelevant_or_marked_destroy?))
  end

  def irrelevant_or_marked_destroy?
    !relevant? || _destroy
  end
end
