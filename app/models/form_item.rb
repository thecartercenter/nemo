class FormItem < ActiveRecord::Base
  include MissionBased, FormVersionable, Replication::Replicable

  acts_as_list column: :rank, scope: [:ancestry]

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

  # Gets all leaves of the subtree headed by this FormItem, sorted.
  # These should all be Questionings.
  def sorted_leaves(eager_load = nil)
    _sorted_leaves(arrange_and_sort(eager_load).values[0])
  end

  def arrange_and_sort(eager_load = nil)
    # This is the only way (apparently) to do eager loading with arrange.
    self.class.arrange_nodes(subtree.all(include: eager_load,
      order: '(case when ancestry is null then 0 else 1 end), ancestry, rank'))
  end

  # tests for cyclic parents
  def check_ancestry_integrity(parent_id)
    parent = FormItem.find_by_id(parent_id)
    return true if parent.nil?
    parent.parent.nil? || parent.parent.id != self.id
  end

  private
    # copy mission from question
    def set_mission
      self.mission = form.try(:mission)
    end

    def _sorted_leaves(nodes)
      nodes.map do |form_item, children|
        if form_item.is_a?(Questioning)
          form_item
        else
          _sorted_leaves(children).flatten
        end
      end
    end

    def parent_must_be_group
      errors.add(:parent, :must_be_group) unless parent.nil? || parent.is_a?(QingGroup)
    end

end
