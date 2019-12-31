# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: answers
#
#  id                :uuid             not null, primary key
#  accuracy          :decimal(9, 3)
#  altitude          :decimal(9, 3)
#  date_value        :date
#  datetime_value    :datetime
#  latitude          :decimal(8, 6)
#  longitude         :decimal(9, 6)
#  new_rank          :integer          default(0), not null
#  old_inst_num      :integer          default(1), not null
#  old_rank          :integer          default(1), not null
#  pending_file_name :string
#  time_value        :time
#  tsv               :tsvector
#  type              :string           default("Answer"), not null
#  value             :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  option_id         :uuid
#  parent_id         :uuid
#  questioning_id    :uuid             not null
#  response_id       :uuid             not null
#
# Indexes
#
#  index_answers_on_new_rank        (new_rank)
#  index_answers_on_option_id       (option_id)
#  index_answers_on_parent_id       (parent_id)
#  index_answers_on_questioning_id  (questioning_id)
#  index_answers_on_response_id     (response_id)
#  index_answers_on_type            (type)
#
# Foreign Keys
#
#  answers_option_id_fkey       (option_id => options.id) ON DELETE => restrict ON UPDATE => restrict
#  answers_questioning_id_fkey  (questioning_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#  answers_response_id_fkey     (response_id => responses.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

# Parent class for nodes in the response tree
class ResponseNode < ApplicationRecord
  self.table_name = "answers"

  attr_accessor :relevant

  belongs_to :form_item, inverse_of: :response_nodes, foreign_key: "questioning_id"
  belongs_to :response

  # We don't use the advisory lock for now because it slows down concurrent inserts a lot and doesn't
  # seem necessary since we don't do a lot of concurrent edits.
  has_closure_tree order: "new_rank", numeric_order: true, dont_order_roots: true,
                   with_advisory_lock: false, dependent: :destroy

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

  # Finds the first (in pre-order) descendant AnswerGroupSet with the same QingGroup as the given one.
  # Returns nil if not found.
  def matching_group_set(qing_group)
    if is_a?(AnswerGroupSet) && form_item == qing_group
      self
    else
      # Find, in a short-circuit fashion, the first non-nil recursive call result.
      children.lazy.map { |c| c.matching_group_set(qing_group) }.detect(&:itself)
    end
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
  def _destroy=(val)
    @destroy = val.is_a?(String) ? val == "true" : val
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
