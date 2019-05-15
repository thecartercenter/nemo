# frozen_string_literal: true

# # rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: conditions
#
#  id                 :uuid             not null, primary key
#  conditionable_type :string           not null
#  op                 :string(255)      not null
#  rank               :integer          not null
#  value              :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  conditionable_id   :uuid             not null
#  left_qing_id       :uuid             not null
#  mission_id         :uuid
#  option_node_id     :uuid
#  right_qing_id      :uuid
#
# Indexes
#
#  index_conditions_on_conditionable_id                         (conditionable_id)
#  index_conditions_on_conditionable_type_and_conditionable_id  (conditionable_type,conditionable_id)
#  index_conditions_on_left_qing_id                             (left_qing_id)
#  index_conditions_on_mission_id                               (mission_id)
#  index_conditions_on_option_node_id                           (option_node_id)
#
# Foreign Keys
#
#  conditions_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  conditions_option_node_id_fkey  (option_node_id => option_nodes.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_rails_...                    (left_qing_id => form_items.id)
#  fk_rails_...                    (right_qing_id => form_items.id)
#
# # rubocop:enable Metrics/LineLength

# Represents a condition in a question's display logic or skip logic.
class Condition < ApplicationRecord
  include MissionBased
  include FormVersionable
  include Replication::Replicable

  # Condition ranks are currently not editable, but they provide a source of deterministic ordering
  # which is useful in tests and in UI consistency.
  acts_as_list column: :rank, scope: [:conditionable_id]

  belongs_to :conditionable, polymorphic: true
  belongs_to :left_qing, class_name: "Questioning", foreign_key: "left_qing_id",
                         inverse_of: :referring_conditions
  belongs_to :right_qing, class_name: "Questioning", foreign_key: "right_qing_id", inverse_of: false
  belongs_to :option_node

  before_validation :clear_blanks
  before_validation :clean_times
  before_create :set_mission

  validate :all_fields_required

  delegate :has_options?, :rank, :full_rank, :full_dotted_rank, to: :left_qing, prefix: true
  delegate :form, :form_id, :refable_qings, to: :conditionable

  scope :referring_to_question, ->(q) { where(left_qing_id: q.qing_ids) }
  scope :by_rank, -> { order(:rank) }

  OPERATOR_CODES = %i[eq lt gt leq geq neq inc ninc].freeze

  replicable dont_copy: %i[left_qing_id conditionable_id option_node_id], backward_assocs: [
    :conditionable,
    {name: :option_node, skip_obj_if_missing: true},
    # This is a second pass association because the left_qing may not have been copied yet.
    # We have to set left_qing to something due to a null constraint.
    # For a temporary object, we can just use the FormItem this condition is attached to (base_item).
    {name: :left_qing, second_pass: true, temp_id: ->(conditionable) { conditionable.base_item.id }}
  ]

  # Deletes any that have become invalid due to changes in the given question
  def self.check_integrity_after_question_change(question)
    return unless question.option_set_id_changed? || question.destroyed?
    referring_to_question(question).destroy_all
  end

  # We accept a list of OptionNode IDs as a way to set the option_node association.
  # This is useful for forms, etc. We just pluck the last non-blank ID off the end.
  # If all are blank, we set the association to nil.
  def option_node_ids=(ids)
    self.option_node_id = ids.reverse.find(&:present?)
  end

  def options
    option_nodes.map(&:option)
  end

  def option_nodes
    option_node.nil? ? nil : option_node.ancestors[1..-1] << option_node
  end

  def option_node_path
    OptionNodePath.new(option_set: left_qing.option_set, target_node: option_node)
  end

  # returns names of all operators that are applicable to this condition based on its referred question
  def applicable_operator_names
    return [] unless left_qing
    qtype = left_qing.qtype
    OPERATOR_CODES.select do |oc|
      case oc
      when :eq, :neq then !qtype.select_multiple?
      when :lt, :gt, :leq, :geq then qtype.temporal? || qtype.numeric?
      when :inc, :ninc then qtype.select_multiple?
      end
    end
  end

  def temporal_ref_question?
    left_qing.try(:temporal?)
  end

  def numeric_ref_question?
    left_qing.try(:numeric?)
  end

  # Gets the referenced Subqing.
  # If option_node is not set, returns the first subqing of left_qing (just an alias).
  # If option_node is set, uses the depth to determine the subqing rank.
  def ref_subqing
    left_qing.subqings[option_node.blank? ? 0 : option_node.depth - 1]
  end

  def all_fields_blank?
    left_qing.blank? && op.blank? && option_node_id.blank? && value.blank?
  end

  # The type of the right side of the condition expression. Either `qing` or `value`.
  # Behaves as an ephemeral attribute.
  def right_side_type
    @right_side_type || (right_qing_id.present? ? "qing" : "value")
  end
  attr_writer :right_side_type

  private

  def clear_blanks
    return if destroyed?
    self.value = nil if value.blank? || left_qing&.has_options?
  end

  # Parses and reformats time strings given as conditions.
  def clean_times
    return unless !destroyed? && temporal_ref_question? && value.present?
    begin
      self.value = Time.zone.parse(value).to_s(:"std_#{left_qing.qtype_name}")
    rescue ArgumentError
      self.value = nil
    end
  end

  def all_fields_required
    errors.add(:base, :all_required) if any_fields_blank?
  end

  def any_fields_blank?
    left_qing.blank? || op.blank? || (left_qing.has_options? ? option_node_id.blank? : value.blank?)
  end

  def set_mission
    self.mission = conditionable.try(:mission)
  end
end
