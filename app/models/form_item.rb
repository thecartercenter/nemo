# frozen_string_literal: true

class FormItem < ApplicationRecord
  include TreeTraverseable
  include Replication::Replicable
  include FormVersionable
  include MissionBased

  DISPLAY_IF_OPTIONS = %i[always all_met any_met].freeze

  acts_as_list column: :rank, scope: %i[form_id ancestry]

  # These are just for mounting validation errors.
  attr_accessor :display_logic, :skip_logic

  # These associations are really only applicable to Questioning, but
  # they are defined here to allow eager loading.
  belongs_to :question, autosave: true, inverse_of: :questionings

  belongs_to :form
  has_many :response_nodes, foreign_key: :questioning_id, dependent: :destroy, inverse_of: :form_item
  has_many :standard_form_reports, class_name: "Report::StandardFormReport",
                                   foreign_key: :disagg_qing_id, dependent: :nullify
  has_many :display_conditions, -> { by_rank },
    as: :conditionable, class_name: "Condition", dependent: :destroy
  has_many :referring_conditions, class_name: "Condition", foreign_key: :ref_qing_id,
                                  dependent: :destroy, inverse_of: :ref_qing
  has_many :skip_rules, -> { by_rank },
    foreign_key: :source_item_id, inverse_of: :source_item, dependent: :destroy
  has_many :incoming_skip_rules, class_name: "SkipRule", foreign_key: :dest_item_id,
                                 inverse_of: :dest_item, dependent: :destroy

  before_validation :normalize

  before_validation :set_foreign_key_on_conditions
  before_validation :ensure_parent_is_group
  before_create :set_mission

  has_ancestry cache_depth: true

  validate :collect_conditional_logic_errors

  delegate :condition_computer, to: :form
  delegate :name, to: :form, prefix: true

  replicable child_assocs: %i[question display_conditions skip_rules children],
             backward_assocs: :form, dont_copy: %i[form_id question_id]

  accepts_nested_attributes_for :display_conditions, allow_destroy: true
  accepts_nested_attributes_for :skip_rules, allow_destroy: true

  def self.rank_gaps?
    SqlRunner.instance.run("
      SELECT id FROM form_items fi1
      WHERE fi1.rank > 1 AND NOT EXISTS (
        SELECT id FROM form_items fi2
        WHERE fi2.ancestry = fi1.ancestry AND fi2.rank = fi1.rank - 1)
    ").any?
  end

  def self.duplicate_ranks?
    SqlRunner.instance.run("
      SELECT ancestry, rank
      FROM form_items
      WHERE ancestry is NOT NULL AND ancestry != ''
      GROUP BY ancestry, rank
      HAVING COUNT(id) > 1
    ").any?
  end

  def self.terminate_sub_relationships(form_item_ids)
    Form.where(root_id: form_item_ids).update_all(root_id: nil)
    SkipRule.where(source_item_id: form_item_ids).delete_all
  end

  # Duck type used for retrieving the main FormItem associated with this object, which is itself.
  def base_item
    self
  end

  def visible_children
    sorted_children.select(&:visible?)
  end

  def preordered_descendants(eager_load: nil, type: nil)
    items = eager_load ? descendants.includes(eager_load) : descendants
    sorted_items = self.class.sort_by_ancestry(items) { |a, b| a.rank <=> b.rank }

    # the items are filtered after the sort because we need to have all
    # FormItem types (Questioning and QingGroup) to be available for the sort to work properly
    type ? sorted_items.select { |i| i.type == type } : sorted_items
  end

  def sorted_children
    children.order(:rank)
  end

  # All questionings that can be referred to by a condition if it were defined on this item.
  def refable_qings(eager_load: nil)
    # Always eager load :question because it's always needed
    eager_load = eager_load ? [eager_load, :question] : :question
    all_items =
      if form
        form.preordered_items(eager_load: eager_load)
      else
        # If no form specified, return all items for all forms.
        mission.forms.map { |form| form.preordered_items(eager_load: eager_load) }.flatten
      end
    all_previous = persisted? ? all_items[0..(all_items.index(self))] : all_items
    all_previous.select(&:refable?)
  end

  def refable?
    qtype_name && QuestionType[qtype_name].refable?
  end

  # Returns all form items after this one in the form, in preorder traversal order.
  # If item is not persisted, returns empty array.
  def later_items(eager_load: nil)
    return [] unless persisted?
    # Always eager load :question because it's always needed
    eager_load = eager_load ? [eager_load, :question] : :question
    all_items = form.preordered_items(eager_load: eager_load)
    all_items[(all_items.index(self) + 1)..-1]
  end

  # Returns an array of ranks of all parents plus self, e.g. [2,5].
  # Uses the cached value setup by descendant_questionings if available.
  def full_rank
    @full_rank ||= path.map(&:rank)[1..-1]
  end

  # Returns the full rank joined with a period separator, e.g. 2.5.
  def full_dotted_rank
    @full_dotted_rank ||= full_rank.join(".")
  end

  # Moves item to new rank and parent.
  # Ensures new rank is not too low or high.
  def move(new_parent, new_rank)
    new_parent = FormItem.find(new_parent) unless new_parent.is_a?(FormItem)
    transaction do
      self.parent = new_parent
      self.rank = [1, [new_rank, new_parent.children.size + 1].min].max
      save(validate: false)
    end
  end

  def as_json(options = {})
    options[:methods] ||= []
    options[:methods] << :full_dotted_rank
    result = super(options)
  end

  def group_children?
    children.any? { |c| c.is_a?(QingGroup) }
  end

  def top_level?
    depth == 1
  end

  def visible?
    !hidden?
  end

  def self_and_ancestor_ids
    ancestor_ids << id
  end

  def display_conditionally?
    display_if != "always" && display_conditions.any?
  end

  # This method is used by the condition computer. Note it includes only display conditions.
  # To get all conditions on a form item including those from skip rules, use the condition computer.
  def condition_group
    @condition_group ||= Forms::ConditionGroup.new(
      true_if: display_if,
      members: display_conditions,
      name: "Display for #{code}"
    )
  end

  def group?
    false
  end

  def debug_tree(indent: 0)
    child_tree = sorted_children.map { |c| c.debug_tree(indent: indent + 1) }.join
    chunks = []
    chunks << " " * (indent * 2)
    chunks << rank.to_s.rjust(2)
    chunks << " "
    chunks << self.class.name.ljust(15)
    chunks << " Type: #{qtype_name}," if qtype_name.present?
    chunks << " Code: #{code}"
    chunks << " Repeatable" if repeatable?
    chunks << " Id: #{id}"
    "\n#{chunks.join}#{child_tree}"
  end

  private

  def normalize
    display_conditions.destroy(display_conditions.select(&:all_fields_blank?))
    skip_rules.destroy(skip_rules.select(&:all_fields_blank?))

    if display_conditions.reject(&:marked_for_destruction?).none?
      self.display_if = "always"
    elsif display_if == "always"
      self.display_if = "all_met"
    end
  end

  # copy mission from question
  def set_mission
    self.mission = form.try(:mission)
  end

  # Since conditionable is polymorphic, inverse is not available and we have to do this explicitly
  def set_foreign_key_on_conditions
    display_conditions.each { |c| c.conditionable = self }
  end

  def ensure_parent_is_group
    raise ParentMustBeGroupError unless parent.nil? || parent.group?
  end

  # If there is a validation error on display logic or skip logic, we know it has to be due
  # to a missing field. This is easier to catch here instead of React for now.
  def collect_conditional_logic_errors
    errors.add(:display_logic, :all_required) if display_conditions.any?(&:invalid?)

    errors.add(:skip_logic, :all_required) if skip_rules.any?(&:invalid?)
  end
end

class ParentMustBeGroupError < StandardError; end
