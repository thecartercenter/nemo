# frozen_string_literal: true

# Holds common functionality for models that apply logic to forms and are composed of a set of conditions.
module FormLogical
  extend ActiveSupport::Concern

  included do
    include Replication::Replicable
    include MissionBased

    # Ranks are currently not editable, but they provide a source of deterministic ordering
    # which is useful in tests and in UI consistency.
    acts_as_list column: :rank, scope: [:source_item_id]

    belongs_to :source_item, class_name: "FormItem", inverse_of: model_name.plural, touch: true
    has_many :conditions, -> { by_rank }, as: :conditionable, inverse_of: :conditionable, dependent: :destroy

    before_validation :set_foreign_key_on_conditions
    before_create :inherit_mission

    scope :by_rank, -> { order(:rank) }

    delegate :form, :form_id, :refable_qings, to: :source_item

    accepts_nested_attributes_for :conditions, allow_destroy: true, reject_if: :all_blank
  end

  # Duck type used for retrieving the main FormItem associated with this object, which is source_item.
  def base_item
    source_item
  end

  def refd_qings
    conditions.flat_map(&:refd_qings).uniq
  end

  private

  # Since conditionable is polymorphic, inverse is not available and we have to do this explicitly
  def set_foreign_key_on_conditions
    conditions.each { |c| c.conditionable = self }
  end

  def inherit_mission
    self.mission = source_item.mission
  end
end
