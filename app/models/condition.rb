class Condition < ApplicationRecord
  include MissionBased, FormVersionable, Replication::Replicable

  acts_as_paranoid

  # question types that cannot be used in conditions
  NON_REFABLE_TYPES = %w(location image annotated_image signature sketch audio video)

  belongs_to :questioning, inverse_of: :display_conditions
  belongs_to :ref_qing, class_name: "Questioning", foreign_key: "ref_qing_id",
    inverse_of: :referring_conditions
  belongs_to :option_node

  before_validation :clear_blanks
  before_validation :clean_times
  before_create :set_mission

  validate :all_fields_required
  validates :questioning, presence: true

  delegate :has_options?, :full_dotted_rank, to: :ref_qing, prefix: true
  delegate :form, :form_id, :refable_qings, to: :questioning

  scope :referring_to_question, ->(q) { where(ref_qing_id: q.qing_ids) }
  scope :by_ref_qing_rank, -> { joins(:ref_qing).order("form_items.rank") }

  OPERATORS = [
    {name: 'eq', types: %w(decimal integer counter text long_text address select_one datetime date time),
      code: "="},
    {name: 'lt', types: %w(decimal integer counter datetime date time), code: "<"},
    {name: 'gt', types: %w(decimal integer counter datetime date time), code: ">"},
    {name: 'leq', types: %w(decimal integer counter datetime date time), code: "<="},
    {name: 'geq', types: %w(decimal integer counter datetime date time), code: ">="},
    {name: 'neq', types: %w(decimal integer counter text long_text address select_one datetime date time),
      code: "!="},
    {name: 'inc', types: %w(select_multiple), code: "="},
    {name: 'ninc', types: %w(select_multiple), code: "!="}
  ]

  replicable backward_assocs: [:questioning, :ref_qing, {name: :option_node, skip_obj_if_missing: true}],
    dont_copy: [:ref_qing_id, :questioning_id, :option_node_id]

  # Deletes any that have become invalid due to changes in the given question
  def self.check_integrity_after_question_change(question)
    if question.option_set_id_changed? || question.destroyed?
      referring_to_question(question).destroy_all
    end
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
    OptionNodePath.new(option_set: ref_qing.option_set, target_node: option_node)
  end

  # returns names of all operators that are applicable to this condition based on its referred question
  def applicable_operator_names
    ref_qing ? OPERATORS.select{|o| o[:types].include?(ref_qing.qtype_name)}.map{|o| o[:name]} : []
  end

  # Gets the definition of self's operator (self.op).
  def operator
    @operator ||= OPERATORS.detect{|o| o[:name] == op}
  end

  def temporal_ref_question?
    ref_qing.try(:temporal?)
  end

  def numeric_ref_question?
    ref_qing.try(:numeric?)
  end

  # Gets the referenced Subqing.
  # If option_node is not set, returns the first subqing of ref_qing (just an alias).
  # If option_node is set, uses the depth to determine the subqing rank.
  def ref_subqing
    ref_qing.subqings[option_node.blank? ? 0 : option_node.depth - 1]
  end

  def all_fields_blank?
    ref_qing.blank? && op.blank? && option_node_id.blank? && value.blank?
  end

  private

  def clear_blanks
    unless destroyed?
      self.value = nil if value.blank? || ref_qing && ref_qing.has_options?
    end
    return true
  end

  # Parses and reformats time strings given as conditions.
  def clean_times
    if !destroyed? && temporal_ref_question? && value.present?
      begin
        self.value = Time.zone.parse(value).to_s(:"std_#{ref_qing.qtype_name}")
      rescue ArgumentError
        self.value = nil
      end
    end
    return true
  end

  def all_fields_required
    errors.add(:base, :all_required) if any_fields_blank?
  end

  def any_fields_blank?
    puts "any fields blank?"
    ref_qing.blank? || op.blank? #|| (ref_qing.has_options? ? option_node_id.blank? : value.blank?)
  end

  def set_mission
    self.mission = questioning.try(:mission)
  end
end
