class FormItem < ApplicationRecord
  include MissionBased, FormVersionable, Replication::Replicable, TreeTraverseable

  DISPLAY_IF_OPTIONS = %i(always all_met any_met)

  acts_as_paranoid
  acts_as_list column: :rank, scope: [:form_id, :ancestry, deleted_at: nil]

  # These associations are really only applicable to Questioning, but
  # they are defined here to allow eager loading.
  belongs_to :question, autosave: true, inverse_of: :questionings

  belongs_to :form
  has_many :answers, foreign_key: :questioning_id, dependent: :destroy, inverse_of: :questioning
  has_many :standard_form_reports, class_name: "Report::StandardFormReport",
    foreign_key: :disagg_qing_id, dependent: :nullify

  # These associations have qing in their foreign keys but we have them here in FormItem instead
  # because we will eventually support conditions on groups.
  has_many :display_conditions, -> { by_ref_qing_rank }, as: :conditionable,
    class_name: "Condition", dependent: :destroy
  has_many :referring_conditions, class_name: "Condition", foreign_key: :ref_qing_id,
    dependent: :destroy, inverse_of: :ref_qing
  has_many :skip_rules, inverse_of: :source_item

  before_validation :normalize

  # Since conditionable is polymorphic, inverse is not available and we have to do this explicitly
  before_validation :set_foreign_key_on_conditions
  before_create :set_mission

  has_ancestry cache_depth: true

  validate :parent_must_be_group

  delegate :name, to: :form, prefix: true

  replicable child_assocs: [:question, :display_conditions, :children], backward_assocs: :form,
    dont_copy: [:hidden, :form_id, :question_id]

  accepts_nested_attributes_for :display_conditions, allow_destroy: true

  def self.rank_gaps?
    SqlRunner.instance.run("
      SELECT id FROM form_items fi1
      WHERE fi1.deleted_at IS NULL AND fi1.rank > 1 AND NOT EXISTS (
        SELECT id FROM form_items fi2
        WHERE fi2.deleted_at IS NULL AND fi2.ancestry = fi1.ancestry AND fi2.rank = fi1.rank - 1)
    ").any?
  end

  def self.duplicate_ranks?
    SqlRunner.instance.run("
      SELECT ancestry, rank
      FROM form_items
      WHERE deleted_at IS NULL AND ancestry is NOT NULL
        AND ancestry != ''
      GROUP BY ancestry, rank
      HAVING COUNT(id) > 1
    ").any?
  end

  # Gets an OrderedHash of the following form for the descendants of this FormItem.
  # Uses only a constant number of database queries to do so.
  # {
  #   Qing => {},
  #   Qing => {},
  #   QingGroup => {
  #     Qing => {},
  #     Qing => {}
  #   },
  #   Qing => {},
  #   QingGroup => {},
  #   Qing => {},
  #   Qing => {},
  #   ...
  # }
  # Some facts about the hash:
  # * This item itself is not included in the hash.
  # * If an item points to an empty hash, it is a leaf node.
  def arrange_descendants
    sort = '(case when ancestry is null then 0 else 1 end), ancestry, rank'
    # We eager load questions and option sets since they are likely to be needed.
    nodes = subtree.includes(question: {option_set: :root_node}).order(sort).to_a
    with_self = self.class.arrange_nodes(nodes)
    with_self.values[0]
  end

  # Gets a nested array of all Questionings in the subtree headed by this item. For example,
  # (corresponding to the above example for arrange_descendants):
  # [Qing, Qing, [Qing, Qing], Qing, Qing, Qing, ...]
  def descendant_questionings(nodes = nil)
    nodes ||= arrange_descendants
    nodes.map do |form_item, children|
      form_item.is_a?(Questioning) ? form_item : descendant_questionings(children)
    end
  end

  def preordered_descendants
    self.class.sort_by_ancestry(descendants.order(:rank)) { |a, b| a.rank <=> b.rank }
  end

  def sorted_children
    sorted = children.order(:rank)
  end

  # Returns an array of ranks of all parents plus self, e.g. [2,5].
  # Uses the cached value setup by descendant_questionings if available.
  def full_rank
    @full_rank ||= path.map(&:rank)[1..-1]
  end

  # Returns the full rank joined with a period separator, e.g. 2.5.
  def full_dotted_rank
    @full_dotted_rank ||= full_rank.join('.')
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

  def has_group_children?
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

  def group?
    false
  end

  private

  def normalize
    display_conditions.each do |cond|
      display_conditions.destroy(cond) if cond.all_fields_blank?
    end

    if display_conditions.none?
      self.display_if = "always"
    elsif display_if == "always"
      self.display_if = "all_met"
    end
  end

  # copy mission from question
  def set_mission
    self.mission = form.try(:mission)
  end

  def set_foreign_key_on_conditions
    display_conditions.each { |c| c.conditionable = self }
  end

  def parent_must_be_group
    errors.add(:parent, :must_be_group) unless parent.nil? || parent.is_a?(QingGroup)
  end
end
