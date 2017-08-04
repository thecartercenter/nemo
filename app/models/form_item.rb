class FormItem < ApplicationRecord
  include MissionBased, FormVersionable, Replication::Replicable

  acts_as_paranoid
  acts_as_list column: :rank, scope: [:form_id, :ancestry]

  belongs_to(:form)

  # These associations are really only applicable to Questioning, but
  # they are defined here to allow eager loading.
  belongs_to(:question, autosave: true, inverse_of: :questionings)
  has_many(:answers, foreign_key: :questioning_id, dependent: :destroy, inverse_of: :questioning)
  has_one(:condition, foreign_key: :questioning_id, autosave: true, dependent: :destroy, inverse_of: :questioning)
  has_many(:referring_conditions, class_name: 'Condition', foreign_key: :ref_qing_id, dependent: :destroy, inverse_of: :ref_qing)
  has_many(:standard_form_reports, class_name: 'Report::StandardFormReport', foreign_key: :disagg_qing_id, dependent: :nullify)

  before_create(:set_mission)

  has_ancestry cache_depth: true

  validate :parent_must_be_group

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
    children.order(:rank)
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
  def move(new_parent_id, new_rank)
    transaction do
      new_parent = FormItem.find(new_parent_id)
      form_id = new_parent.form_id
      update_attributes(parent: new_parent, rank: new_rank)

      # Extra safeguards to make sure ranks are correct. acts_as_list should prevent these.
      if rank_gaps?
        raise "Moving Qing #{id} to parent #{new_parent_id}, rank #{new_rank} would have caused gaps in ranks."
      elsif duplicate_ranks?
        raise "Moving Qing #{id} to parent #{new_parent_id}, rank #{new_rank} would have caused duplicate ranks."
      end
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

  private

  # copy mission from question
  def set_mission
    self.mission = form.try(:mission)
  end

  def parent_must_be_group
    errors.add(:parent, :must_be_group) unless parent.nil? || parent.is_a?(QingGroup)
  end

  # Checks for gaps in ranks in the db directly.
  def rank_gaps?
    SqlRunner.instance.run("
      SELECT id FROM form_items fi1
      WHERE fi1.deleted_at IS NULL AND fi1.form_id = ? AND fi1.rank > 1 AND NOT EXISTS (
        SELECT id FROM form_items fi2
        WHERE fi2.deleted_at IS NULL AND fi2.ancestry = fi1.ancestry AND fi2.rank = fi1.rank - 1)
    ", form_id).any?
  end

  def duplicate_ranks?
    SqlRunner.instance.run("
      SELECT ancestry, rank
      FROM form_items
      WHERE form_id = ? AND deleted_at IS NULL AND ancestry is NOT NULL
        AND ancestry != ''
      GROUP BY ancestry, rank
      HAVING COUNT(id) > 1
    ", form_id).any?
  end
end
