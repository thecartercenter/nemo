# frozen_string_literal: true

class SkipRule < ActiveRecord::Base
  include Replication::Replicable
  include MissionBased

  # SkipRule ranks are currently not editable, but they provide a source of deterministic ordering
  # which is useful in tests and in UI consistency.
  acts_as_list column: :rank, scope: [:source_item_id]

  belongs_to :source_item, class_name: "FormItem", inverse_of: :skip_rules
  belongs_to :dest_item, class_name: "FormItem", inverse_of: :incoming_skip_rules
  has_many :conditions, -> { by_rank }, as: :conditionable, dependent: :destroy

  before_validation :set_foreign_key_on_conditions
  before_validation :normalize
  before_create :inherit_mission

  validate :require_dest_item
  validate :collect_condition_errors

  scope :by_rank, -> { order(:rank) }

  delegate :form, :form_id, :refable_qings, to: :source_item

  accepts_nested_attributes_for :conditions, allow_destroy: true, reject_if: :all_blank

  replicable child_assocs: [:conditions], dont_copy: %i[source_item_id dest_item_id],
             backward_assocs: [
               :source_item,
               # This is a second pass association because the
               # dest_item won't have been copied yet on the 1st pass.
               {name: :dest_item, second_pass: true}
             ]

  def all_fields_blank?
    destination.blank? && dest_item.blank? && conditions.all?(&:all_fields_blank?)
  end

  def condition_group
    @condition_group ||= Forms::ConditionGroup.new(
      true_if: skip_if,
      members: conditions,
      negate: true,
      name: "Skip for #{source_item.code}"
    )
  end

  # Duck type used for retrieving the main FormItem associated with this object, which is src_item.
  def base_item
    source_item
  end

  def ref_qings
    conditions.map(&:ref_qing)
  end

  private

  # Since conditionable is polymorphic, inverse is not available and we have to do this explicitly
  def set_foreign_key_on_conditions
    conditions.each { |c| c.conditionable = self }
  end

  def normalize
    if conditions.reject(&:marked_for_destruction?).none?
      self.skip_if = "always"
    elsif skip_if == "always"
      self.skip_if = "all_met"
    end
  end

  def require_dest_item
    errors.add(:dest_item_id, :blank_unless_goto_end) if destination != "end" && dest_item.nil?
  end

  # If there is a validation error on the conditions, we know it has to be due
  # to a missing field. This is easier to catch here instead of React for now.
  def collect_condition_errors
    errors.add(:base, :all_required) if conditions.any?(&:invalid?)
  end

  def inherit_mission
    self.mission = source_item.mission
  end
end
