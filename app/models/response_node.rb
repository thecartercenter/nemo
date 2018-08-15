# frozen_string_literal: true

# Parent class for nodes in the response tree
class ResponseNode < ApplicationRecord
  self.table_name = "answers"

  attr_accessor :relevant

  belongs_to :form_item, inverse_of: :answers, foreign_key: "questioning_id"
  belongs_to :response
  has_closure_tree order: "new_rank", numeric_order: true, dont_order_roots: true, dependent: :destroy

  before_save do
    children.each do |c|
      if !c.relevant? || c._destroy
        c.destroy
      else
        c.response_id = response_id
      end
    end
    # update inst_nums. inst_num and this block will go away with answer_arranger
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

  after_save { children.each(&:save) }

  validates_associated :children

  alias c children

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
end
