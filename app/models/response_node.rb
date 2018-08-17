# frozen_string_literal: true

# Parent class for nodes in the response tree
class ResponseNode < ApplicationRecord
  self.table_name = "answers"

  acts_as_paranoid

  attr_accessor :relevant

  belongs_to :form_item, inverse_of: :answers, foreign_key: "questioning_id"
  belongs_to :response
  has_closure_tree order: "new_rank", numeric_order: true, dont_order_roots: true, dependent: :destroy

  before_save do
    destroy_obsolete_children
    propogate_response_id
    update_inst_nums
  end

  after_save { children.each(&:save) }

  validates_associated :children

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
    chunks << " InstNum: #{inst_num}"
    chunks << " NewRank: #{new_rank}"
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

  #_destroy defaults to false unless set otherwise
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

  # TODO: remove. inst_num and this block will go away with answer_arranger
  def update_inst_nums
    children.reject(&:destroyed?).sort_by(&:new_rank).each_with_index do |c, i|
      new_inst_num =
        if c.parent.is_a?(AnswerGroupSet) # repeat group
          i + 1
        elsif %w[Answer AnswerSet AnswerGroupSet].include?(c.type)
          c.parent.inst_num
        else
          1
        end
      c.inst_num = new_inst_num
    end
  end

  def irrelevant_or_marked_destroy?
    !relevant? || _destroy
  end
end
